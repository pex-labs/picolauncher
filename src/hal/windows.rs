use std::{
    fs::{File, OpenOptions},
    os::windows::{io::RawHandle, prelude::*},
    path::{Path, PathBuf},
    ptr,
};

use anyhow::anyhow;
use winapi::um::{
    fileapi::{CreateFileW, OPEN_EXISTING},
    handleapi::INVALID_HANDLE_VALUE,
    namedpipeapi::CreateNamedPipeW,
    winbase::{PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE, PIPE_WAIT},
    winnt::{FILE_SHARE_READ, GENERIC_READ, GENERIC_WRITE, HANDLE},
};

pub const IN_PIPE: &'static str = "\\\\.\\pipe\\in_pipe";
pub const OUT_PIPE: &'static str = "\\\\.\\pipe\\out_pipe";

fn to_wstring(str: &str) -> Vec<u16> {
    use std::{ffi::OsStr, os::windows::ffi::OsStrExt};

    OsStr::new(str)
        .encode_wide()
        .chain(Some(0).into_iter())
        .collect()
}

fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    use std::{io::Error, ptr};

    if !pipe.exists() {
        println!("pipe does not exist, creating {}", pipe.to_str().unwrap());
        let pipe_name_w = to_wstring(pipe.to_str().unwrap());

        unsafe {
            let handle = CreateNamedPipeW(
                pipe_name_w.as_ptr(),
                PIPE_ACCESS_DUPLEX,
                PIPE_TYPE_BYTE | PIPE_WAIT,
                1,               // Max instances
                512,             // Output buffer size
                512,             // Input buffer size
                0,               // Default timeout
                ptr::null_mut(), // Default security attributes
            );

            if handle == INVALID_HANDLE_VALUE {
                return Err(anyhow!(Error::last_os_error()));
            }
        }
    }
    Ok(())
}

pub fn open_out_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(OUT_PIPE))?;

    let pipe_name_w = to_wstring(&*OUT_PIPE);

    unsafe {
        let handle = CreateFileW(
            pipe_name_w.as_ptr(),
            GENERIC_READ,
            0,
            ptr::null_mut(),
            OPEN_EXISTING,
            0,
            ptr::null_mut(),
        );

        if handle == INVALID_HANDLE_VALUE {
            return Err(anyhow!(std::io::Error::last_os_error()));
        }

        println!("successfully opened {handle:?}");
        Ok(File::from_raw_handle(handle as RawHandle))
    }
}

pub fn open_in_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;

    let pipe_name_w = to_wstring(&*IN_PIPE);

    unsafe {
        let handle = CreateFileW(
            pipe_name_w.as_ptr(),
            GENERIC_WRITE,
            0,
            ptr::null_mut(),
            OPEN_EXISTING,
            0,
            ptr::null_mut(),
        );

        if handle == INVALID_HANDLE_VALUE {
            return Err(anyhow!(std::io::Error::last_os_error()));
        }

        println!("successfully opened {handle:?}");
        Ok(File::from_raw_handle(handle as RawHandle))
    }
}

// search start menu for pico8.exe
pub fn locate_pico8_binary() {
    // TODO traverse start menu directory, find pico8.exe
    // TODO resolve .lnk file to get actual location of pico8 binary
}

pub fn stop_pico8_process(pico8_process: Child) -> anyhow::Result<()> {
    todo!()
}

/*
pub fn open_out_pipe() -> anyhow::Result<File> {
    let mut file = OpenOptions::new()
        .write(true)
        .truncate(true)
        .open("out_pipe")?;

    Ok(file)
}

pub fn open_in_pipe() -> anyhow::Result<File> {
    let mut file = OpenOptions::new()
        .read(true)
        .truncate(true)
        .open("in_pipe")?;

    Ok(file)
}
*/
