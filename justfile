
default: picolauncher

picolauncher:
    RUST_LOG=picolauncher=debug cargo run --bin picolauncher

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
    RUSTFLAGS="-A unused" cargo clippy -- -W clippy::cargo

lint_fix:
    RUSTFLAGS="-A unused" cargo clippy --fix -- -W clippy::cargo

test:
    cargo test -- --nocapture

clean:
    rm -rf build; rm *.zip
