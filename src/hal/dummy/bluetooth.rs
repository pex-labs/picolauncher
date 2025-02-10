use crate::hal::BluetoothHAL;

pub struct DummyBluetoothHAL {}

impl DummyBluetoothHAL {
    pub fn new() -> Self {
        Self {}
    }
}

impl BluetoothHAL for DummyBluetoothHAL {
    fn connect(&self, device_name: &str) -> anyhow::Result<()> {
        todo!()
    }

    fn disconnect(&self) -> anyhow::Result<()> {
        todo!()
    }

    fn status(&self) -> anyhow::Result<String> {
        todo!()
    }

    fn start_scan(&self) -> anyhow::Result<()> {
        todo!()
    }

    fn stop_scan(&self) -> anyhow::Result<()> {
        todo!()
    }
}
