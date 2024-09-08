#!/bin/sh

set -e

# create file structure
rm -rf build_windows
mkdir -p build_windows/
mkdir -p build_windows/drive/
mkdir -p build_windows/drive/screenshots/
mkdir -p build_windows/drive/carts/
mkdir -p build_windows/drive/carts/screenshots/

# build executables
cargo build --release --target x86_64-pc-windows-gnu

# install files
cp -r drive/carts/{games,labels,metadata,music} build_windows/drive/carts
cp -r drive/carts/{*.p8,*.lua} build_windows/drive/carts/
cp drive/config_template.txt build_windows/drive/config.txt

cp target/x86_64-pc-windows-gnu/release/picolauncher.exe build_windows/picolauncher.exe
cp target/x86_64-pc-windows-gnu/release/p8util.exe build_windows/p8util.exe

zip -r build_windows.zip build_windows/
