
default: picolauncher

picolauncher:
    cargo run --bin picolauncher

util:
    cargo run --bin p8util

pico8:
    pico8 -home drive -run drive/carts/serial.p8 -i in_pipe -o out_pipe

export:
    pico8 -home drive -export os.bin drive/carts/os.p8

devsetup:
    cp dev/hooks/* .git/hooks

fmt:
    cargo +nightly fmt --all

lint:
    cargo clippy -- -W clippy::unwrap_used -W clippy::cargo

test:
    cargo test -- --nocapture
