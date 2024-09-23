mod consts;
mod exe;
mod hal;
mod p8util;
mod scrape;

use std::thread; // TODO maybe switch to async
use std::{
    collections::HashMap,
    fs::{read_dir, read_to_string, File, OpenOptions},
    io::{BufRead, BufReader, Read, Write},
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    ptr,
    time::Duration,
};

use anyhow::anyhow;
use consts::*;
use hal::*;
use log::{debug, error, info, warn};
use notify::event::CreateKind;
use notify_debouncer_full::{new_debouncer, notify::*, DebounceEventResult};
use p8util::*;
use scrape::*;
use serde_json::Map;

use crate::exe::ExeMeta;

fn parse_metadata(path: &Path) -> anyhow::Result<String> {
    let content = read_to_string(path)?;
    let table: Map<String, serde_json::Value> = serde_json::from_str(&content)?;
    let serialized = serialize_table(&table);
    debug!("serialized {serialized}");
    Ok(serialized)
}

// Watch screenshot directory for new screenshots and then convert to a cartridge + downscale
fn screenshot_watcher() {
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

fn main() {
    // set up logger
    let crate_name = env!("CARGO_PKG_NAME");
    // env_logger::builder().format_timestamp(None).filter(Some(crate_name), log::LevelFilter::Debug).init();

    // set up screenshot watcher process
    let screenshot_handle = thread::spawn(|| {
        screenshot_watcher();
    });

    // launch pico8 binary
    let pico8_bin_override = std::env::var("PICO8_BINARY");

    #[cfg(target_os = "linux")]
    let mut pico8_bins: Vec<String> = vec!["pico8".into(), "pico8_64".into(), "pico8_dyn".into()];

    #[cfg(target_os = "windows")]
    let mut pico8_bins = vec![
        "pico8.exe".into(),
        "C:\\Program Files (x86)\\PICO-8\\pico8.exe".into(),
    ];

    if let Ok(bin_override) = pico8_bin_override {
        pico8_bins.insert(0, bin_override);
    }

    // spawn pico8 process and setup pipes
    // TODO capture stdout of pico8 and log it
    let pico8_process = launch_pico8_binary(
        &pico8_bins,
        vec![
            "-home",
            DRIVE_DIR,
            "-run",
            "drive/carts/pexsplore_home.p8",
            "-i",
            "in_pipe",
            "-o",
            "out_pipe",
        ],
    )
    .expect("failed to spawn pico8 process");

    // need to drop the in_pipe (for some reason) for the pico8 process to start up
    let mut in_pipe = open_in_pipe().expect("failed to open pipe");
    drop(in_pipe);

    let mut out_pipe = open_out_pipe().expect("failed to open pipe");
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
        debug!("received cmd:{cmd} data:{data}");

        // TODO: tokio runtime here, maybe convert entire main to tokio::main in future
        let runtime = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap();

        match cmd {
            // TODO disable until we port this to windows and support launching external binaries
            "spawn" => {
                // TODO double check that the command to run is in the exec directory (to avoid
                // arbitrary code execution)

                // spawn an executable of given name
                // TODO ensure no ../ escape
                let exe_path = EXE_DIR.join(data); // TODO assume exe name is same as the directory name
                println!("spawning executable {exe_path:?}");
                let mut child = Command::new(exe_path)
                    .args(vec!["-home", DRIVE_DIR]) // TODO when spawning should we override the config.txt?
                    .spawn()
                    .unwrap();

                pico8_to_bg(&pico8_process, child);
            },
            "spawn_pico8" => {
                let mut child = launch_pico8_binary(&pico8_bins, vec!["-home", DRIVE_DIR]).unwrap();

                pico8_to_bg(&pico8_process, child);
            },
            "spawn_splore" => {
                let mut child =
                    launch_pico8_binary(&pico8_bins, vec!["-home", DRIVE_DIR, "-splore"]).unwrap();

                pico8_to_bg(&pico8_process, child);
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

                pico8_to_bg(&pico8_process, child);
            },
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
                            Err(e) => warn!("failed parsing metadata file: {e:?}"),
                        }
                    }
                }
                // TODO check efficiency for lots of files

                // TODO make this pipe writing stuff better (duplicate code)
                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                let joined_carts = carts.join(",");
                debug!("joined carts {joined_carts}");
                writeln!(in_pipe, "{}", joined_carts).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "ls_exe" => {
                // fetch all exe that are registered
                //
                // executables metadata files are given by p8 files in drive/exe
                // metadata is under the __meta:picolauncher__ section with the following properties
                // ```
                // name=picocad
                // author=johanpeitz
                // path=picocad/picocad
                // ```
                let mut exes = vec![];
                for entry in read_dir(EXE_DIR.as_path()).unwrap() {
                    let entry = entry.unwrap().path();
                    if !entry.is_file() {
                        continue;
                    }
                    // TODO can this fail?
                    if entry.extension().unwrap() != "p8" {
                        continue;
                    }
                    let Ok(mut cart) = Cart::from_file(&entry) else {
                        warn!("failed to read exe meta file {entry:?}");
                        continue;
                    };
                    let meta = cart
                        .get_section(SectionName::Meta("picolauncher".into()))
                        .join("\n");

                    let Ok(meta_parsed) = toml::from_str::<ExeMeta>(&meta) else {
                        warn!("failed to parse metadata section of file {entry:?}");
                        continue;
                    };

                    println!("{meta_parsed:?}");
                    let Ok(meta_string) = meta_parsed.to_lua_table() else {
                        warn!("failed to serialize to lua table for meta file {entry:?}");
                        continue;
                    };

                    exes.push(meta_string);
                }
                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                let exes_joined = exes.join(",");
                debug!("exes_joined {exes_joined}");
                writeln!(in_pipe, "{}", exes_joined).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "bbs" => {
                // Query the bbs
                // args: page, query (optional)
                let mut split = data.splitn(2, ",");
                let page = split.next().unwrap().parse::<u32>().unwrap(); // TODO better error handlng here
                let query = split.next();
                println!("bbs command {page}, {query:?}");

                let client = reqwest::Client::new();
                let url = build_bbs_url(
                    Sub::Releases,
                    page,
                    query.map(|x| x.to_string()),
                    None,
                    Some(OrderBy::Featured),
                );
                println!("querying {url}");
                let res = runtime.block_on(scrape::crawl_bbs(&client, &url)).unwrap();

                for cart in res {
                    println!("{}", cart.title);
                }
            },
            "download" => {
                // Download a cart from the bbs
            },
            "label" => {
                // fetch a label for a given cart, scaled to a given size
            },
            "hello" => {
                info!("hello message acknowledged - connection established to pico8 process");
            },
            "debug" => {
                info!("debug:{}", data);
            },
            "sys" => {
                // Get system information like operating system, etc
            },
            _ => {
                warn!("unhandled command");
            },
        }

        // acknowledge the write
    }
}
