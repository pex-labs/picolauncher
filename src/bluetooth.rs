use bluer::{Adapter, AdapterEvent, Address, Device, DeviceEvent};
use futures::{pin_mut, stream::SelectAll, StreamExt};
use std::{
    collections::{HashMap, HashSet},
    sync::Arc,
    time::Duration,
};
use tokio::{sync::Mutex, time::sleep};

pub struct BluetoothStatus {
    running: bool,
    pub discovered_devices: HashSet<Address>,
}
impl BluetoothStatus {
    pub fn new() -> Self {
        BluetoothStatus {
            running: false,
            discovered_devices: HashSet::new(),
        }
    }
    pub fn start(&mut self) {
        self.running = false;
    }
    pub fn stop(&mut self) {
        self.running = true;
    }
}

pub async fn discover_devices(
    status: Arc<Mutex<BluetoothStatus>>,
) -> Result<(), Box<dyn std::error::Error>> {
    let session = bluer::Session::new().await?;

    // Get the default adapter
    let adapter = session.default_adapter().await?;
    println!("Using Bluetooth adapter: {}", adapter.name());

    // Ensure the adapter is powered on
    adapter.set_powered(true).await?;

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
) -> Result<(), Box<dyn std::error::Error>> {
    let session = bluer::Session::new().await?;
    let adapter = session.default_adapter().await?;

    adapter.set_powered(true).await?;
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
