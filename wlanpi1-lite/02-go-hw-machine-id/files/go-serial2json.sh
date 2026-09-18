#!/bin/bash

# go-serial2json.sh - Serial data to JSON converter for the Go
#
# Author: Josh Schmelzle
# License: BSD-3

VERSION="1.0.0"
PORT="/dev/ttyAMA0"
TIMEOUT=2
SHOW_VERSION=false

cleanup() {
    if [ -e /proc/$$/fd/3 ]; then
        exec 3<&-
    fi
    exit "${1:-0}"
}

trap 'echo "Received interrupt signal, exiting ..." >&2; cleanup 1' INT TERM HUP

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -v|--version)
            SHOW_VERSION=true;
            shift
            ;;
        -h|--help)
            echo "WLAN Pi Go serial to JSON converter v$VERSION"
            echo "Usage: $0 [-o|--oneshot] [-p|--port PORT] [-v|--version]"
            echo "  -p, --port PORT   Specify serial port to use (default: ""$PORT"")"
            echo "  -v, --version     Show version information"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-o|--oneshot] [-p|--port PORT] [-v|--version]"
            exit 1
            ;;
    esac
done

if $SHOW_VERSION; then
    echo "v$VERSION"
    exit 0
fi

if [ ! -e "$PORT" ]; then
    echo "Error: Serial port ""$PORT"" does not exist" >&2
    echo "Available serial ports:" >&2
    find /dev -type c -name "ttyS*" -o -name "ttyUSB*" -o -name "ttyACM*" -o -name "ttyAMA*" | sort >&2
    exit 1
fi

if [ ! -r "$PORT" ] || [ ! -w "$PORT" ]; then
    echo "Error: No permission to access $PORT" >&2
    echo "Try running with sudo or add your user to the dialout group:" >&2
    echo "sudo usermod -a -G dialout $USER" >&2
    exit 1
fi

if ! stty -F "$PORT" 115200 -icrnl -ixon -ixoff -opost -isig -icanon -echo 2>/dev/null; then
    echo "Error: Failed to configure serial port $PORT" >&2
    cleanup 1
fi

read_with_timeout() {
    local fd="$1"
    local timeout="$2"

    if read -t "$timeout" -r line <&"$fd"; then
        echo "$line"
        return 0
    else
        return 1
    fi
}

exec 3<"$PORT" || { echo "Error: Failed to open $PORT" >&2; cleanup 1; }

if ! line=$(read_with_timeout 3 "$TIMEOUT"); then
    echo "Error: timed out waiting for data from $PORT" >&2
        cleanup 1
fi

IFS=',' read -r product version candidate hardware error tested rfuA rfuB timeSinceStart usbVoltage rfuC vBatt serial <<< "$line"
if [[ -n "$product" ]]; then
    serial=$(echo "$serial" | tr -d '\r\n')
    echo "{\"product\":$product,\"version\":$version,\"candidate\":$candidate,\"hardware\":$hardware,\"error\":$error,\"tested\":$tested,\"rfuA\":$rfuA,\"rfuB\":$rfuB,\"timeSinceStart\":$timeSinceStart,\"usbVoltage\":$usbVoltage,\"rfuC\":$rfuC,\"vBatt\":$vBatt,\"serial\":\"$serial\"}"
fi

cleanup 0