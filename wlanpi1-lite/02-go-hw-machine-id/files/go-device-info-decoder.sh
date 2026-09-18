#!/bin/bash
#
# go-device-info-decoder.sh - Decode serial number
# 
# Version: v0.1
# Author: Josh Schmelzle
# License: BSD-3

VERSION="0.1"

usage() {
    cat << EOF
go-device-info-decoder.sh v${VERSION} - Decode Go hardware device info

Description:
    This script decodes the base64 encoded serial number and other 
    data stored by the go-hw-machine-id.sh script.

Usage:
    ./go-device-info-decoder.sh [OPTIONS]

Options:
    -h, --help      Display this help message and exit
    -v, --version   Display version information and exit

Files:
    /home/.device-info/serial    - Encoded serial number
    /home/.device-info/productid - Product ID
    /home/.device-info/firmware  - Firmware
    /home/.device-info/revision  - Hardware revision
    /home/.device-info/model     - Model

Example:
    ./go-device-info-decoder.sh
    sudo ./go-device-info-decoder.sh

Author: Josh Schmelzle
License: BSD-3
EOF
}

version() {
    echo "go-device-info-decoder.sh v${VERSION}"
}

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
    -v|--version)
        version
        exit 0
        ;;
    *)
        ;;
esac

INPUT_FILE="/home/.device-info/serial"
PRODUCT_FILE="/home/.device-info/productid"
FIRMWARE_FILE="/home/.device-info/firmware"
REVISION_FILE="/home/.device-info/revision"
MODEL_FILE="/home/.device-info/model"

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: need root to run ..."
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: can't find $INPUT_FILE  ..."
    exit 1
fi

ENCODED_SERIAL=$(cat "$INPUT_FILE")
DECODED_SERIAL=$(echo "$ENCODED_SERIAL" | base64 -d)
PRODUCT_ID=$(cat "$PRODUCT_FILE")
FIRMWARE=$(cat "$FIRMWARE_FILE")
REVISION=$(cat "$REVISION_FILE")
MODEL=$(cat "$MODEL_FILE")

echo "Encoded serial number: $ENCODED_SERIAL"
echo "Decoded serial number: $DECODED_SERIAL"
echo "Product ID: $PRODUCT_ID"
echo "Firmware: $FIRMWARE"
echo "Hardware revision: $REVISION"
echo "Model: $MODEL"

exit 0
