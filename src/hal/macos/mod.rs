mod network;
use std::{
    fs::{File, OpenOptions},
    path::{Path, PathBuf},
    time::Duration,
};

use log::warn;
use nix::{
    sys::signal::{kill, Signal},
    unistd::Pid,
};
use tokio::process::Child;

pub const IN_PIPE: &str = "in_pipe";
pub const OUT_PIPE: &str = "out_pipe";

lazy_static::lazy_static! {
    pub static ref PICO8_BINS: Vec<String> = vec!["pico8".into(), "pico8_64".into(), "pico8_dyn".into()];
}

/// Suspend the pico8 process until child process exits
pub async fn pico8_to_bg(pico8_process: &Child, mut child: Child) {
    warn!("pico8_to_bg not implemented for macos")
}

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
