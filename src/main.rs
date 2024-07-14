use std::path::Path;
use lazy_static::lazy_static;
use nix::unistd::mkfifo;
use nix::sys::stat::Mode;

lazy_static! {
    static ref IN_PIPE: &'static Path= Path::new("in_pipe");
    static ref OUT_PIPE: &'static Path= Path::new("out_pipe");
}

/// create named pipes if they don't exist
fn create_pipe(pipe: &Path) {
    if !pipe.exists() {
        mkfifo(pipe, Mode::S_IRUSR | Mode::S_IWUSR).expect("failed to create pipe {pipe}");
    }
}

fn main() {
    create_pipe(&IN_PIPE);
    create_pipe(&OUT_PIPE);
}
