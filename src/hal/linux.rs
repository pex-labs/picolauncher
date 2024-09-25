use std::{
    fs::{File, OpenOptions},
    path::{Path, PathBuf},
    process::{Child, Command},
    time::Duration,
};

use anyhow::anyhow;
use event::CreateKind;
use log::{debug, error, info, warn};
use nix::{
    sys::signal::{kill, Signal},
    unistd::Pid,
};
use notify_debouncer_full::{new_debouncer, notify::*, DebounceEventResult};

use crate::{
    consts::*,
    p8util::{format_label, screenshot2cart},
};

pub const IN_PIPE: &'static str = "in_pipe";
pub const OUT_PIPE: &'static str = "out_pipe";

/// create named pipes if they don't exist
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

pub fn open_in_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;

    let in_pipe = OpenOptions::new().write(true).open(&*IN_PIPE)?;

    Ok(in_pipe)
}

pub fn open_out_pipe() -> anyhow::Result<File> {
    create_pipe(&PathBuf::from(IN_PIPE))?;

    let out_pipe = OpenOptions::new().read(true).open(&*OUT_PIPE)?;

    Ok(out_pipe)
}

pub fn kill_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(pico8_process.id() as i32);
    kill(pico8_pid, Signal::SIGKILL)?;
    Ok(())
}

pub fn stop_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(pico8_process.id() as i32);
    kill(pico8_pid, Signal::SIGSTOP)?;
    Ok(())
}

pub fn resume_pico8_process(pico8_process: &Child) -> anyhow::Result<()> {
    let pico8_pid = Pid::from_raw(pico8_process.id() as i32);
    kill(pico8_pid, Signal::SIGCONT)?;
    Ok(())
}

// Watch screenshot directory for new screenshots and then convert to a cartridge + downscale
pub fn screenshot_watcher() {
    let mut debouncer = new_debouncer(Duration::from_secs(2), None, |res: DebounceEventResult| {
        match res {
            Ok(events) => {
                for event in events.iter() {
                    if event.event.kind == EventKind::Create(CreateKind::File) {
                        debug!("{event:?}");

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

    info!("screenshot watcher registered");

    loop {} // TODO this might consume a lot of cpu?
}

/// Suspend the pico8 process until child process exits
pub fn pico8_to_bg(pico8_process: &Child, mut child: Child) {
    // suspend current pico8 process and swap with newly spawned process
    stop_pico8_process(pico8_process);

    // unsuspend when child finishes
    child.wait().unwrap();
    resume_pico8_process(pico8_process);
}

/// Attempts to spawn pico8 binary by trying multiple potential binary names depending on the
/// platform
pub fn launch_pico8_binary(bin_names: &Vec<String>, args: Vec<&str>) -> anyhow::Result<Child> {
    for bin_name in bin_names {
        let pico8_process = Command::new(bin_name.clone())
            .args(args.clone())
            // .stdout(Stdio::piped())
            .spawn();

        match pico8_process {
            Ok(process) => return Ok(process),
            Err(e) => warn!("failed launching {bin_name}: {e}"),
        }
    }
    Err(anyhow!("failed to launch pico8"))
}

/// Use the pico8 binary to export games from *.p8.png to *.p8
pub fn pico8_export(
    bin_names: &Vec<String>,
    in_file: &Path,
    out_file: &Path,
) -> anyhow::Result<()> {
    let mut pico8_process = launch_pico8_binary(
        bin_names,
        vec![
            "-x",
            in_file.to_str().unwrap(),
            "-export",
            out_file.to_str().unwrap(),
        ],
    )?;
    pico8_process.wait()?;
    Ok(())
}
