// TODO maybe switch to async
use std::{
    collections::HashMap,
    ffi::OsStr,
    fs::{create_dir_all, read_dir, File},
    io::{BufRead, BufReader, Write},
    path::Path,
    sync::Arc,
    thread,
    time::{Duration, Instant},
};

use anyhow::anyhow;
use futures::future::join_all;
use headless_chrome::{Browser, LaunchOptions, Tab};
use log::{debug, error, info, warn};
use picolauncher::{
    bbs::*,
    consts::*,
    db,
    exe::ExeMeta,
    hal::*,
    p8util::{self, *},
};
use serde_json::{Map, Value};
use tokio::process::Command;

use crate::db::{schema::CartId, Cart, DB};

fn create_dirs() -> anyhow::Result<()> {
    create_dir_all(EXE_DIR.as_path())?;
    create_dir_all(CART_DIR.as_path())?;
    create_dir_all(GAMES_DIR.as_path())?;
    create_dir_all(MUSIC_DIR.as_path())?;
    create_dir_all(LABEL_DIR.as_path())?;
    create_dir_all(BBS_CART_DIR.as_path())?;
    create_dir_all(RAW_SCREENSHOT_PATH)?;
    create_dir_all(SCREENSHOT_PATH)?;
    Ok(())
}

#[tokio::main]
async fn main() {
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

    // initialize network HAL
    // TODO choose correct impl based on platform
    let mut network_hal = init_network_hal().expect("failed to initialize network HAL");

    // initialize bluetooth HAL
    let ble_hal = init_ble_hal().expect("failed to initialize bluetooth HAL");

    // initialize gyroscpe HAL
    // enable IMU
    // TODO print error message if this failed
    let gyro_hal = init_gyro_hal().expect("failed to initialize bluetooth HAL");
    let gyro_hal_clone = Arc::clone(&gyro_hal);
    tokio::spawn(async move {
        gyro_hal_clone.start().await.unwrap();
    });

    // create necessary directories
    if let Err(e) = create_dirs() {
        warn!("failed to create directories: {e:?}")
    }

    // launch pico8 binary
    let pico8_bin_override = std::env::var("PICO8_BINARY");
    let mut pico8_bins = PICO8_BINS.clone();
    if let Ok(bin_override) = pico8_bin_override {
        pico8_bins.insert(0, bin_override);
    }

    // spawn pico8 process and setup pipes
    // TODO capture stdout of pico8 and log it
    let mut pico8_process = launch_pico8_main(&pico8_bins).expect("failed to spawn pico8 process");

    // need to drop the in_pipe (for some reason) for the pico8 process to start up
    let in_pipe = open_in_pipe().expect("failed to open pipe");
    drop(in_pipe);

    let out_pipe = open_out_pipe().expect("failed to open pipe");
    let mut reader = BufReader::new(out_pipe);

    // TODO don't crash if browser fails to launch - just disable bbs functionality?
    // spawn browser and create tab for crawling
    let chrome_args = [
        "--disable-gpu",
        "--disable-images",
        "--disable-css",
        "--no-sandbox",
        "--disable-software-rasterizer",
        "--disable-dev-shm-usage",
    ];
    let options = LaunchOptions::default_builder()
        .args(chrome_args.iter().map(OsStr::new).collect())
        .sandbox(false)
        .devtools(false)
        .enable_gpu(false)
        .enable_logging(false)
        .idle_browser_timeout(Duration::from_secs(u64::MAX))
        .build()
        .expect("Could not find chrome-executable");

    let start = Instant::now();
    let browser = Browser::new(options).expect("\x1b[31mFailed to launch chrome, do you have it installed?\nInstall on raspberry pi: sudo apt-get install chromium-browser\x1b[0m\n");
    debug!("browser new took: {:?}", start.elapsed());

    let start = Instant::now();
    let tab = browser.new_tab().unwrap();
    debug!("new tab took: {:?}", start.elapsed());
    tab.disable_debugger().unwrap();
    tab.disable_fetch().unwrap();
    tab.disable_log().unwrap();
    tab.disable_profiler().unwrap();
    //tab.disable_runtime().unwrap();
    // only accept text to save on bandwidth
    let mut tab_headers = HashMap::new();
    tab_headers.insert("Accept", "text/html");
    tab.set_extra_http_headers(tab_headers).unwrap();

    // TODO theres a lot of state in main.rs, should abstract into own state struct or something
    // cart stack
    let mut cartstack = Vec::<String>::new();
    cartstack.push(INIT_CART.into());

    // connect to database
    let mut db = DB::connect(db::DB_PATH).expect("unable to establish connection with database");
    debug!("established connection to sqlite database");
    db.migrate().expect("failed migrating database");

    // cache for bbs queries
    // TODO move this into struct of some sort
    let mut bbs_cache = BBSCache::new();

    // listen for commands from pico8 process
    loop {
        // check if pico8 process has exited
        if let Some(status) = pico8_process.try_wait().unwrap() {
            info!("pico8 process exited with status {status}");
            break;
        }

        let mut line = String::new();
        reader
            .read_line(&mut line)
            .expect("failed to read line from pipe");
        line = line.trim().to_string();

        // TODO this busy loops?
        if line.is_empty() {
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
                let child = Command::new(exe_path)
                    .args(vec!["-home", DRIVE_DIR]) // TODO when spawning should we override the config.txt?
                    .spawn()
                    .unwrap();

                pico8_to_bg(&pico8_process, child).await;
            },
            "spawn_pico8" => {
                let child = launch_pico8_binary(&pico8_bins, vec!["-home", DRIVE_DIR]).unwrap();

                pico8_to_bg(&pico8_process, child).await;
            },
            "spawn_splore" => {
                let child =
                    launch_pico8_binary(&pico8_bins, vec!["-home", DRIVE_DIR, "-splore"]).unwrap();

                pico8_to_bg(&pico8_process, child).await;
            },
            "spawnp" => {
                // execute a pico8 cart as an external process
                let cart_path = CART_DIR.join(data);

                println!("spawning executable {cart_path:?}");
                let child = Command::new("pico8") // TODO absolute path to pico8?
                    .args(vec![
                        "-home",
                        DRIVE_DIR,
                        "-run",
                        cart_path.to_str().unwrap(),
                    ])
                    .spawn()
                    .unwrap();

                pico8_to_bg(&pico8_process, child).await;
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
                if let Ok(read_dir) = read_dir(EXE_DIR.as_path()) {
                    for entry in read_dir {
                        let entry = entry.unwrap().path();
                        if !entry.is_file() {
                            continue;
                        }
                        // TODO can this fail?
                        if entry.extension().unwrap() != "p8" {
                            continue;
                        }
                        let Ok(mut cart) = CartFile::from_file(&entry) else {
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
                }
                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                let exes_joined = exes.join(",");
                debug!("exes_joined {exes_joined}");
                write_to_pico8(exes_joined).await;
            },
            "bbs" => {
                // Query the bbs
                // args: page, query (optional)
                let mut split = data.splitn(2, ",");
                let page = split.next().unwrap().parse::<u32>().unwrap(); // TODO better error handlng here
                let query = split.next().unwrap_or_default();
                info!("bbs command {page}, {query}");

                // TODO don't need to fetch new carts every time
                let remote_cartdatas = if query == "local" {
                    // special case, return local files
                    // TODO a bit stupid that we need to query DB to get the cart ids, and then query again
                    impl_bbs_local(&mut db).expect("failed to query local db for games")
                } else if query == "favorites" {
                    // special case, return favorite carts
                    db.get_favorites(20).unwrap()
                } else if let Some(search_query) = query.strip_prefix("search:") {
                    let url = bbs_url_for_search(search_query, page);
                    impl_bbs(&mut bbs_cache, &mut db, &tab, &pico8_bins, &url, page).await
                } else {
                    let query = query
                        .parse::<PexsploreCategory>()
                        .unwrap_or(PexsploreCategory::Featured);
                    let url = bbs_url_for_category(query, page);
                    impl_bbs(&mut bbs_cache, &mut db, &tab, &pico8_bins, &url, page).await
                };

                // fetch desired cartdatas from db
                let cart_ids = remote_cartdatas
                    .iter()
                    .map(|cart| cart.id)
                    .collect::<Vec<_>>();
                let cartdatas = db.get_carts_by_ids(cart_ids).unwrap();

                let cartdatas_encoded = cartdatas
                    .iter()
                    .map(|cart| {
                        // TODO this is weird code
                        let mut cart = cart.clone();
                        // make all cart names uppercase (either this or invert the case)
                        // TODO maybe can just do this when saving to db?
                        cart.title = cart.title.to_ascii_lowercase();
                        cart.author = cart.author.to_ascii_lowercase();
                        cart.to_lua_table()
                    })
                    .collect::<Vec<_>>()
                    .join(",");

                println!("cartdatas_encoded {cartdatas_encoded}");

                // format: number of carts N, followed by N comma separate cartdatas
                let data = if cartdatas.len() == 0 {
                    "0".to_string()
                } else {
                    format!("{},{}", cartdatas.len(), cartdatas_encoded)
                };
                write_to_pico8(data).await;
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
            "info" => {
                let info = impl_info();
                println!("{info:?}");
                write_to_pico8(info.to_lua_table()).await;
            },
            "debug" => {
                info!("debug:{}", data);
            },
            "sys" => {
                // Get system information like operating system, etc
            },
            "pushcart" => {
                // when loading a new cart, can push the current cart and use as breadcrumb
                cartstack.push(data.into());
            },
            "popcart" => {
                // remove latest cart from stack
                let _ = cartstack.pop();
                let topcart = cartstack.last().cloned().unwrap_or_default();
                debug!("popcart topcart is {topcart}");
                write_to_pico8(topcart).await;
            },
            "wifi_list" => {
                // scan for networks
                // TODO should log error at least
                let networks = network_hal.list().unwrap_or_default();
                let networks = networks
                    .into_iter()
                    .map(|x| x.to_lua_table())
                    .collect::<Vec<_>>();

                println!("found networks {}", networks.join(","));
                write_to_pico8(networks.join(",")).await;
            },
            "wifi_connect" => {
                // Grab password and connect to wifi, returning success or failure info
                // TODO any security concerns with

                // TODO use hw_address as unique id?
                let mut split = data.splitn(2, ",");
                let ssid = split.next().unwrap_or_default();
                let psk = split.next().unwrap_or_default();

                let res = network_hal.connect(ssid, psk);
                println!("wifi connection result {res:?}");

                let status = network_hal.status().unwrap();
                write_to_pico8(status).await;
            },
            "wifi_disconnect" => {
                let res = network_hal.disconnect();
                println!("wifi disconnection result {res:?}");

                let status = network_hal.status().unwrap();
                write_to_pico8(status).await;
            },
            "wifi_status" => {
                // Get if wifi is connected or not, the current network, and the strength of connection
                let status = network_hal.status().unwrap();
                write_to_pico8(status).await;
            },
            "bt_start" => {
                /*
                let _ = update_connected_devices(bt_status.clone(), adapter.clone()).await;
                tokio::spawn({
                    let bt_status = bt_status.clone();
                    let adapter = adapter.clone();
                    async move {
                        discover_devices(bt_status.clone(), adapter).await.unwrap();
                    }
                });
                */
                todo!()
            },
            "bt_stop" => {
                /*
                let mut bt_status_guard = bt_status.lock().await;
                bt_status_guard.stop();
                */
                todo!()
            },

            "bt_status" => {
                /*
                let mut bt_status_guard = bt_status.lock().await;

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(
                    in_pipe,
                    "{}",
                    bt_status_guard.get_status_table(&adapter).await.unwrap()
                )
                .expect("failed to write to pipe");
                drop(in_pipe);
                */
                todo!()
            },
            "bt_connect" => {
                todo!()
            },
            "bt_disconnect" => {
                todo!()
            },
            "set_favorite" => {
                let mut split = data.splitn(2, ",");
                let cart_id = split.next().unwrap().parse::<i32>().unwrap();
                let is_favorite = split.next().unwrap().parse::<bool>().unwrap();

                // TODO better error handling
                db.set_favorite(cart_id, is_favorite).unwrap();
                write_to_pico8(format!("{cart_id},{is_favorite}")).await;
            },
            "download_music" => {
                let cart_id = data.parse::<i32>().unwrap();
                let res = impl_download_music(&mut db, cart_id).await;
                if let Err(ref e) = res {
                    warn!("download_music failed {e:?}");
                }
                write_to_pico8(format!("{}", res.is_ok())).await;
            },
            "gyro_read" => {
                let gyro_hal = Arc::clone(&gyro_hal.clone());
                let (pitch, roll) = gyro_hal.read_tilt().await;
                debug!("got imu data {},{}", pitch, roll);
                write_to_pico8(format!("{pitch},{roll}")).await;
            },
            "shutdown" => {
                // shutdown() call in pico8 only escapes to the pico8 shell, so implement special command that kills pico8 process
                kill_pico8_process(&pico8_process).unwrap();
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

fn bbs_url_for_search(search_query: &str, page: u32) -> String {
    build_bbs_url(
        Sub::Releases,
        page,
        Some(search_query.to_string()),
        None,
        Some(OrderBy::Featured),
    )
}

// TODO i don't really like how the cache is implemented, it's sorta just slapped on
async fn impl_bbs(
    bbs_cache: &mut BBSCache,
    db: &mut DB,
    tab: &Arc<Tab>,
    pico8_bins: &Vec<String>,
    url: &str,
    page: u32,
) -> Vec<Cart> {
    info!("querying {url}");

    // memoize crawl_bbs
    // TODO this is disgusting code
    let res = match bbs_cache.query(url) {
        Some(cached) => cached.to_vec(),
        None => {
            // actually make the request
            let res = crawl_bbs(tab.clone(), url).await;
            match res {
                Ok(res) => {
                    // cache the query
                    bbs_cache.insert(url, res.to_vec());
                    res
                },
                Err(e) => {
                    error!("failed to crawl bbs {e:?}");
                    return vec![];
                },
            }
        },
    };

    // download these carts if not in games/ directory
    let res_cloned = res.clone();

    let mut tasks = vec![];

    for cart in res_cloned {
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
                // New client in async task
                let client = reqwest::Client::new();
                if let Err(e) = download_cart(client, cart.download_url.clone(), &path).await {
                    warn!("failed to download cart {path:?}: {e:?}");
                }
            });
            tasks.push(task);
        }
    }

    // Wait for all the download tasks to complete
    let _ = join_all(tasks).await;

    // Postprocess carts
    for cart in res.iter() {
        let Some(filename) = filename_from_url(&cart.download_url) else {
            warn!("could not extract filename from url: {}", cart.download_url);
            continue;
        };

        // Download if we don't have a copy of it in our games dir
        let path = BBS_CART_DIR.join(filename);

        if let Err(e) = postprocess_cart(db, pico8_bins, cart, &path).await {
            warn!("failed to postprocess cart {e:?}");
            continue;
        }
    }

    res.to_vec()
}

// return the contents of the games dir
fn impl_bbs_local(db: &mut DB) -> anyhow::Result<Vec<Cart>> {
    let dir = &*GAMES_DIR; // TODO watch out for path traversal
    let mut filenames = vec![];
    if let Ok(read_dir) = read_dir(dir) {
        for entry in read_dir {
            let entry = entry.unwrap().path();
            if entry.is_file() {
                // for each file read metadata and pack into table string
                let filename = entry.file_stem().unwrap().to_str().unwrap().to_owned();
                filenames.push(filename);
            }
        }
    }

    debug!("querying {} carts", filenames.len());

    db.get_cart_by_filenames(filenames)
}

async fn impl_download_music(db: &mut DB, cart_id: CartId) -> anyhow::Result<()> {
    // TODO can also just supply the cartname directly
    // find the name of the cart (using id)
    let cart = db.get_cart_by_id(cart_id)?;

    // obtain path of cart in filesystem
    let mut cart_path = GAMES_DIR.join(&cart.filename);
    cart_path.set_extension("p8");

    // try to download the cart if it isnt already
    if !cart_path.exists() {
        // TODO
        debug!("cart {cart_path:?} does not exist, attempting to download");
        let client = reqwest::Client::new();
        let path = BBS_CART_DIR.join(&cart.filename);
        download_cart(client, cart.download_url.clone(), &path).await?;
        debug!("successfully downloaded cart cart: {cart_path:?}");
    }

    // convert cart to music file
    let music_cart = p8util::cart2music(&cart_path)?;

    // write music cart file to filesystem
    let mut music_path = MUSIC_DIR.join(&cart.filename);
    music_path.set_extension("p8");
    let mut music_file = File::create(music_path.clone())?;
    music_cart.write(&mut music_file)?;

    Ok(())
}

async fn write_to_pico8(msg: String) {
    let mut in_pipe = open_in_pipe().expect("failed to open pipe");
    writeln!(in_pipe, "{msg}",).expect("failed to write to pipe");
    drop(in_pipe);
}

#[derive(Default, Debug)]
pub struct SystemInfo {
    platform: String,
    wifi_enabled: bool,
    bt_enabled: bool,
}

impl SystemInfo {
    pub fn to_lua_table(&self) -> String {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("platform".into(), Value::String(self.platform.to_string()));
        prop_map.insert(
            "wifi_enabled".into(),
            Value::String(self.wifi_enabled.to_string()),
        );
        prop_map.insert(
            "bt_enabled".into(),
            Value::String(self.bt_enabled.to_string()),
        );
        serialize_table(&prop_map)
    }
}

fn impl_info() -> SystemInfo {
    let mut info = SystemInfo::default();

    // set the platform
    {
        info.platform = "unknown".into();

        #[cfg(target_os = "macos")]
        {
            info.platform = "macos".into();
        }

        #[cfg(target_os = "linux")]
        {
            info.platform = "linux".into();
        }

        #[cfg(target_os = "windows")]
        {
            info.platform = "windows".into();
        }
    }

    #[cfg(feature = "network")]
    {
        info.wifi_enabled = true;
    }

    #[cfg(feature = "bluetooth")]
    {
        info.bt_enabled = true;
    }

    info
}
