#!/bin/sh

set -e

build_dir=build/build-linux-armv7

# create file structure
mkdir -p build/
rm -rf $build_dir
mkdir -p $build_dir
mkdir -p $build_dir/drive/
mkdir -p $build_dir/drive/screenshots/
mkdir -p $build_dir/drive/carts/
mkdir -p $build_dir/drive/carts/screenshots/

# build executables
cross build --release --target armv7-unknown-linux-gnueabihf

# install files
cp -r drive/carts/{games,labels,music} $build_dir/drive/carts
cp -r drive/carts/{*.p8,*.lua} $build_dir/drive/carts/
cp drive/config_template.txt $build_dir/drive/config.txt

cp target/armv7-unknown-linux-gnueabihf/release/picolauncher $build_dir/picolauncher
cp target/armv7-unknown-linux-gnueabihf/release/p8util $build_dir/p8util

zip -r picolauncher-linux-armv7.zip $build_dir
