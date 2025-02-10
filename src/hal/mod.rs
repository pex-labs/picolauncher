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
use anyhow::Result;
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
    if cfg!(all(feature = "network", target_os = "linux")) {
        LinuxNetworkHAL::new().map(|x| Box::new(x) as Box<dyn NetworkHAL>)
    } else if cfg!(all(feature = "network", target_os = "macos")) {
        // TODO MACOS is dummy for now
        Ok(Box::new(DummyNetworkHAL::new()) as Box<dyn NetworkHAL>)
    } else {
        // fallback to the dummy
        Ok(Box::new(DummyNetworkHAL::new()) as Box<dyn NetworkHAL>)
    }
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

pub trait GyroHAL {}
