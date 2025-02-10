use anyhow::Result;
use async_trait::async_trait;
use embedded_hal::i2c::I2c;
use linux_embedded_hal::I2cdev;
use log::{debug, warn};
use tokio::sync::RwLock;

use crate::hal::GyroHAL;

const CTRL_REG1_GYRO: u8 = 0x10; // Gyroscope control register
const OUT_X_L_GYRO: u8 = 0x18; // Gyroscope output X low register
const CTRL_REG6_ACCEL: u8 = 0x20; // Accelerometer control register
const OUT_X_L_ACCEL: u8 = 0x28; // Accelerometer X low byte

const WHO_AM_I: u8 = 0x0F; // WHO_AM_I register
const WHO_AM_I_RESP: u8 = 0x68; // the value we expect to get back from whoami request
const GYRO_SCALE: f64 = 0.01750; // sensitivity of gyroscope
const ACCEL_SCALE: f64 = 0.000122; // sensitivity of accel

const COMPL_FILTER_ALPHA: f64 = 0.98;

// driver for LSM9DS1
pub struct LinuxGyroHAL {
    i2cdev: String,
    accel_gyro_addr: u8,
    /// (pitch, roll)
    tilt: RwLock<(f64, f64)>,
}

impl LinuxGyroHAL {
    /// sdom_high: if the SDOM pin is pulled high or low
    /// sdoag_high: if the SDOAG pin is pulled high or low
    pub fn new(i2cdev: &str, sdoag_high: bool) -> anyhow::Result<Self> {
        let accel_gyro_addr = if sdoag_high { 0x6B } else { 0x6A };

        let mut dev = LinuxGyroHAL::open_i2cdev(i2cdev, accel_gyro_addr)?;

        // enable the gyro
        dev.write(accel_gyro_addr, &[CTRL_REG1_GYRO, 0x60])?;

        // enable the accel
        dev.write(accel_gyro_addr, &[CTRL_REG6_ACCEL, 0x60])?;

        Ok(Self {
            i2cdev: i2cdev.into(),
            accel_gyro_addr,
            tilt: RwLock::new((0., 0.)),
        })
    }

    /// Verify that the IMU is responsive
    fn open_i2cdev(i2cdev: &str, accel_gyro_addr: u8) -> anyhow::Result<I2cdev> {
        // create i2c device
        let mut dev = I2cdev::new(i2cdev)?;

        // run a heartbeat command to see if the device is connected
        // for gyro
        let mut buf = [0];
        dev.write_read(accel_gyro_addr, &[WHO_AM_I], &mut buf)?;
        if buf[0] != WHO_AM_I_RESP {
            return Err(anyhow::anyhow!(format!(
                "unexpected gyroscope address, expected: {}, got: {}",
                accel_gyro_addr, buf[0]
            )));
        }

        Ok(dev)
    }

    fn read_register(&self, dev: &mut I2cdev, addr: u8, len: usize) -> anyhow::Result<Vec<u8>> {
        let mut buf = vec![0; len];
        dev.write_read(self.accel_gyro_addr, &[addr | 0x80], &mut buf)?; // 0x80 for auto-increment
        Ok(buf)
    }

    fn read_gyro(&self, dev: &mut I2cdev) -> anyhow::Result<(f64, f64, f64)> {
        let data = self.read_register(dev, OUT_X_L_GYRO, 6)?;

        let x = i16::from_le_bytes([data[0], data[1]]) as f64 * GYRO_SCALE;
        let y = i16::from_le_bytes([data[2], data[3]]) as f64 * GYRO_SCALE;
        let z = i16::from_le_bytes([data[4], data[5]]) as f64 * GYRO_SCALE;

        Ok((x, y, z))
    }

    fn read_accel(&self, dev: &mut I2cdev) -> anyhow::Result<(f64, f64, f64)> {
        let data = self.read_register(dev, OUT_X_L_ACCEL, 6)?;

        let x = i16::from_le_bytes([data[0], data[1]]) as f64 * ACCEL_SCALE;
        let y = i16::from_le_bytes([data[2], data[3]]) as f64 * ACCEL_SCALE;
        let z = i16::from_le_bytes([data[4], data[5]]) as f64 * ACCEL_SCALE;

        Ok((x, y, z))
    }
}

#[async_trait]
impl GyroHAL for LinuxGyroHAL {
    /// spawn a task that periodically queries the gyro and updates internal tilt
    async fn start(&self) -> Result<()> {
        use tokio::time::{self, Duration};

        let mut dev = Self::open_i2cdev(&self.i2cdev, self.accel_gyro_addr)?;

        let mut interval = time::interval(Duration::from_millis(10));
        let mut last_time = std::time::Instant::now();
        loop {
            interval.tick().await;
            let dt = last_time.elapsed().as_secs_f64();
            last_time = std::time::Instant::now();

            // we probably don't want to use default values, since it will mess with the
            // current tilt prediction, just skip this loop iteration and print warning
            let Ok((g_x, g_y, _)) = self.read_gyro(&mut dev) else {
                warn!("failed to read from gyro");
                continue;
            };
            let Ok((a_x, a_y, a_z)) = self.read_accel(&mut dev) else {
                warn!("failed to read from accel");
                continue;
            };

            // compute pitch and roll from raw accel readings
            let accel_pitch =
                a_x.atan2((a_y * a_y + a_z * a_z).sqrt()) * (180.0 / std::f64::consts::PI);
            let accel_roll =
                a_y.atan2((a_x * a_x + a_z * a_z).sqrt()) * (180.0 / std::f64::consts::PI);

            // complimentary filter
            let tilt = self.tilt.read().await;
            let new_pitch =
                COMPL_FILTER_ALPHA * (tilt.0 + g_x * dt) + (1.0 - COMPL_FILTER_ALPHA) * accel_pitch;
            let new_roll =
                COMPL_FILTER_ALPHA * (tilt.1 + g_y * dt) + (1.0 - COMPL_FILTER_ALPHA) * accel_roll;

            debug!("{} {}", new_pitch, new_roll);
            drop(tilt);

            let mut tilt = self.tilt.write().await;
            tilt.0 = new_pitch;
            tilt.1 = new_roll;
            drop(tilt);
        }
        Ok(())
    }

    async fn read_tilt(&self) -> (f64, f64) {
        *(self.tilt.read().await)
    }
}
