#!/bin/bash -e

on_chroot << EOF
echo "=== removing wlanpi-stats from profile.d ==="
rm -f /etc/profile.d/wlanpi-stats.sh
echo "=== finish removing wlanpi-stats from profile.d ==="
EOF
