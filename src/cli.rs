use std::{fs, fs::File, io, path::PathBuf};

use clap::{Parser, Subcommand};
use log::{debug, error};
use picolauncher::{
    bbs::{download_cart, postprocess_cart, scrape_cart},
    consts::*,
    db::{self, schema::Cart, DB},
    hal::PICO8_BINS,
    p8util::{self, filename_from_url},
};

#[derive(Subcommand, Debug)]
enum Commands {
    #[command(name = "cart2music")]
    CartToMusic {
        cart_path: Option<PathBuf>,
        #[arg(short, long)]
        all: bool,
    },
    #[command(name = "cart2label")]
    CartToLabel {
        cart_path: Option<PathBuf>,
        #[arg(short, long)]
        all: bool,
    },
    addcart {
        cart_url: String,
    },
}

#[derive(Parser, Debug)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();

    match &cli.command {
        Commands::CartToMusic { cart_path, all } => {
            // TODO this is duplicate logic
            if *all {
                let entries = fs::read_dir(GAMES_DIR.as_path()).unwrap();
                for entry in entries {
                    let entry = entry.unwrap();
                    let cart_path = entry.path(); // shadow
                    if cart_path.is_file() {
                        // TODO clear the cart dir first?
                        match p8util::cart2music(cart_path.as_path()) {
                            Ok(cart) => {
                                let cart_name = cart_path.file_name().unwrap();
                                let mut music_path = MUSIC_DIR.clone();
                                music_path.push(cart_name);

                                let mut music_file = File::create(music_path.clone()).unwrap();
                                cart.write(&mut music_file).unwrap();
                                println!("wrote {music_path:?}");
                            },
                            Err(e) => eprintln!("{}", e),
                        }
                    }
                }
            } else if let Some(cart_path) = cart_path {
                match p8util::cart2music(cart_path) {
                    Ok(cart) => {
                        cart.write(&mut io::stdout()).unwrap();
                    },
                    Err(e) => eprintln!("{}", e),
                }
            }
        },
        Commands::CartToLabel { cart_path, all } => {
            if *all {
                let entries = fs::read_dir(GAMES_DIR.as_path()).unwrap();
                for entry in entries {
                    let entry = entry.unwrap();
                    let cart_path = entry.path(); // shadow
                    if cart_path.is_file() {
                        // TODO clear the cart dir first?
                        match p8util::cart2label(cart_path.as_path()) {
                            Ok(cart) => {
                                let cart_name = cart_path.file_name().unwrap();
                                let mut label_path = LABEL_DIR.clone();
                                label_path.push(cart_name);
                                label_path.set_extension("64.p8");

                                let mut label_file = File::create(label_path.clone()).unwrap();
                                cart.write(&mut label_file).unwrap();
                                println!("wrote {label_path:?}");
                            },
                            Err(e) => eprintln!("{}", e),
                        }
                    }
                }
            } else if let Some(cart_path) = cart_path {
                match p8util::cart2label(cart_path) {
                    Ok(cart) => {
                        cart.write(&mut io::stdout()).unwrap();
                    },
                    Err(e) => eprintln!("{}", e),
                }
            }
        },
        Commands::addcart { cart_url } => {
            let mut db =
                DB::connect(db::DB_PATH).expect("unable to establish connection with database");
            debug!("established connection to sqlite database");
            db.migrate().expect("failed migrating database");

            let rt = tokio::runtime::Runtime::new().unwrap();
            let client = reqwest::Client::new();

            rt.block_on(async move {
                let cart = scrape_cart(&client, cart_url).await?;
                let filename =
                    filename_from_url(&cart.download_url).ok_or(anyhow::anyhow!("invalid url"))?;
                let dl_path = BBS_CART_DIR.join(filename);
                download_cart(client, cart.download_url.clone(), &dl_path).await?;
                postprocess_cart(&mut db, &PICO8_BINS, &cart, &dl_path).await?;
                anyhow::Ok(())
            })?;
        },
    }
    Ok(())
}
