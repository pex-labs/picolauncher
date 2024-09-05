mod p8util;

use std::path::{Path, PathBuf};
use std::io;

use clap::{Parser, Subcommand};

#[derive(Subcommand, Debug)]
enum Commands {
    downscale,
    cart2music {
        cart_path: PathBuf
    }
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
        Commands::downscale => todo!(),
        Commands::cart2music{ cart_path } => {
            match p8util::cart2music(cart_path) {
                Ok(cart) => {
                    cart.write(&mut io::stdout()).unwrap();                   
                },
                Err(e) => eprintln!("{}", e),
            }
        },
    }
}
