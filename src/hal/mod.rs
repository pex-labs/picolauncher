#[cfg(target_os = "linux")]
mod linux;
use std::sync::Arc;

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
use anyhow::Result;
use async_trait::async_trait;
use dummy::*;

use crate::p8util::serialize_table;

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
