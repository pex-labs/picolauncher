// TODO maybe switch to async
use std::{
    collections::HashMap,
    ffi::OsStr,
    fs::{create_dir_all, read_dir, read_to_string, File, OpenOptions},
    io::{BufRead, BufReader, Read, Write},
    ops::ControlFlow,
    path::{Path, PathBuf},
    ptr,
    sync::Arc,
    thread,
    time::{Duration, Instant},
};

use anyhow::anyhow;
use futures::future::join_all;
use headless_chrome::{Browser, LaunchOptions, Tab};
use log::{debug, error, info, warn};
use network_manager::{
    AccessPoint, AccessPointCredentials, Device, DeviceType, NetworkManager, ServiceState,
};
use notify::event::CreateKind;
use notify_debouncer_full::{new_debouncer, notify, DebounceEventResult};
use picolauncher::{
    bbs::*,
    bluetooth::*,
    consts::*,
    db,
    exe::ExeMeta,
    hal::*,
    p8util::{self, *},
};
use serde_json::{Map, Value};
use tokio::{process::Command, runtime::Runtime, sync::Mutex};

use crate::db::{schema::CartId, Cart, DB};

fn create_dirs() -> anyhow::Result<()> {
    create_dir_all(EXE_DIR.as_path())?;
    create_dir_all(CART_DIR.as_path())?;
    create_dir_all(GAMES_DIR.as_path())?;
    create_dir_all(MUSIC_DIR.as_path())?;
    create_dir_all(LABEL_DIR.as_path())?;
    create_dir_all(METADATA_DIR.as_path())?;
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

    // set up dbus connection and network manager
    // TODO linux specific currently
    // start network manager if not started
    let did_nm_start = NetworkManager::start_service(1000);
    match did_nm_start {
        Ok(_) => {
            println!("Network manager service started successfully!");
            let nm_state =
                NetworkManager::get_service_state().expect("unable to get network manager state");
            if nm_state != ServiceState::Active {
                // TODO maybe implement retry loop to attempt starting nm multiple times
                error!("failed to start network manager");
                return;
            }
        },
        Err(err) => {
            println!("Failed to start network manager service: {}", err);
        },
    }

    let nm = NetworkManager::new();
    let mut access_points: Vec<AccessPoint> = vec![];

    let session = bluer::Session::new().await.unwrap();
    let adapter = Arc::new(session.default_adapter().await.unwrap());
    println!("Using Bluetooth adapter: {}", adapter.name());
    // Ensure the adapter is powered on
    adapter.set_powered(true).await.unwrap();

    let mut bt_status = Arc::new(Mutex::new(BluetoothStatus::new(&adapter).await.unwrap()));

    // create necessary directories
    if let Err(e) = create_dirs() {
        warn!("failed to create directories: {e:?}")
    }

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
    let init_cart = "main_menu.p8";
    let mut pico8_process = launch_pico8_binary(
        &pico8_bins,
        vec![
            "-home",
            DRIVE_DIR,
            "-run",
            &format!("drive/carts/{init_cart}"),
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
    cartstack.push(init_cart.into());

    // connect to database
    let mut db = DB::connect(db::DB_PATH).expect("unable to establish connection with database");
    debug!("established connection to sqlite database");
    db.migrate().expect("failed migrating database");

    // enable IMU
    // TODO should put this behind a feature flag
    // TODO print error message if this failed
    let mut imu: Option<Arc<LSM9DS1>> = match LSM9DS1::new("/dev/i2c-5", true) {
        Ok(imu) => Some(Arc::new(imu)),
        Err(e) => {
            warn!("LSM9DS1 IMU failed to initialize {e:?}");
            None
        },
    };
    if let Some(ref imu) = imu {
        let imu = Arc::clone(&imu);
        tokio::spawn(async move {
            imu.start().await.unwrap();
        });
    }

    // db.add_favorite("advent2024-27.p8")
    //     .expect("failed to add to fav");
    // db.get_favorites().expect("failed to get fav");

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
                let mut child = Command::new("pico8") // TODO absolute path to pico8?
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
                writeln!(in_pipe, "{}", exes_joined).expect("failed to write to pipe");
                drop(in_pipe);
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
                    impl_bbs_local()
                } else if query == "favorite" {
                    // special case, return favorite carts
                    db.get_favorites(20).unwrap()
                } else if let Some(search_query) = query.strip_prefix("search:") {
                    let url = bbs_url_for_search(search_query, page);
                    impl_bbs(&mut db, &tab, &pico8_bins, &url, page).await
                } else {
                    let query = query
                        .parse::<PexsploreCategory>()
                        .unwrap_or(PexsploreCategory::Featured);
                    let url = bbs_url_for_category(query, page);
                    impl_bbs(&mut db, &tab, &pico8_bins, &url, page).await
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

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", cartdatas_encoded).expect("failed to write to pipe");
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
            "pushcart" => {
                // when loading a new cart, can push the current cart and use as breadcrumb
                cartstack.push(data.into());
            },
            "popcart" => {
                // remove latest cart from stack
                let _ = cartstack.pop();
                let topcart = cartstack.last().cloned().unwrap_or_default();
                debug!("popcart topcart is {topcart}");

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", topcart).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "wifi_list" => {
                // scan for networks
                let networks = impl_wifi_list(&nm, &mut access_points).unwrap();
                let networks = networks
                    .into_iter()
                    .map(|x| x.to_lua_table())
                    .collect::<Vec<_>>();

                // TODO save this to global state

                println!("found networks {}", networks.join(","));
                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", networks.join(",")).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "wifi_connect" => {
                // Grab password and connect to wifi, returning success or failure info
                // TODO any security concerns with

                // TODO use hw_address as unique id?
                let mut split = data.splitn(2, ",");
                let ssid = split.next().unwrap_or_default();
                let psk = split.next().unwrap_or_default();

                let res = impl_wifi_connect(&nm, &mut access_points, ssid, psk);
                println!("wifi connection result {res:?}");

                let status = impl_wifi_status(&nm);

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", status).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "wifi_disconnect" => {
                let res = impl_wifi_disconnect(&nm);
                println!("wifi disconnection result {res:?}");

                let status = impl_wifi_status(&nm);

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", status).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "wifi_status" => {
                // Get if wifi is connected or not, the current network, and the strength of connection
                let status = impl_wifi_status(&nm);
                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{}", status).expect("failed to write to pipe");
                drop(in_pipe);
            },
            "bt_start" => {
                println!("HELLO");
                let _ = update_connected_devices(bt_status.clone(), adapter.clone()).await;
                tokio::spawn({
                    let bt_status = bt_status.clone();
                    let adapter = adapter.clone();
                    async move {
                        discover_devices(bt_status.clone(), adapter).await.unwrap();
                    }
                });
            },
            "bt_stop" => {
                let mut bt_status_guard = bt_status.lock().await;
                bt_status_guard.stop();
            },

            "bt_status" => {
                let mut bt_status_guard = bt_status.lock().await;

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(
                    in_pipe,
                    "{}",
                    bt_status_guard.get_status_table(&adapter).await.unwrap()
                )
                .expect("failed to write to pipe");
                drop(in_pipe);
            },
            "set_favorite" => {
                let mut split = data.splitn(2, ",");
                let cart_id = split.next().unwrap().parse::<i32>().unwrap();
                let is_favorite = split.next().unwrap().parse::<bool>().unwrap();

                // TODO better error handling
                db.set_favorite(cart_id, is_favorite).unwrap();

                let mut in_pipe = open_in_pipe().expect("failed to open pipe");
                writeln!(in_pipe, "{cart_id},{is_favorite}").expect("failed to write to pipe");
                drop(in_pipe);
            },
            "list_favorite" => {},
            "bt_connect" => {},
            "bt_disconnect" => {},
            "download_music" => {
                let cart_id = data.parse::<i32>().unwrap();
                let res = impl_download_music(&mut db, cart_id).await;
                if let Err(ref e) = res {
                    warn!("download_music failed {e:?}");
                }
                write_to_pico8(format!("{}", res.is_ok())).await;
            },
            "gyro_read" => {
                if imu.is_some() {
                    let imu = Arc::clone(&imu.clone().unwrap());
                    let (pitch, roll) = imu.get_tilt().await;
                    debug!("got imu data {},{}", pitch, roll);
                    write_to_pico8(format!("{pitch},{roll}")).await;
                } else {
                    write_to_pico8(format!("0,0")).await;
                }
                write_to_pico8(format!("0,0")).await;
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

// TODO this function is pretty similar to the functionality in cli.rs - should aggerate this
async fn postprocess_cart(
    db: &mut DB,
    pico8_bins: &Vec<String>,
    cart: &Cart,
    path: &Path,
) -> anyhow::Result<()> {
    // TODO: since path.file_prefix is still unstable, we need to split on the first period
    let filename = path.file_name().unwrap().to_str().unwrap();
    let mut split = filename.splitn(2, ".");
    let filestem = split.next().unwrap();

    // generate p8 file from p8.png file
    let mut dest_path = GAMES_DIR.join(filestem);
    dest_path.set_extension("p8");
    if !dest_path.exists() {
        pico8_export(&pico8_bins, path, &dest_path)
            .await
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
    /*
    let mut metadata_path = METADATA_DIR.clone().join(filestem);
    metadata_path.set_extension("json");
    if !metadata_path.exists() {
        let metadata_serialized = serde_json::to_string_pretty(cart).unwrap();

        let mut metadata_file = File::create(metadata_path.clone()).unwrap();
        metadata_file
            .write_all(metadata_serialized.as_bytes())
            .unwrap();
    }
    */

    // save metadata to db
    // TODO might be nicer to do batch insert instead of single query per cart?
    db.insert_cart(cart)?;

    Ok(())
}

pub struct WifiNetwork {
    pub ssid: String,
    pub name: String, // Display name of SSID
    pub strength: u32,
}

impl WifiNetwork {
    pub fn to_lua_table(&self) -> String {
        let mut prop_map = Map::<String, Value>::new();
        prop_map.insert("ssid".into(), Value::String(self.ssid.clone()));
        prop_map.insert("name".into(), Value::String(self.name.clone()));
        prop_map.insert("strength".into(), Value::String(self.strength.to_string()));
        serialize_table(&prop_map)
    }
}

// implementation for specific functions
fn impl_wifi_list(
    nm: &NetworkManager,
    access_points: &mut Vec<AccessPoint>,
) -> anyhow::Result<Vec<WifiNetwork>> {
    // TODO give each indexed access point a unique id (just index is fine?) so the
    // user is able to perform operations on the specific network
    let mut networks = vec![]; // TODO this should be some global state?

    // need to run find device inside here since WiFiDevice is not exported :(
    let wifi_device = find_device(nm)?;
    let wifi_device = wifi_device.as_wifi_device().unwrap();

    // store the queried access points in global state
    let mut _access_points = wifi_device.get_access_points().unwrap();
    access_points.clear();
    access_points.extend(_access_points.drain(..));

    let wifi_networks = access_points
        .into_iter()
        .filter_map(|x| {
            let Ok(ssid) = x.ssid().as_str() else {
                return None;
            };

            Some(WifiNetwork {
                ssid: ssid.to_string(),
                name: ssid.to_ascii_lowercase(),
                strength: x.strength,
            })
        })
        .collect::<Vec<_>>();
    networks.extend(wifi_networks);

    return Ok(networks);
}

fn impl_wifi_connect(
    nm: &NetworkManager,
    access_points: &mut Vec<AccessPoint>,
    ssid: &str,
    psk: &str,
) -> anyhow::Result<()> {
    let wifi_device = find_device(nm)?;
    let wifi_device = wifi_device.as_wifi_device().unwrap();

    // TODO seems like we need to disconnect from existing network before connecting to a new one?

    // find the ssid
    let Some(ap) = access_points
        .iter()
        .find(|x| x.ssid().as_str().unwrap() == ssid)
    else {
        return Err(anyhow!("Cannot find access point with ssid {ssid}"));
    };

    let credentials = AccessPointCredentials::Wpa {
        passphrase: psk.to_string(),
    };
    if let Err(e) = wifi_device.connect(&ap, &credentials) {
        return Err(anyhow!("Failed to connect to access point {e}"));
    }

    Ok(())
}

fn impl_wifi_disconnect(nm: &NetworkManager) -> anyhow::Result<()> {
    let wifi_device = find_device(nm)?;
    if let Err(e) = wifi_device.disconnect() {
        return Err(anyhow!("Failed to disconnect from access point {e}"));
    }

    Ok(())
}

// just return the serialized lua string directly
fn impl_wifi_status(nm: &NetworkManager) -> String {
    let mut prop_map = Map::<String, Value>::new();
    prop_map.insert("state".into(), Value::String("unknown".into()));

    let conns = nm.get_active_connections().unwrap_or_default();
    for conn in conns {
        let settings = conn.settings();
        // TODO double check this is the right string for all wireless
        if settings.kind == "802-11-wireless" {
            let ssid = settings.ssid.as_str().unwrap().to_string();
            let state = conn.get_state().unwrap();
            println!("wifi_status ssid={:?} state={state:?}", conn.settings());
            prop_map.insert("ssid".into(), Value::String(ssid));
            // TODO just doing the tostring impl here lol
            let state_str = match state {
                network_manager::ConnectionState::Unknown => "unknown",
                network_manager::ConnectionState::Activating => "connecting",
                network_manager::ConnectionState::Activated => "connected",
                network_manager::ConnectionState::Deactivating => "disconnecting",
                network_manager::ConnectionState::Deactivated => "disconnected",
            };
            prop_map.insert("state".into(), Value::String(state_str.into()));
            return serialize_table(&prop_map);
        }
    }

    warn!("wifi interface not found");
    serialize_table(&prop_map)
}

fn find_device(manager: &NetworkManager) -> anyhow::Result<Device> {
    // TODO error handling pretty lmao
    let devices = manager.get_devices().map_err(|e| anyhow!(format!("{e}")))?;

    let index = devices
        .iter()
        .position(|d| *d.device_type() == DeviceType::WiFi);

    if let Some(index) = index {
        Ok(devices[index].clone())
    } else {
        return Err(anyhow!("Cannot find a WiFi device"));
    }
}

async fn impl_bbs(
    db: &mut DB,
    tab: &Arc<Tab>,
    pico8_bins: &Vec<String>,
    url: &str,
    page: u32,
) -> Vec<Cart> {
    info!("querying {url}");

    let res = crawl_bbs(tab.clone(), &url).await;

    let res = match res {
        Ok(res) => res,
        Err(e) => {
            error!("failed to crawl bbs {e:?}");
            return vec![];
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

        if let Err(e) = postprocess_cart(db, &pico8_bins, &cart, &path).await {
            warn!("failed to postprocess cart {e:?}");
            continue;
        }
    }

    res
}

// return the contents of the games dir
fn impl_bbs_local() -> Vec<Cart> {
    let dir = &*GAMES_DIR; // TODO watch out for path traversal
    let mut carts = vec![];
    if let Ok(read_dir) = read_dir(dir) {
        for entry in read_dir {
            let entry = entry.unwrap().path();
            if entry.is_file() {
                // for each file read metadata and pack into table string
                let filename = entry.file_name().unwrap();
                let mut metapath = PathBuf::from(filename);
                metapath.set_extension("json");
                let metapath = METADATA_DIR.join(metapath);

                let Ok(content) = read_to_string(&metapath) else {
                    warn!("failed to read {:?}", metapath);
                    continue;
                };
                let Ok(parsed_meta): Result<Cart, serde_json::Error> =
                    serde_json::from_str(&content)
                else {
                    warn!("failed to parse into CartData {:?}", metapath);
                    continue;
                };

                carts.push(parsed_meta);
            }
        }
    }
    // TODO check efficiency for lots of files
    carts
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
