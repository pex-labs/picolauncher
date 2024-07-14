use std::path::{Path, PathBuf};
use lazy_static::lazy_static;
use nix::unistd::mkfifo;
use nix::sys::stat::Mode;
use std::fs::{OpenOptions, File};
use std::io::Write;

lazy_static! {
    // in file from the perspective of pico8 process, so we write to this
    static ref IN_PIPE: PathBuf = PathBuf::from("in_pipe");
    // out file from the perspective of pico8 process, so we read from this
    static ref OUT_PIPE: PathBuf = PathBuf::from("out_pipe");
}

/// create named pipes if they don't exist
fn create_pipe(pipe: &Path) {
    if !pipe.exists() {
        mkfifo(pipe, Mode::S_IRUSR | Mode::S_IWUSR).expect("failed to create pipe {pipe}");
    }
}

fn main() {
    // set up environment
    create_pipe(&IN_PIPE);
    create_pipe(&OUT_PIPE);

    // spawn pico8 process and setup pipes

    // send hello message to pico8 process
    let mut in_pipe = OpenOptions::new().write(true).open(&*IN_PIPE).expect("failed to open pipe {IN_PIPE}");
    writeln!(in_pipe, "E").expect("failed to write to pipe {IN_PIPE}");

    // listen for commands from pico8 process
    loop {

    }  

}
