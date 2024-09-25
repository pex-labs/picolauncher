// TODO maybe switch to async
use std::{
    collections::HashMap,
    ffi::OsStr,
    fs::{read_dir, read_to_string, File, OpenOptions},
    io::{BufRead, BufReader, Read, Write},
    ops::ControlFlow,
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    ptr, thread,
    time::{Duration, Instant},
};

use anyhow::anyhow;
use futures::future::join_all;
use headless_chrome::{Browser, LaunchOptions};
use log::{debug, error, info, warn};
use notify::event::CreateKind;
use notify_debouncer_full::{new_debouncer, notify::*, DebounceEventResult};
use picolauncher::{bbs::*, consts::*, exe::ExeMeta, hal::*, p8util::*};
use serde_json::Map;

fn parse_metadata(path: &Path) -> anyhow::Result<String> {
    let content = read_to_string(path)?;
    let table: Map<String, serde_json::Value> = serde_json::from_str(&content)?;
    let serialized = serialize_table(&table);
    debug!("serialized {serialized}");
    Ok(serialized)
}

fn main() -> ! {
    // set up logger
    let crate_name = env!("CARGO_PKG_NAME");
    env_logger::builder()
        .format_timestamp(None)
        .filter(Some(crate_name), log::LevelFilter::Debug)
        .init();

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

    // TODO: tokio runtime here, maybe convert entire main to tokio::main in future
    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap();

    // TODO don't crash if browser fails to launch - just disable bbs functionality?
    // spawn browser and create tab for crawling
    let chrome_args = vec![
        "--disable-gpu",
        "--disable-images",
        "--disable-css",
        "--no-sandbox",
        "--disable-software-rasterizer",
        "--disable-dev-shm-usage",
    ];
    let options = LaunchOptions::default_builder()
        .args(chrome_args.iter().map(|s| OsStr::new(s)).collect())
        .build()
        .expect("Could not find chrome-executable");

    let start = Instant::now();
    let browser = Browser::new(options).unwrap();
    debug!("browser new took: {:?}", start.elapsed());

    let start = Instant::now();
    let tab = browser.new_tab().unwrap();
    debug!("new tab took: {:?}", start.elapsed());
    tab.disable_debugger();
    tab.disable_fetch();
    tab.disable_log();
    tab.disable_profiler();
    tab.disable_runtime();
    // only accept text to save on bandwidth
    let mut tab_headers = HashMap::new();
    tab_headers.insert("Accept", "text/html");
    tab.set_extra_http_headers(tab_headers);

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
                let query = split.next().unwrap_or_default();
                let query = query
                    .parse::<PexsploreCategory>()
                    .unwrap_or(PexsploreCategory::Featured);
                info!("bbs command {page}, {query}");

                let url = bbs_url_for_category(query, page);
                info!("querying {url}");
                let res = runtime.block_on(crawl_bbs(&tab, &url)).unwrap();

                let cartdatas = res
                    .iter()
                    .map(|cart| {
                        // TODO this is weird code
                        let mut cart = cart.clone();
                        // make all cart names uppercase (either this or invert the case)
                        cart.title = cart.title.to_ascii_lowercase();
                        cart.author = cart.author.to_ascii_lowercase();
                        cart.to_lua_table()
                    })
                    .collect::<Vec<_>>()
                    .join(",");

                // TODO use trace to log async

                // download these carts if not in games/ directory
                let pico8_bins = pico8_bins.clone();
                let res_cloned = res.clone();
                runtime.block_on(async move {
                    let mut tasks = vec![];

                    for cart in res_cloned {
                        // println!("{}", cart.to_lua_table());

                        let Some(filename) = filename_from_url(&cart.download_url) else {
                            warn!("could not extract filename from url: {}", cart.download_url);
                            continue;
                        };

                        // download if we don't have a copy of it in our games dir
                        let path = BBS_CART_DIR.join(filename);
                        if !path.exists() {
                            info!("download cart from bbs: {}", cart.download_url);
                            let path = path.clone();
                            let cart = cart.clone();
                            let task = tokio::spawn(async move {
                                // TODO kinda lmao how we need to make a new client here
                                let client = reqwest::Client::new();
                                if let Err(e) =
                                    download_cart(client, cart.download_url.clone(), &path).await
                                {
                                    warn!("failed to download cart {path:?}: {e:?}");
                                }
                            });
                            tasks.push(task);
                        }
                    }
                    let _ = join_all(tasks).await;
                });

                for cart in res {
                    // TODO some of this code is duplicated

                    let Some(filename) = filename_from_url(&cart.download_url) else {
                        warn!("could not extract filename from url: {}", cart.download_url);
                        continue;
                    };

                    // download if we don't have a copy of it in our games dir
                    let path = BBS_CART_DIR.join(filename);

                    if let Err(e) = postprocess_cart(&pico8_bins, &cart, &path) {
                        warn!("failed to postprocess cart {e:?}");
                        continue;
                    }
                }

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", cartdatas).expect("failed to write to pipe");
                drop(in_pipe);
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

#[derive(strum_macros::Display, strum_macros::EnumString)]
#[strum(serialize_all = "lowercase")]
enum PexsploreCategory {
    Featured,
    Platformer,
    New,
    Arcade,
    Action,
    Puzzle,
}

fn bbs_url_for_category(category: PexsploreCategory, page: u32) -> String {
    match category {
        PexsploreCategory::Featured => {
            build_bbs_url(Sub::Releases, page, None, None, Some(OrderBy::Featured))
        },
        PexsploreCategory::New => {
            build_bbs_url(Sub::Releases, page, None, None, Some(OrderBy::New))
        },
        PexsploreCategory::Platformer
        | PexsploreCategory::Arcade
        | PexsploreCategory::Action
        | PexsploreCategory::Puzzle => build_bbs_url(
            Sub::Releases,
            page,
            Some(category.to_string()),
            None,
            Some(OrderBy::Featured),
        ),
    }
}

// TODO this function is pretty similar to the functionality in cli.rs - should aggerate this
fn postprocess_cart(pico8_bins: &Vec<String>, cart: &CartData, path: &Path) -> anyhow::Result<()> {
    // TODO: since path.file_prefix is still unstable, we need to split on the first period
    let filename = path.file_name().unwrap().to_str().unwrap();
    let mut split = filename.splitn(2, ".");
    let filestem = split.next().unwrap();

    // generate p8 file from p8.png file
    let mut dest_path = GAMES_DIR.join(filestem);
    dest_path.set_extension("p8");
    if !dest_path.exists() {
        pico8_export(pico8_bins, path, &dest_path)
            .map_err(|e| anyhow!("failed to convert cart to p8 from file {path:?}: {e:?}"))?;
    }

    // generate label file
    let mut label_path = LABEL_DIR.join(filestem);
    label_path.set_extension("64.p8");
    if !label_path.exists() {
        let label_cart = cart2label(&dest_path)
            .map_err(|_| anyhow!("failed to generate label cart from {dest_path:?}"))?;

        let mut label_file = File::create(label_path.clone())
            .map_err(|e| anyhow!("failed to create label file {label_path:?}: {e:?}"))?;

        label_cart
            .write(&mut label_file)
            .map_err(|e| anyhow!("failed to write label file {label_path:?}: {e:?}"))?;
    }

    // generate metadata file
    let mut metadata_path = METADATA_DIR.clone().join(filestem);
    metadata_path.set_extension("json");
    if !metadata_path.exists() {
        // TODO we don't need metadata file anymore (i think?)
        let metadata = Metadata {
            name: cart.title.clone(),
            filename: filestem.to_owned(),
            author: cart.author.clone(),
            tags: cart.tags.join(","),
        };

        let metadata_serialized = serde_json::to_string_pretty(&metadata).unwrap();

        let mut metadata_file = File::create(metadata_path.clone()).unwrap();
        metadata_file
            .write_all(metadata_serialized.as_bytes())
            .unwrap();
    }

    Ok(())
}
