mod consts;
mod p8util;

use std::{
    fs,
    fs::File,
    io,
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
}

#[derive(Parser, Debug)]
#[command(version, about)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
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
    }
}
