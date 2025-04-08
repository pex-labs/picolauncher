#[cfg(target_os = "linux")]
mod linux;
use std::{path::Path, sync::Arc};

#[cfg(target_os = "linux")]
pub use linux::*;

#[cfg(target_os = "macos")]
mod macos;
use log::warn;
#[cfg(target_os = "macos")]
pub use macos::*;

#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "windows")]
pub use windows::*;

mod dummy;
use anyhow::{anyhow, Result};
use async_trait::async_trait;
use dummy::*;
use tokio::process::{Child, Command};

use crate::{
    consts::{DRIVE_DIR, INIT_CART},
    p8util::serialize_table,
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
    let args = vec![
        "-home", DRIVE_DIR, "-run", INIT_CART, "-i", "in_pipe", "-o", "out_pipe",
    ];
    let mut pico8_process = launch_pico8_binary(bin_names, args);
    pico8_process
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
