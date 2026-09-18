#!/bin/bash

VERSION="1.0.0"

usage() {
    cat << EOF
go-hw-machine-id.sh v${VERSION} - Set machine-id from Go hardware serial number

Description:
    This script reads the hardware serial number from a Go device connected
    to the serial port, then uses it to set a persistent machine ID for the system.
    
    The script performs the following actions:
    
    1. Reads serial number from /dev/ttyAMA0
    2. Stores base64 encoded serial number at /home/.device-info/serial
    3. Sets the SHA-256 hash of the raw serial number at /etc/machine-id
    4. Retrieves other device-info from the serial port

Usage:
    sudo ./go-hw-machine-id.sh [OPTIONS]

Options:
    -h, --help      Display this help message and exit
    -v, --version   Display version information and exit

Files:
    /var/log/go-hw-id-encoder.log    - Log file with operation details
    /home/.device-info/serial        - Base64 encoded serial number storage
    /home/.device-info/productid     - Product ID storage
    /home/.device-info/firmware      - Firmware version
    /home/.device-info/revision      - Hardware revision
    /home/.device-info/model         - "Go" if productid == 14
    /etc/machine-id                  - System machine ID

Examples:
    sudo ./go-hw-machine-id.sh

Note:
    This script requires root privileges to run and modify system files.
    Once set, the serial number and machine-id files are made immutable
    and require 'chattr -i' to modify.

Author: Josh Schmelzle
License: BSD-3
EOF
}

version() {
    echo "go-hw-machine-id.sh v${VERSION}"
}

# Add option parsing to the actual script
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
    version
    exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Error: need root to run ..."
    exit 1
fi

LOG_FILE="/var/log/go-hw-id-encoder.log"
SERIAL_DEVICE="/dev/ttyAMA0"
DEVICE_INFO_DIR="/home/.device-info"
SERIAL_FILE="${DEVICE_INFO_DIR}/serial"
PRODUCT_FILE="${DEVICE_INFO_DIR}/productid"
FIRMWARE_FILE="${DEVICE_INFO_DIR}/firmware"
REVISION_FILE="${DEVICE_INFO_DIR}/revision"
MODEL_FILE="${DEVICE_INFO_DIR}/model"
TIMEOUT=2

log() {
    echo "$(date -Iseconds): $1" | tee -a "$LOG_FILE"
}

cleanup() {
    if [ -e /proc/$$/fd/3 ]; then
        exec 3<&-
    fi
    exit "${1:-0}"
}

set_immutable() {
    local file="$1"
    if ! chattr +i "$file" 2>/dev/null; then
        log "WARNING: Could not set $file as immutable (filesystem may not support chattr)"
    else
        log "Set $file as immutable (requires chattr -i to modify in future)"
    fi
}

log "Starting go hardware machine-id encoder ..."

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$DEVICE_INFO_DIR"
chmod 755 "$DEVICE_INFO_DIR"

if [ -s "$SERIAL_FILE" ]; then
    log "Serial number file already exists, using existing serial ..."
    SERIAL_NUMBER=$(base64 -d "$SERIAL_FILE" 2>/dev/null || echo "")

    if [ -z "$SERIAL_NUMBER" ]; then
        log "ERROR: failed to decode existing serial number, will try to read from hardware ..."
    fi
fi

if [ -z "$SERIAL_NUMBER" ]; then
    MAX_ATTEMPTS=5
    CURRENT_ATTEMPT=1
    RETRY_DELAY=2
    SUCCESS=false
    
    log "Beginning serial port read attempts (max $MAX_ATTEMPTS attempts with $RETRY_DELAY second delays) ..."

    while [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ] && [ "$SUCCESS" = "false" ]; do
        log "Attempt $CURRENT_ATTEMPT of $MAX_ATTEMPTS to read from serial port ..."

        if [ ! -c "$SERIAL_DEVICE" ]; then
            log "WARNING: Serial device $SERIAL_DEVICE not found on attempt $CURRENT_ATTEMPT ..."
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Serial device $SERIAL_DEVICE not found after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        log "Reading serial number from $SERIAL_DEVICE ..."

        if ! stty -F "$SERIAL_DEVICE" 115200 -icrnl -ixon -ixoff -opost -isig -icanon -echo 2>/dev/null; then
            log "WARNING: Failed to configure serial port $SERIAL_DEVICE on attempt $CURRENT_ATTEMPT"
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Failed to configure serial port after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        log "Opening serial device for reading ..."

        if ! exec 3< "$SERIAL_DEVICE"; then
            log "WARNING: Failed to open serial device for reading on attempt $CURRENT_ATTEMPT"
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Failed to open serial device after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        line=""
        if ! line=$(timeout "$TIMEOUT" cat <&3 | grep -v "^$" | head -n 1); then
            log "WARNING: Failed to read from serial device on attempt $CURRENT_ATTEMPT"
            exec 3<&-  
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Failed to read from serial device after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        if [ -z "$line" ]; then
            log "WARNING: No data received from serial port on attempt $CURRENT_ATTEMPT ..."
            exec 3<&-  
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: No data received from serial port after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        # Field names document the device serial CSV protocol. `serial` is
        # the 13th field, so every field must be consumed even when unused.
        # shellcheck disable=SC2034
        IFS=',' read -r product version candidate hardware error tested rfuA rfuB timeSinceStart usbVoltage rfuC vBatt serial <<< "$line"
        if [[ -n "$product" ]]; then
            serial=$(echo "$serial" | tr -d '\r\n')
            log "Parsed device data: product=$product, version=$version, serial=$serial"
            SUCCESS=true
        else
            log "WARNING: Failed to parse product ID from data on attempt $CURRENT_ATTEMPT ..."
            exec 3<&-  
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Failed to parse product ID after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        SERIAL_NUMBER=$serial
        PRODUCT_ID=$product
        FIRMWARE=$candidate
        REVISION=$hardware

        if [ -z "$SERIAL_NUMBER" ]; then
            log "WARNING: Failed to extract serial number from data on attempt $CURRENT_ATTEMPT ..."
            exec 3<&- 
            CURRENT_ATTEMPT=$((CURRENT_ATTEMPT+1))
            
            if [ $CURRENT_ATTEMPT -le $MAX_ATTEMPTS ]; then
                log "Waiting $RETRY_DELAY seconds before retry ..."
                sleep $RETRY_DELAY
                continue
            else
                log "ERROR: Failed to extract serial number after $MAX_ATTEMPTS attempts ..."
                log "Will generate a random machine-id instead ..."
                systemd-machine-id-setup
                cleanup 1
            fi
        fi

        log "Successfully read serial number on attempt $CURRENT_ATTEMPT!"
        break
    done

    if [ -e /proc/$$/fd/3 ]; then
        exec 3<&-
    fi

    if [ "$SUCCESS" = "false" ]; then
        log "ERROR: Failed to read serial number after $MAX_ATTEMPTS attempts ..."
        log "Will generate a random machine-id instead ..."
        systemd-machine-id-setup
        cleanup 1
    fi

    log "Extracted serial number: $SERIAL_NUMBER ..."
    echo -n "$SERIAL_NUMBER" | base64 > "$SERIAL_FILE"
    chmod 644 "$SERIAL_FILE"
    set_immutable "$SERIAL_FILE"
    log "Saved base64 encoded serial to $SERIAL_FILE ..."

    log "Extracted product id: $PRODUCT_ID ..."
    echo -n "$PRODUCT_ID" > "$PRODUCT_FILE"
    chmod 644 "$PRODUCT_FILE"
    set_immutable "$PRODUCT_FILE"
    log "Saved product id to $PRODUCT_FILE ..."

    if [ "$PRODUCT_ID" = "14" ]; then
        echo "Go" > "$MODEL_FILE"
        chmod 644 "$MODEL_FILE"
        set_immutable "$MODEL_FILE"
        log "Device identified as Go model, information saved to $MODEL_FILE ..."
    fi

    log "Extracted firmware: $FIRMWARE ..."
    echo -n "$FIRMWARE" > "$FIRMWARE_FILE"
    chmod 644 "$FIRMWARE_FILE"
    set_immutable "$FIRMWARE_FILE"
    log "Saved firmware version to $FIRMWARE_FILE ..."
    
    log "Extracted hardware revision: $REVISION ..."
    echo -n "$REVISION" > "$REVISION_FILE"
    chmod 644 "$REVISION_FILE"
    set_immutable "$REVISION_FILE"
    log "Saved hardware revision to $REVISION_FILE ..."
fi

MACHINE_ID=$(echo -n "$SERIAL_NUMBER" | sha256sum | cut -c 1-32)
log "Generated machine-id: $MACHINE_ID ..."

if [ -n "$MACHINE_ID" ]; then
    if [ -s "/etc/machine-id" ]; then
        CURRENT_ID=$(cat /etc/machine-id)
        if [ "$CURRENT_ID" = "$MACHINE_ID" ]; then
            log "Machine ID already set correctly, no changes needed ..."
            cleanup 0
        fi
    fi

    echo "$MACHINE_ID" > /etc/machine-id
    chmod 444 /etc/machine-id
    log "Setting machine-id as immutable (requires chattr -i to modify in future) ..."
    set_immutable "/etc/machine-id"
    log "Written machine-id to /etc/machine-id ..."
    cleanup 0
else
    log "ERROR: Failed to generate valid machine-id ..."
    log "Will generate a random machine-id instead ..."
    systemd-machine-id-setup
    cleanup 1
fi
