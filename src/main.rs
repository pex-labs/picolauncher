use std::path::{Path, PathBuf};
use lazy_static::lazy_static;
use nix::unistd::{mkfifo, Pid};
use nix::sys::stat::Mode;
use nix::sys::signal::{kill, Signal};
use std::fs::{OpenOptions, File, read_dir};
use std::io::{Write, Read, BufRead, BufReader};
use std::process::{Command};

// root directory from perspective of pico8 process
const DRIVE_DIR: &'static str = "drive";

lazy_static! {
    // in file from the perspective of pico8 process, so we write to this
    static ref IN_PIPE: PathBuf = PathBuf::from("in_pipe");
    // out file from the perspective of pico8 process, so we read from this
    static ref OUT_PIPE: PathBuf = PathBuf::from("out_pipe");
    static ref EXE_DIR: PathBuf = PathBuf::from("drive/exe");
    static ref CART_DIR: PathBuf = PathBuf::from("drive/carts");
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
    // TODO capture stdout of pico8 and log it
    let pico8_process = Command::new("pico8") // TODO this assumes pico8 is in path
        .args(vec!["-home", DRIVE_DIR, "-run", "drive/carts/launcher.p8", "-i", "in_pipe", "-o", "out_pipe"])
        .spawn()
        .expect("failed to spawn pico8 process");
    let pico8_pid = Pid::from_raw(pico8_process.id() as i32);

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

        // TODO this busy loops?
        if line.len() == 0 {
            continue;
        }
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
                let exe_path = EXE_DIR.join(data).join(data); // TODO assume exe name is same as the directory name
                println!("spawning executable {exe_path:?}");
                let mut child = Command::new(exe_path)
                    .args(vec!["-home", DRIVE_DIR]) // TODO when spawning should we override the config.txt?
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process"); 

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process"); 

            }
            "spawnp" => {
                // execute a pico8 cart as an external process
                let cart_path = CART_DIR.join(data);

                println!("spawning executable {cart_path:?}");
                let mut child = Command::new("pico8") // TODO absolute path to pico8?
                    .args(vec!["-home", DRIVE_DIR, "-run", cart_path.to_str().unwrap()])
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process"); 

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process"); 

            }
            "ls" => {
                // fetch all carts in directory 
                let dir = (&*CART_DIR).join(data); // TODO watch out for path traversal
                let mut carts = vec![];
                for entry in read_dir(dir).unwrap() {
                    let entry = entry.unwrap().path();
                    if entry.is_file() {
                        let filename = entry.file_name().unwrap().to_str().unwrap().to_string();
                        carts.push(filename); 
                    }
                }
                // TODO check efficiency for lots of files

                // TODO make this pipe writing stuff better (duplicate code)
                let mut in_pipe = OpenOptions::new().write(true).open(&*IN_PIPE).expect("failed to open pipe {IN_PIPE}");
                let joined_carts = carts.join(",");
                writeln!(in_pipe, "{}", joined_carts).expect("failed to write to pipe {IN_PIPE}");
                drop(in_pipe);
            },
            "label" => {
                // fetch a label for a given cart, scaled to a given size
            }
            "splore" => {

                let mut child = Command::new("pico8") // TODO absolute path to pico8?
                    .args(vec!["-home", DRIVE_DIR, "-splore"])
                    .spawn()
                    .unwrap();

                // suspend current pico8 process and swap with newly spawned process
                kill(pico8_pid, Signal::SIGSTOP).expect("failed to send SIGSTOP to pico8 process"); 

                // unsuspend when child finishes
                child.wait().unwrap();
                kill(pico8_pid, Signal::SIGCONT).expect("failed to send SIGCONT to pico8 process"); 
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
