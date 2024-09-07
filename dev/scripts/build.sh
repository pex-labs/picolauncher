#!/bin/sh

set -e

# create file structure
rm -rf build
mkdir -p build/
mkdir -p build/drive/
mkdir -p build/drive/screenshots/
mkdir -p build/drive/carts/
mkdir -p build/drive/carts/screenshots/

# build executables
cargo build --release --target x86_64-unknown-linux-gnu
cargo build --release --target x86_64-pc-windows-gnu

# install files
cp -r drive/carts/{games,labels,metadata,music} build/drive/carts
cp -r drive/carts/{*.p8,*.lua} build/drive/carts/
cp drive/config_template.txt build/drive/config.txt
cp target/x86_64-unknown-linux-gnu/release/pexos build/pexos_linux
cp target/x86_64-pc-windows-gnu/release/pexos.exe build/pexos_windows.exe

zip -r build.zip build/
