#[cfg(target_os = "linux")]
mod linux;

#[cfg(target_os = "linux")]
pub use linux::*;

#[cfg(target_os = "macos")]
mod macos;

#[cfg(target_os = "macos")]
pub use macos::*;

#[cfg(target_os = "windows")]
mod windows;

#[cfg(target_os = "windows")]
pub use windows::*;

mod dummy;
use std::{
    fs::File,
    path::{Path, PathBuf},
    sync::Arc,
    time::Duration,
};

use anyhow::{anyhow, Result};
use async_trait::async_trait;
use dummy::*;
use event::CreateKind;
use log::{debug, info, warn};
use notify_debouncer_full::{new_debouncer, notify::*, DebounceEventResult};
use tokio::process::{Child, Command};

use crate::{
    consts::{DRIVE_DIR, INIT_CART, SCREENSHOT_PATH},
    p8util::{format_label, screenshot2cart, serialize_table},
};

pub struct WifiNetwork {
    pub ssid: String,
    pub name: String, // Display name of SSID
    pub strength: u32,
}

impl WifiNetwork {
    pub fn to_lua_table(&self) -> String {
        use serde_json::{Map, Value};

        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("ssid".into(), Value::String(self.ssid.clone()));
        prop_map.insert("name".into(), Value::String(self.name.clone()));
        prop_map.insert("strength".into(), Value::String(self.strength.to_string()));
        serialize_table(&prop_map)
    }
}

pub trait NetworkHAL {
    fn scan(&self) -> Result<()>;
    fn status(&self) -> Result<String>;
    fn list(&mut self) -> Result<Vec<WifiNetwork>>;
    fn connect(&mut self, ssid: &str, psk: &str) -> Result<()>;
    fn disconnect(&mut self) -> Result<()>;
}

// initialize the network HAL depending on the platform and any compile flags
pub fn init_network_hal() -> Result<Box<dyn NetworkHAL>> {
    #[cfg(all(feature = "network", target_os = "linux"))]
    {
        return LinuxNetworkHAL::new().map(|x| Box::new(x) as Box<dyn NetworkHAL>);
    }

    #[cfg(all(feature = "network", target_os = "macos"))]
    {
        // TODO MACOS is dummy for now
        return Ok(Box::new(DummyNetworkHAL::new()) as Box<dyn NetworkHAL>);
    }

    // fallback to the dummy
    Ok(Box::new(DummyNetworkHAL::new()) as Box<dyn NetworkHAL>)
}

pub trait BluetoothHAL {
    fn connect(&self, device_name: &str) -> Result<()>;
    fn disconnect(&self) -> Result<()>;
    fn status(&self) -> Result<String>;
    fn start_scan(&self) -> Result<()>;
    fn stop_scan(&self) -> Result<()>;
}

pub fn init_ble_hal() -> Result<Box<dyn BluetoothHAL>> {
    // TODO implementations, we are just falling back to the dummy impl for now
    Ok(Box::new(DummyBluetoothHAL::new()) as Box<dyn BluetoothHAL>)
}

#[async_trait]
pub trait GyroHAL: Send + Sync {
    /// Start monitoring the gyroscope data
    async fn start(&self) -> Result<()>;
    async fn read_tilt(&self) -> (f64, f64);
}

pub fn init_gyro_hal() -> Result<Arc<dyn GyroHAL>> {
    #[cfg(all(feature = "gyro", target_os = "linux"))]
    {
        return Ok(Arc::new(LinuxGyroHAL::new("/dev/i2c-5", true).unwrap()) as Arc<dyn GyroHAL>);
    }

    Ok(Arc::new(DummyGyroHAL::new()) as Arc<dyn GyroHAL>)
}

/// Attempts to spawn pico8 binary by trying multiple potential binary names
pub fn launch_pico8_binary(bin_names: &Vec<String>, args: Vec<&str>) -> anyhow::Result<Child> {
    for bin_name in bin_names {
        let pico8_process = Command::new(bin_name.clone()).args(args.clone()).spawn();

        match pico8_process {
            Ok(process) => return Ok(process),
            Err(e) => warn!("failed launching {bin_name}: {e}"),
        }
    }
    Err(anyhow!("failed to launch pico8"))
}

pub fn launch_pico8_main(bin_names: &Vec<String>) -> anyhow::Result<Child> {
    let init_cart_path = format!("drive/carts/{INIT_CART}");
    let args = vec![
        "-home",
        DRIVE_DIR,
        "-run",
        &init_cart_path,
        "-i",
        "in_pipe",
        "-o",
        "out_pipe",
    ];
    let mut pico8_process = launch_pico8_binary(bin_names, args);
    pico8_process
}

// Watch screenshot directory for new screenshots and then convert to a cartridge + downscale
pub fn screenshot_watcher() {
    let mut debouncer = new_debouncer(Duration::from_secs(2), None, |res: DebounceEventResult| {
        match res {
            Ok(events) => {
                for event in events.iter() {
                    debug!("{event:?}");
                    if event.event.kind == EventKind::Create(CreateKind::Any)
                        || event.event.kind == EventKind::Create(CreateKind::File)
                    {
                        // TODO should do this for each path?
                        let screenshot_fullpath = event.event.paths.first().unwrap();

                        // TODO don't use unwrap
                        let cart_name = screenshot_fullpath.file_stem().unwrap().to_string_lossy();

                        // preprocess newly created screenshot and downscale to png
                        let mut cart_128 = screenshot2cart(screenshot_fullpath).unwrap();
                        let cart_32 = format_label(&mut cart_128, 32).unwrap();

                        let mut out_128_file = File::create(PathBuf::from(format!(
                            "{SCREENSHOT_PATH}/{cart_name}.128.p8"
                        )))
                        .unwrap();
                        let mut out_32_file = File::create(PathBuf::from(format!(
                            "{SCREENSHOT_PATH}/{cart_name}.32.p8"
                        )))
                        .unwrap();

                        cart_128.write(&mut out_128_file);
                        cart_32.write(&mut out_32_file);
                    }
                }
            },
            Err(errors) => errors.iter().for_each(|error| println!("{error:?}")),
        }
    })
    .unwrap();

    debouncer
        .watcher()
        .watch(Path::new("drive/screenshots"), RecursiveMode::Recursive)
        .unwrap();

    info!("screenshot watcher registered");

    // ensure this thread remains alive
    std::thread::park();
}

/// Use the pico8 binary to export games from *.p8.png to *.p8
pub async fn pico8_export(
    bin_names: &Vec<String>,
    in_file: &Path,
    out_file: &Path,
) -> anyhow::Result<()> {
    let mut pico8_process = launch_pico8_binary(
        bin_names,
        vec![
            "-x",
            in_file.to_str().unwrap(),
            "-export",
            out_file.to_str().unwrap(),
        ],
    )?;
    pico8_process.wait().await?;
    Ok(())
}

#[async_trait]
pub trait PipeHAL {
    async fn write_to_pico8(&mut self, msg: String) -> anyhow::Result<()>;
    async fn read_from_pico8(&mut self) -> anyhow::Result<String>;
}

pub fn init_pipe_hal() -> Result<Box<dyn PipeHAL>> {
    #[cfg(target_os = "linux")]
    {
        return Ok(Box::new(MacosPipeHAL::init().unwrap()) as Box<dyn PipeHAL>);
    }

    #[cfg(target_os = "windows")]
    {
        return Ok(Box::new(WindowsPipeHAL::init().unwrap()) as Box<dyn PipeHAL>);
    }

    #[cfg(target_os = "macos")]
    {
        return Ok(Box::new(MacosPipeHAL::init().unwrap()) as Box<dyn PipeHAL>);
    }

    Ok(Box::new(DummyPipeHAL::init()) as Box<dyn PipeHAL>)
}
