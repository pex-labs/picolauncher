
default: debug

debug:
    cargo run

pico8:
    pico8 -home drive -run drive/carts/serial.p8 -i in_pipe -o out_pipe

export:
    pico8 os.p8 -export os.bin

devsetup:
    cp dev/hooks/* .git/hooks

fmt:
    cargo +nightly fmt --all

lint:
    cargo clippy -- -W clippy::unwrap_used -W clippy::cargo
