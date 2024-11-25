use anyhow::Result;
use bluer::{Adapter, AdapterEvent, Address, Device, DeviceEvent};
use futures::{pin_mut, stream::SelectAll, StreamExt};
use serde_json::{Map, Value};
use std::{
    collections::{HashMap, HashSet},
    sync::Arc,
    time::Duration,
};
use tokio::{sync::Mutex, time::sleep};

use crate::p8util::serialize_table;

pub struct BluetoothStatus {
    running: bool,
    pub discovered_devices: HashSet<Address>,
}
impl BluetoothStatus {
    pub async fn new(adapter: &Adapter) -> Result<Self> {
        // Get the default adapter

        Ok(BluetoothStatus {
            running: false,
            discovered_devices: HashSet::new(),
        })
    }
    pub fn start(&mut self) {
        self.running = false;
    }
    pub fn stop(&mut self) {
        self.running = true;
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
pub async fn discover_devices(
    status: Arc<Mutex<BluetoothStatus>>,
    adapter: Arc<Adapter>,
) -> Result<(), Box<dyn std::error::Error>> {
    // Start discovering devices
    println!("Starting device discovery...");

    let discover = adapter.discover_devices().await?;
    pin_mut!(discover);

    while let Some(evt) = discover.next().await {
        {
            // Lock the BluetoothStatus to check if discovery should continue
            let status_guard = status.lock().await;
            if !status_guard.running {
                // If running is false, break the loop and stop discovering
                println!("Discovery stopped.");
                break;
            }
        }
        match evt {
            AdapterEvent::DeviceAdded(addr) => {
                let mut status_guard = status.lock().await;
                status_guard.discovered_devices.insert(addr);
            },
            AdapterEvent::DeviceRemoved(addr) => {
                let mut status_guard = status.lock().await;
                status_guard.discovered_devices.remove(&addr);
            },
            _ => (),
        }
    }

    Ok(())
}

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
