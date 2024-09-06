
use std::path::PathBuf;

use lazy_static::lazy_static;

// root directory from perspective of pico8 process
pub const DRIVE_DIR: &'static str = "drive";

lazy_static! {
    // in file from the perspective of pico8 process, so we write to this
    pub static ref IN_PIPE: PathBuf = PathBuf::from("in_pipe");
    // out file from the perspective of pico8 process, so we read from this
    pub static ref OUT_PIPE: PathBuf = PathBuf::from("out_pipe");
    pub static ref EXE_DIR: PathBuf = PathBuf::from("drive/exe");
    pub static ref CART_DIR: PathBuf = PathBuf::from("drive/carts");
    pub static ref GAMES_DIR: PathBuf = PathBuf::from("drive/carts/carts");
    pub static ref LABEL_DIR: PathBuf = PathBuf::from("drive/carts/labels");
    pub static ref METADATA_DIR: PathBuf = PathBuf::from("drive/carts/metadata");

}

// path of png files generated by pico8
pub const RAW_SCREENSHOT_PATH: &'static str = "drive/screenshots";

// path of scaled cart screenshots
pub const SCREENSHOT_PATH: &'static str = "drive/carts/screenshots";

