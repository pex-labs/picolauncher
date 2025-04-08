use std::{
    fs::{File, OpenOptions},
    os::windows::{io::RawHandle, prelude::*},
    path::{Path, PathBuf},
    ptr,
};

use anyhow::anyhow;
use log::warn;
use tokio::process::{Child, Command};
use winapi::um::{
    fileapi::{CreateFileW, OPEN_EXISTING},
    handleapi::INVALID_HANDLE_VALUE,
    namedpipeapi::CreateNamedPipeW,
    winbase::{PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE, PIPE_WAIT},
    winnt::{FILE_SHARE_READ, GENERIC_READ, GENERIC_WRITE, HANDLE},
};

pub const IN_PIPE: &'static str = "in_pipe";
pub const OUT_PIPE: &'static str = "out_pipe";

lazy_static::lazy_static! {
    pub static ref PICO8_BINS: Vec<String> = vec![
        "pico8.exe".into(),
        "C:\\Program Files (x86)\\PICO-8\\pico8.exe".into(),
    ];
}

fn to_wstring(str: &str) -> Vec<u16> {
    use std::{ffi::OsStr, os::windows::ffi::OsStrExt};

    OsStr::new(str)
        .encode_wide()
        .chain(Some(0).into_iter())
        .collect()
}

// just create a normal file
fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    if !Path::new(pipe).exists() {
        OpenOptions::new()
            .write(true)
            .create(true)
            .open(pipe)?;
    }
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

// search start menu for pico8.exe
pub fn locate_pico8_binary() {
    // TODO traverse start menu directory, find pico8.exe
    // TODO resolve .lnk file to get actual location of pico8 binary
}

pub fn stop_pico8_process(pico8_process: Child) -> anyhow::Result<()> {
    warn!("stop_pico8_process is not implemented for windows");
    Ok(())
}

pub fn screenshot_watcher() {
    warn!("screenshot_watcher does not work in windows");
}

pub async fn pico8_to_bg(pico8_process: &Child, mut child: Child) {
    warn!("pico8_to_bg not implemented for windows")
}

pub fn kill_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    warn!("kill_pico8_process not implemented for windows");
    Ok(())
}
