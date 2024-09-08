mod consts;
mod p8util;

use std::{
    fs,
    fs::File,
    io,
    io::Write,
    path::{Path, PathBuf},
};

use clap::{Parser, Subcommand};
use consts::*;

#[derive(Subcommand, Debug)]
enum Commands {
    cart2music {
        cart_path: Option<PathBuf>,
        #[arg(short, long)]
        all: bool,
    },
    cart2label {
        cart_path: Option<PathBuf>,
        #[arg(short, long)]
        all: bool,
    },
    addcart {
        cart_path: PathBuf,
        #[arg(short, long)]
        name: Option<String>,
        #[arg(short, long)]
        author: Option<String>,
    },
}

#[derive(Parser, Debug)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

// TODO this does not belong here
#[derive(serde::Serialize)]
struct Metadata {
    name: String,
    filename: String,
    author: String,
    tags: String,
}

fn main() {
    let cli = Cli::parse();

    match &cli.command {
        Commands::cart2music { cart_path, all } => {
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
            } else {
                if let Some(cart_path) = cart_path {
                    match p8util::cart2music(cart_path) {
                        Ok(cart) => {
                            cart.write(&mut io::stdout()).unwrap();
                        },
                        Err(e) => eprintln!("{}", e),
                    }
                }
            }
        },
        Commands::cart2label { cart_path, all } => {
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
            } else {
                if let Some(cart_path) = cart_path {
                    match p8util::cart2label(cart_path) {
                        Ok(cart) => {
                            cart.write(&mut io::stdout()).unwrap();
                        },
                        Err(e) => eprintln!("{}", e),
                    }
                }
            }
        },
        Commands::addcart {
            cart_path,
            name,
            author,
        } => {
            // TODO we currently don't do any form of checking on if the cart that is passed is valid

            let cart_name = cart_path.file_stem().unwrap().to_str().unwrap();
            let mut game_path = GAMES_DIR.clone().join(cart_name.clone());
            game_path.set_extension("p8");

            // copy the cart to games directory
            if let Err(e) = fs::copy(cart_path, game_path.clone()) {
                eprintln!("failed to copy file: {e}");
                std::process::exit(1);
            }
            println!("copied game to {game_path:?}");

            // generate label
            // TODO all this is duplicate logic
            let cart = match p8util::cart2label(&game_path) {
                Ok(cart) => cart,
                Err(e) => {
                    eprintln!("failed to generate label for file : {e}");
                    std::process::exit(1);
                },
            };

            let mut label_path = LABEL_DIR.clone().join(cart_name);
            label_path.set_extension("64.p8");
            let mut label_file = File::create(label_path.clone()).unwrap();
            cart.write(&mut label_file).unwrap();
            println!("generated label {label_path:?}");

            // generate metadata file
            let metadata = Metadata {
                name: name.clone().unwrap_or(cart_name.to_owned()),
                filename: cart_name.to_owned(),
                author: author.clone().unwrap_or_default(),
                tags: String::new(),
            };

            let metadata_serialized = serde_json::to_string_pretty(&metadata).unwrap();

            let mut metadata_path = METADATA_DIR.clone().join(cart_name);
            metadata_path.set_extension("json");
            let mut metadata_file = File::create(metadata_path.clone()).unwrap();
            metadata_file
                .write_all(metadata_serialized.as_bytes())
                .unwrap();
            println!("generated metadata {metadata_path:?}");

            // generate music file
            let music_cart = match p8util::cart2music(&game_path) {
                Ok(cart) => cart,
                Err(e) => {
                    eprintln!("failed to generate music for file: {e}");
                    std::process::exit(1);
                },
            };

            let mut music_path = MUSIC_DIR.clone().join(cart_name);
            music_path.set_extension("p8");
            let mut music_file = File::create(music_path.clone()).unwrap();
            music_cart.write(&mut music_file).unwrap();
            println!("generated music {music_path:?}");
        },
    }
}
