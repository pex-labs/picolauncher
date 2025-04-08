mod network;
use async_trait::async_trait;
pub use network::*;

mod bluetooth;
pub use bluetooth::*;

mod gyro;
pub use gyro::*;

use super::PipeHAL;

pub struct DummyPipeHAL {}

impl DummyPipeHAL {
    pub fn init() -> Self {
        Self {}
    }
}

#[async_trait]
impl PipeHAL for DummyPipeHAL {
    async fn write_to_pico8(&mut self, msg: String) -> anyhow::Result<()> {
        Ok(())
    }

    async fn read_from_pico8(&mut self) -> anyhow::Result<String> {
        Ok(String::new())
    }
}
