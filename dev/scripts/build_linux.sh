#!/bin/sh

set -e

# create file structure
rm -rf build_linux
mkdir -p build_linux/
mkdir -p build_linux/drive/
mkdir -p build_linux/drive/screenshots/
mkdir -p build_linux/drive/carts/
mkdir -p build_linux/drive/carts/screenshots/

# build executables
cargo build --release --target x86_64-unknown-linux-gnu

# install files
cp -r drive/carts/{games,labels,metadata,music} build_linux/drive/carts
cp -r drive/carts/{*.p8,*.lua} build_linux/drive/carts/
cp drive/config_template.txt build_linux/drive/config.txt

cp target/x86_64-unknown-linux-gnu/release/picolauncher build_linux/picolauncher
cp target/x86_64-unknown-linux-gnu/release/p8util build_linux/p8util

zip -r build_linux.zip build_linux/
