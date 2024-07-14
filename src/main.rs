use std::path::{Path, PathBuf};
use lazy_static::lazy_static;
use nix::unistd::mkfifo;
use nix::sys::stat::Mode;
use std::fs::{OpenOptions, File};
use std::io::{Write, Read, BufRead, BufReader};
use std::process::{Command};

lazy_static! {
    // in file from the perspective of pico8 process, so we write to this
    static ref IN_PIPE: PathBuf = PathBuf::from("in_pipe");
    // out file from the perspective of pico8 process, so we read from this
    static ref OUT_PIPE: PathBuf = PathBuf::from("out_pipe");
    static ref EXE_DIR: PathBuf = PathBuf::from("drive/exe");
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
    drop(in_pipe);

    let mut out_pipe = OpenOptions::new().read(true).open(&*OUT_PIPE).expect("failed to open pipe {OUT_PIPE}");
    let mut reader = BufReader::new(out_pipe);

    // listen for commands from pico8 process
    loop {

        let mut line = String::new();
        reader.read_line(&mut line).expect("failed to read line from pipe");
        line = line.trim().to_string();
        println!("received [{}] {}", line.len(), line);

        // spawn process command
        let mut split = line.splitn(2, ':');
        let cmd = split.next().unwrap_or("");
        let data = split.next().unwrap_or("");
        println!("received cmd:{cmd} data:{data}");

        match cmd {
            "spawn" => {
                // TODO double check that the command to run is in the exec directory (to avoid
                // arbitrary code execution)

                // spawn an executable of given name
                // TODO ensure no ../ escape
                let exe_path = EXE_DIR.join(data);
                println!("spawning executable {exe_path:?}");
                let child = Command::new(exe_path)
                    .spawn()
                    .unwrap();
            }
            "hello" => {
                println!("ack hello");
            }
            _ => {
                println!("unhandled command");
            }
        }

        // acknowledge the write

    }  

}
