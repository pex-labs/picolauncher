use async_trait::async_trait;

use crate::hal::GyroHAL;

pub struct DummyGyroHAL {}

impl DummyGyroHAL {
    pub fn new() -> Self {
        Self {}
    }
}

#[async_trait]
impl GyroHAL for DummyGyroHAL {
    async fn start(&self) -> anyhow::Result<()> {
        Ok(())
    }

    async fn read_tilt(&self) -> (f64, f64) {
        (0.0, 0.0)
    }
}
