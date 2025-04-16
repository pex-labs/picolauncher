use anyhow::{anyhow, Result};
use log::warn;
use network_manager::{
    AccessPoint, AccessPointCredentials, Device, DeviceType, NetworkManager, ServiceState,
};
use serde_json::{Map, Value};

use crate::{
    hal::{NetworkHAL, WifiNetwork},
    p8util::serialize_table,
};

pub struct LinuxNetworkHAL {
    nm: NetworkManager,
    access_points: Vec<AccessPoint>,
}

impl LinuxNetworkHAL {
    pub fn new() -> Result<Self> {
        // set up dbus connection and network manager
        // start network manager if not started
        let did_nm_start = NetworkManager::start_service(1000);
        match did_nm_start {
            Ok(_) => {
                println!("Network manager service started successfully!");
                let nm_state = NetworkManager::get_service_state().map_err(|e| anyhow!("{e}"))?;
                if nm_state != ServiceState::Active {
                    // TODO maybe implement retry loop to attempt starting nm multiple times
                    return Err(anyhow!("failed to start network manager"));
                }
            },
            Err(err) => {
                println!("Failed to start network manager service: {}", err);
            },
        }

        Ok(Self {
            nm: NetworkManager::new(),
            access_points: vec![],
        })
    }

    fn find_device(&self) -> anyhow::Result<Device> {
        // TODO error handling pretty lmao
        let devices = self.nm.get_devices().map_err(|e| anyhow!(format!("{e}")))?;

        let index = devices
            .iter()
            .position(|d| *d.device_type() == DeviceType::WiFi);

        if let Some(index) = index {
            Ok(devices[index].clone())
        } else {
            Err(anyhow!("Cannot find a WiFi device"))
        }
    }
}

impl NetworkHAL for LinuxNetworkHAL {
    fn scan(&self) -> Result<()> {
        todo!()
    }

    fn status(&self) -> Result<String> {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("state".into(), Value::String("unknown".into()));

        let conns = self.nm.get_active_connections().unwrap_or_default();
        for conn in conns {
            let settings = conn.settings();
            // TODO double check this is the right string for all wireless
            if settings.kind == "802-11-wireless" {
                let ssid = settings.ssid.as_str().unwrap().to_string();
                let state = conn.get_state().unwrap();
                println!("wifi_status ssid={:?} state={state:?}", conn.settings());
                prop_map.insert("ssid".into(), Value::String(ssid));
                // TODO just doing the tostring impl here lol
                let state_str = match state {
                    network_manager::ConnectionState::Unknown => "unknown",
                    network_manager::ConnectionState::Activating => "connecting",
                    network_manager::ConnectionState::Activated => "connected",
                    network_manager::ConnectionState::Deactivating => "disconnecting",
                    network_manager::ConnectionState::Deactivated => "disconnected",
                };
                prop_map.insert("state".into(), Value::String(state_str.into()));

                // grab the ip address
                let local_ip = local_ip_address::local_ip()
                    .map(|x| x.to_string())
                    .unwrap_or("[unknown]".into());
                prop_map.insert("ip_address".into(), Value::String(local_ip));

                return Ok(serialize_table(&prop_map));
            }
        }

        warn!("wifi interface not found");
        Ok(serialize_table(&prop_map))
    }

    // TODO ideally list shouldn't be mut
    fn list(&mut self) -> Result<Vec<WifiNetwork>> {
        // TODO give each indexed access point a unique id (just index is fine?) so the
        // user is able to perform operations on the specific network
        let mut networks = vec![]; // TODO this should be some global state?

        // need to run find device inside here since WiFiDevice is not exported :(
        let wifi_device = self.find_device()?;
        let wifi_device = wifi_device.as_wifi_device().unwrap();

        // store the queried access points in state
        let mut _access_points = wifi_device.get_access_points().unwrap();
        self.access_points.clear();
        self.access_points.append(&mut _access_points);

        let wifi_networks = self
            .access_points
            .iter()
            .filter_map(|x| {
                let Ok(ssid) = x.ssid().as_str() else {
                    return None;
                };

                Some(WifiNetwork {
                    ssid: ssid.to_string(),
                    name: ssid.to_ascii_lowercase(),
                    strength: x.strength,
                })
            })
            .collect::<Vec<_>>();
        networks.extend(wifi_networks);

        Ok(networks)
    }

    fn connect(&mut self, ssid: &str, psk: &str) -> Result<()> {
        let wifi_device = self.find_device()?;
        let wifi_device = wifi_device.as_wifi_device().unwrap();

        // TODO seems like we need to disconnect from existing network before connecting to a new one?

        // find the ssid
        let Some(ap) = self
            .access_points
            .iter()
            .find(|x| x.ssid().as_str().unwrap() == ssid)
        else {
            return Err(anyhow!("Cannot find access point with ssid {ssid}"));
        };

        let credentials = AccessPointCredentials::Wpa {
            passphrase: psk.to_string(),
        };
        if let Err(e) = wifi_device.connect(ap, &credentials) {
            return Err(anyhow!("Failed to connect to access point {e}"));
        }

        Ok(())
    }

    fn disconnect(&mut self) -> Result<()> {
        let wifi_device = self.find_device()?;
        if let Err(e) = wifi_device.disconnect() {
            return Err(anyhow!("Failed to disconnect from access point {e}"));
        }

        Ok(())
    }
}
