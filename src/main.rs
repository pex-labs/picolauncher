mod consts;
mod p8util;

use std::thread; // TODO maybe switch to async
use std::{
    collections::HashMap,
    fs::{read_dir, read_to_string, File, OpenOptions},
    io::{BufRead, BufReader, Read, Write},
    path::{Path, PathBuf},
    process::Command,
    time::Duration,
};

use anyhow::anyhow;
use consts::*;
use notify::event::CreateKind;
use notify_debouncer_full::{new_debouncer, notify::*, DebounceEventResult};
use p8util::*;
use serde_json::Map;

/// create named pipes if they don't exist
#[cfg(target_os = "linux")]
fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    use nix::{
        sys::{
            signal::{kill, Signal},
            stat::Mode,
        },
        unistd::{mkfifo, Pid},
    };
    if !pipe.exists() {
        mkfifo(pipe, Mode::S_IRUSR | Mode::S_IWUSR).expect("failed to create pipe {pipe}");
    }
    Ok(())
}

#[cfg(target_os = "windows")]
fn to_wstring(str: &str) -> Vec<u16> {
    use std::{ffi::OsStr, os::windows::ffi::OsStrExt};

    OsStr::new(str)
        .encode_wide()
        .chain(Some(0).into_iter())
        .collect()
}

#[cfg(target_os = "windows")]
fn create_pipe(pipe: &Path) -> anyhow::Result<()> {
    use std::{io::Error, ptr};

    use winapi::um::{
        fileapi::CreateFileW,
        handleapi::INVALID_HANDLE_VALUE,
        namedpipeapi::CreateNamedPipeW,
        winbase::{PIPE_ACCESS_DUPLEX, PIPE_TYPE_BYTE, PIPE_WAIT},
        winnt::{FILE_SHARE_READ, GENERIC_READ},
    };

    if !pipe.exists() {
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

fn parse_metadata(path: &Path) -> anyhow::Result<String> {
    let content = read_to_string(path)?;
    let table: Map<String, serde_json::Value> = serde_json::from_str(&content)?;
    let serialized = serialize_table(&table);
    println!("serialized {serialized}");
    Ok(serialized)
}

// Watch screenshot directory for new screenshots and then convert to a cartridge + downscale
fn screenshot_watcher() {
    let mut debouncer = new_debouncer(Duration::from_secs(2), None, |res: DebounceEventResult| {
        match res {
            Ok(events) => {
                for event in events.iter() {
                    if event.event.kind == EventKind::Create(CreateKind::File) {
                        println!("{event:?}");

                        // TODO should do this for each path?
                        let screenshot_fullpath = event.event.paths.get(0).unwrap();

                        // TODO don't use unwrap
                        let cart_name = screenshot_fullpath.file_stem().unwrap().to_string_lossy();

                        // preprocess newly created screenshot and downscale to png
                        let mut cart_128 = screenshot2cart(screenshot_fullpath).unwrap();
                        let cart_32 = format_label(&mut cart_128, 32).unwrap();

                        let mut out_128_file = File::create(PathBuf::from(format!(
                            "{SCREENSHOT_PATH}/{cart_name}.128.p8"
                        )))
                        .unwrap();
                        let mut out_32_file = File::create(PathBuf::from(format!(
                            "{SCREENSHOT_PATH}/{cart_name}.32.p8"
                        )))
                        .unwrap();

                        cart_128.write(&mut out_128_file);
                        cart_32.write(&mut out_32_file);
                    }
                }
            },
            Err(errors) => errors.iter().for_each(|error| println!("{error:?}")),
        }
    })
    .unwrap();

    debouncer
        .watcher()
        .watch(Path::new("drive/screenshots"), RecursiveMode::Recursive)
        .unwrap();
    println!("screenshot watcher registered");

    loop {}
}

fn main() {

    #[cfg(target_os = "linux")]
    let pico8_bin = std::env::var("PICO8_BINARY").unwrap_or("pico8".to_string());

    #[cfg(target_os = "windows")]
    let pico8_bin = std::env::var("PICO8_BINARY").unwrap_or("C:\\Program Files (x86)\\PICO-8\\pico8.exe".to_string());

    // set up environment
    // TODO create all necessary directories
    create_pipe(&IN_PIPE).unwrap();
    create_pipe(&OUT_PIPE).unwrap();

    // spawn helper threads
    let screenshot_handle = thread::spawn(|| {
        screenshot_watcher();
    });

    // spawn pico8 process and setup pipes
    // TODO capture stdout of pico8 and log it
    let pico8_process = Command::new(pico8_bin) // TODO this assumes pico8 is in path
        .args(vec![
            "-home",
            DRIVE_DIR,
            "-run",
            "drive/carts/splashscreen.p8",
            "-i",
            "in_pipe",
            "-o",
            "out_pipe",
        ])
        .spawn()
        .expect("failed to spawn pico8 process");
    //let pico8_pid = Pid::from_raw(pico8_process.id() as i32);

    // send hello message to pico8 process
    let mut in_pipe = OpenOptions::new()
        .write(true)
        .open(&*IN_PIPE)
        .expect("failed to open pipe {IN_PIPE}");
    writeln!(in_pipe, "E").expect("failed to write to pipe {IN_PIPE}");
    drop(in_pipe);

    let mut out_pipe = OpenOptions::new()
        .read(true)
        .open(&*OUT_PIPE)
        .expect("failed to open pipe {OUT_PIPE}");
    let mut reader = BufReader::new(out_pipe);

    // listen for commands from pico8 process
    loop {
        let mut line = String::new();
        reader
            .read_line(&mut line)
            .expect("failed to read line from pipe");
        line = line.trim().to_string();

        // TODO this busy loops?
        if line.len() == 0 {
            continue;
        }
        //println!("received [{}] {}", line.len(), line);

        // spawn process command
        let mut split = line.splitn(2, ':');
        let cmd = split.next().unwrap_or("");
        let data = split.next().unwrap_or("");
        println!("received cmd:{cmd} data:{data}");

        match cmd {
            // TODO disable until we port this to windows and support launching external binaries
            /*
            "spawn" => {
                // TODO double check that the command to run is in the exec directory (to avoid
                // arbitrary code execution)

                // spawn an executable of given name
                // TODO ensure no ../ escape
                let exe_path = EXE_DIR.join(data).join(data); // TODO assume exe name is same as the directory name
                println!("spawning executable {exe_path:?}");
                let mut child = Command::new(exe_path)
                    .args(vec!["-home", DRIVE_DIR]) // TODO when spawning should we override the config.txt?
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process");

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process");
            },
            "spawnp" => {
                // execute a pico8 cart as an external process
                let cart_path = CART_DIR.join(data);

                println!("spawning executable {cart_path:?}");
                let mut child = Command::new("pico8") // TODO absolute path to pico8?
                    .args(vec![
                        "-home",
                        DRIVE_DIR,
                        "-run",
                        cart_path.to_str().unwrap(),
                    ])
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process");

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process");
            },
            */
            "ls" => {
                // fetch all carts in directory
                let dir = (&*CART_DIR).join(data); // TODO watch out for path traversal
                let mut carts = vec![];
                for entry in read_dir(dir).unwrap() {
                    let entry = entry.unwrap().path();
                    if entry.is_file() {
                        // for each file read metadata and pack into table string
                        let filename = entry.file_name().unwrap();
                        let mut metapath = PathBuf::from(filename);
                        metapath.set_extension("json");
                        let metapath = METADATA_DIR.join(metapath);
                        match parse_metadata(&metapath) {
                            Ok(serialized) => carts.push(serialized),
                            Err(e) => eprintln!("failed parsing metadata file: {e:?}"),
                        }
                    }
                }
                // TODO check efficiency for lots of files

                // TODO make this pipe writing stuff better (duplicate code)
                let mut in_pipe = OpenOptions::new()
                    .write(true)
                    .open(&*IN_PIPE)
                    .expect("failed to open pipe {IN_PIPE}");
                let joined_carts = carts.join(",");
                writeln!(in_pipe, "{}", joined_carts).expect("failed to write to pipe {IN_PIPE}");
                drop(in_pipe);
            },
            "label" => {
                // fetch a label for a given cart, scaled to a given size
            },
            /*
            "splore" => {
                let mut child = Command::new("pico8") // TODO absolute path to pico8?
                    .args(vec!["-home", DRIVE_DIR, "-splore"])
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process");

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process");
            },
            */
            "hello" => {
                println!("ack hello");
            },
            "debug" => {
                println!("debug:{}", data);
            },
            _ => {
                println!("unhandled command");
            },
        }

        // acknowledge the write
    }
}
