#!/bin/sh

set -e

rm -rf build
mkdir -p build/
mkdir -p build/drive/
mkdir -p build/drive/screenshots/
mkdir -p build/drive/carts/
mkdir -p build/drive/carts/screenshots/

cargo build --release --target x86_64-unknown-linux-gnu
cp -r drive/carts/{games,labels,metadata,music} build/drive/carts
cp -r drive/carts/{*.p8,*.lua} build/drive/carts/
cp drive/config_template.txt build/drive/config.txt

cp target/x86_64-unknown-linux-gnu/release/pexos build/pexos_linux

zip -r build.zip build/
