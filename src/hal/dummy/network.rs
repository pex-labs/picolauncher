use serde_json::{Map, Value};

use crate::{hal::NetworkHAL, p8util::serialize_table};

// NO-OPS
pub struct DummyNetworkHAL {}

impl DummyNetworkHAL {
    pub fn new() -> Self {
        Self {}
    }
}

impl NetworkHAL for DummyNetworkHAL {
    fn scan(&self) -> anyhow::Result<()> {
        Ok(())
    }

    fn status(&self) -> anyhow::Result<String> {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("state".into(), Value::String("unknown".into()));
        Ok(serialize_table(&prop_map))
    }

    fn list(&mut self) -> anyhow::Result<Vec<crate::hal::WifiNetwork>> {
        Ok(vec![])
    }

    fn connect(&mut self, ssid: &str, psk: &str) -> anyhow::Result<()> {
        Ok(())
    }

    fn disconnect(&mut self) -> anyhow::Result<()> {
        Ok(())
    }
}
