#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "linux")]
pub use linux::*;
#[cfg(target_os = "linux")]
#[cfg(target_os = "windows")]
mod windows;
use anyhow::Result;
#[cfg(target_os = "windows")]
pub use windows::*;

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

pub trait BluetoothHAL {}
