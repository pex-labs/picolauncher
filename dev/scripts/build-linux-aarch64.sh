#!/bin/sh

set -e

build_dir=build/build-linux-aarch64

# create file structure
mkdir -p build/
rm -rf $build_dir
mkdir -p $build_dir
mkdir -p $build_dir/drive/
mkdir -p $build_dir/drive/screenshots/
mkdir -p $build_dir/drive/carts/
mkdir -p $build_dir/drive/carts/screenshots/

# build executables
cross build --release --target aarch64-unknown-linux-gnu

# install files
cp -r drive/carts/{games,labels,metadata,music} $build_dir/drive/carts
cp -r drive/carts/{*.p8,*.lua} $build_dir/drive/carts/
cp drive/config_template.txt $build_dir/drive/config.txt

cp target/aarch64-unknown-linux-gnu/release/picolauncher $build_dir/picolauncher
cp target/aarch64-unknown-linux-gnu/release/p8util $build_dir/p8util

zip -r picolauncher-linux-aarch64.zip $build_dir
