use std::{
    collections::{HashMap, HashSet},
    sync::Arc,
    time::Duration,
};

use anyhow::Result;
use bluer::{Adapter, AdapterEvent, Address, Device, DeviceEvent};
use futures::{pin_mut, stream::SelectAll, StreamExt};
use log::info;
use serde_json::{Map, Value};
use tokio::{sync::Mutex, time::sleep};

use crate::{hal::BluetoothHAL, p8util::serialize_table};

pub struct LinuxBluetoothHAL {
    running: bool,
    discovered_devices: HashSet<Address>,
    adapter: Arc<Adapter>,
}

impl LinuxBluetoothHAL {
    pub async fn new() -> Result<Self> {
        let session = bluer::Session::new().await.unwrap();
        let adapter = Arc::new(session.default_adapter().await.unwrap());
        info!("Using Bluetooth adapter: {}", adapter.name());
        // Ensure the adapter is powered on
        adapter.set_powered(true).await.unwrap();

        Ok(Self {
            running: false,
            discovered_devices: HashSet::new(),
            adapter,
        })
    }

    /*
    pub async fn discover_devices(&self) -> Result<()> {
        // Start discovering devices
        info!("Starting device discovery...");

        let discover = self.adapter.discover_devices().await?;
        pin_mut!(discover);

        while let Some(evt) = discover.next().await {
            {
                // Lock the BluetoothStatus to check if discovery should continue
                let status_guard = status.lock().await;
                if !status_guard.running {
                    // If running is false, break the loop and stop discovering
                    info!("Discovery stopped.");
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
        todo!()
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
    */
}

impl BluetoothHAL for LinuxBluetoothHAL {
    fn connect(&self, device_name: &str) -> Result<()> {
        todo!()
    }

    fn disconnect(&self) -> Result<()> {
        todo!()
    }

    fn status(&self) -> Result<String> {
        /*
        let mut table = Map::<String, Value>::new();
        for &addr in self.discovered_devices.iter() {
            let device = self.adapter.device(addr)?;
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
        */
        todo!()
    }

    fn start_scan(&self) -> Result<()> {
        /*
        self.running = false;
        tokio::spawn({
            let bt_status = bt_status.clone();
            let adapter = adapter.clone();
            async move {
                discover_devices(bt_status.clone(), adapter).await.unwrap();
            }
        });
        Ok(())
        */
        todo!()
    }

    fn stop_scan(&self) -> Result<()> {
        /*
        self.running = true;
        self.discovered_devices.clear();
        Ok(())
        */
        todo!()
    }
}
