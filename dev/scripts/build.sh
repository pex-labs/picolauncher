#!/bin/sh

cross build --target=armv7-unknown-linux-gnueabihf
rm -rf build build.zip
mkdir -p build
cp target/armv7-unknown-linux-gnueabihf/debug/pexos build
cp -r drive build
cd build
zip -r build.zip *
cp build.zip ..
