mod network;
use std::{
    fs::{File, OpenOptions},
    io::{BufRead, BufReader, Write},
    path::{Path, PathBuf},
    time::Duration,
};

use log::warn;
use nix::{
    sys::signal::{kill, Signal},
    unistd::Pid,
};
use tokio::process::Child;
use super::{launch_pico8_binary, PipeHAL};
use async_trait::async_trait;
use std::fs::remove_file;

pub const IN_PIPE: &str = "in_pipe";
pub const OUT_PIPE: &str = "out_pipe";

lazy_static::lazy_static! {
    pub static ref PICO8_BINS: Vec<String> = vec!["pico8".into(), "pico8_64".into(), "pico8_dyn".into()];
}

/// Suspend the pico8 process until child process exits
pub async fn pico8_to_bg(pico8_process: &Child, mut child: Child) {
    warn!("pico8_to_bg not implemented for macos")
}

/*
// create named pipes if they don't exist
fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    use nix::{sys::stat::Mode, unistd::mkfifo};
    if !pipe.exists() {
        mkfifo(pipe, Mode::S_IRUSR | Mode::S_IWUSR).expect("failed to create pipe {pipe}");
    }
    Ok(())
}

pub fn open_in_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;

    let in_pipe = OpenOptions::new().write(true).open(IN_PIPE)?;

    Ok(in_pipe)
}

pub fn open_out_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;

    let out_pipe = OpenOptions::new().read(true).open(OUT_PIPE)?;

    Ok(out_pipe)
}
*/

// just create a normal file
fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    if Path::new(pipe).exists() {
        remove_file(pipe)?;
    }
    OpenOptions::new().write(true).create(true).open(pipe)?;
    Ok(())
}

pub fn open_in_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;
    let in_pipe = OpenOptions::new().write(true).open(IN_PIPE)?;

    Ok(in_pipe)
}

pub fn open_out_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(OUT_PIPE))?;
    let out_pipe = OpenOptions::new().read(true).open(OUT_PIPE)?;

    Ok(out_pipe)
}

pub fn kill_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(
        pico8_process
            .id()
            .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::NotFound, "PID not found"))?
            as i32,
    );

    kill(pico8_pid, Signal::SIGKILL)?;
    Ok(())
}

pub fn stop_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(
        pico8_process
            .id()
            .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::NotFound, "PID not found"))?
            as i32,
    );
    kill(pico8_pid, Signal::SIGSTOP)?;
    Ok(())
}

pub fn resume_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(
        pico8_process
            .id()
            .ok_or_else(|| std::io::Error::new(std::io::ErrorKind::NotFound, "PID not found"))?
            as i32,
    );
    kill(pico8_pid, Signal::SIGCONT)?;
    Ok(())
}

pub struct MacosPipeHAL {
    reader: BufReader<File>,
}

impl MacosPipeHAL {
    pub fn init() -> anyhow::Result<Self> {
        // need to drop the in_pipe (for some reason) for the pico8 process to start up
        let in_pipe = open_in_pipe()?;
        drop(in_pipe);

        let out_pipe = open_out_pipe()?;
        let mut reader = BufReader::new(out_pipe);

        Ok(Self { reader })
    }
}

#[async_trait]
impl PipeHAL for MacosPipeHAL {
    async fn write_to_pico8(&mut self, msg: String) -> anyhow::Result<()> {
        let mut in_pipe = open_in_pipe()?;
        writeln!(in_pipe, "{msg}")?;
        drop(in_pipe);
        Ok(())
    }

    async fn read_from_pico8(&mut self) -> anyhow::Result<String> {
        let mut line = String::new();
        self.reader.read_line(&mut line)?;

        Ok(line)
    }
}
