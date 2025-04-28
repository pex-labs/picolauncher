#!/bin/bash

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <ip_address>"
    exit 1
fi

IP_ADDRESS=$1
FIRMWARE_FILE="picolauncher-linux-aarch64.zip"

echo "Copying firmware to $IP_ADDRESS..."
scp $FIRMWARE_FILE dev@$IP_ADDRESS:~

ssh dev@$IP_ADDRESS "rm -rf ~/build-linux-aarch64; unzip $FIRMWARE_FILE; mv build/build-linux-aarch64 .; rmdir build"
