#!/bin/sh

set -e

build_dir=build/build-linux-x86_64

# create file structure
mkdir -p build/
rm -rf $build_dir
mkdir -p $build_dir
mkdir -p $build_dir/drive/
mkdir -p $build_dir/drive/screenshots/
mkdir -p $build_dir/drive/carts/
mkdir -p $build_dir/drive/carts/screenshots/

# build executables
cargo build --release --target x86_64-unknown-linux-gnu --no-default-features

# install files
# cp -r drive/carts/{games,labels,music} $build_dir/drive/carts
cp -r drive/carts/{*.p8,*.lua} $build_dir/drive/carts/
cp drive/config_template.txt $build_dir/drive/config.txt

cp target/x86_64-unknown-linux-gnu/release/picolauncher $build_dir/picolauncher
cp target/x86_64-unknown-linux-gnu/release/p8util $build_dir/p8util

zip -r picolauncher-linux-x86_64.zip $build_dir
