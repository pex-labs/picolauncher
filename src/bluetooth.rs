#[cfg(target_os = "linux")]
use std::{
    collections::{HashMap, HashSet},
    sync::Arc,
    time::Duration,
};

#[cfg(target_os = "linux")]
use anyhow::Result;

#[cfg(target_os = "linux")]
use bluer::{Adapter, AdapterEvent, Address};

#[cfg(target_os = "linux")]
use futures::{pin_mut, StreamExt};

#[cfg(target_os = "linux")]
use serde_json::{Map, Value};

#[cfg(target_os = "linux")]
use tokio::{sync::Mutex, time::sleep};

#[cfg(target_os = "linux")]
use crate::p8util::serialize_table;

#[cfg(target_os = "linux")]
pub struct BluetoothStatus {
    running: bool,
    pub discovered_devices: HashSet<Address>,
}

#[cfg(target_os = "linux")]
impl BluetoothStatus {
    pub async fn new(adapter: &Adapter) -> Result<Self> {
        Ok(BluetoothStatus {
            running: false,
            discovered_devices: HashSet::new(),
        })
    }

    pub fn start(&mut self) {
        self.running = true;
    }

    pub fn stop(&mut self) {
        self.running = false;
        self.discovered_devices.clear();
    }

    pub async fn get_status_table(&self, adapter: &Adapter) -> Result<String> {
        let mut table = Map::<String, Value>::new();
        for &addr in self.discovered_devices.iter() {
            let device = adapter.device(addr)?;
            let value = if device.is_connected().await? {
                "connected"
            } else if device.is_paired().await? {
                "disconnected"
            } else {
                "unpaired"
            };
            table.insert(
                device.name().await?.unwrap_or("No Name".to_string()),
                Value::String(value.into()),
            );
        }
        Ok(serialize_table(&table))
    }
}

#[cfg(target_os = "linux")]
pub async fn discover_devices(
    status: Arc<Mutex<BluetoothStatus>>,
    adapter: Arc<Adapter>,
) -> Result<(), Box<dyn std::error::Error>> {
    println!("Starting device discovery...");

    let discover = adapter.discover_devices().await?;
    pin_mut!(discover);

    while let Some(evt) = discover.next().await {
        {
            let status_guard = status.lock().await;
            if !status_guard.running {
                println!("Discovery stopped.");
                break;
            }
        }
        match evt {
            AdapterEvent::DeviceAdded(addr) => {
                let mut status_guard = status.lock().await;
                status_guard.discovered_devices.insert(addr);
            }
            AdapterEvent::DeviceRemoved(addr) => {
                let mut status_guard = status.lock().await;
                status_guard.discovered_devices.remove(&addr);
            }
            _ => (),
        }
    }

    Ok(())
}

#[cfg(target_os = "linux")]
pub async fn update_connected_devices(
    status: Arc<Mutex<BluetoothStatus>>,
    adapter: Arc<Adapter>,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut status_guard = status.lock().await;

    adapter
        .device_addresses()
        .await?
        .into_iter()
        .for_each(|elem| {
            status_guard.discovered_devices.insert(elem);
        });
    Ok(())
}
