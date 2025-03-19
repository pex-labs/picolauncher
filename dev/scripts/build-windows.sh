#!/bin/sh

set -e

build_dir=build/build-windows

# create file structure
mkdir -p build/
rm -rf $build_dir
mkdir -p $build_dir
mkdir -p $build_dir/drive/
mkdir -p $build_dir/drive/screenshots/
mkdir -p $build_dir/drive/carts/
mkdir -p $build_dir/drive/carts/screenshots/

# build executables
cross build --release --target x86_64-pc-windows-gnu

# install files
cp -r drive/carts/{games,labels,music} $build_dir/drive/carts
cp -r drive/carts/{*.p8,*.lua} $build_dir/drive/carts/
cp drive/config_template.txt $build_dir/drive/config.txt

cp target/x86_64-pc-windows-gnu/release/picolauncher.exe $build_dir/picolauncher.exe
cp target/x86_64-pc-windows-gnu/release/p8util.exe $build_dir/p8util.exe

zip -r picolauncher-windows.zip $build_dir
