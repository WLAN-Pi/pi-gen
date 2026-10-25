#!/bin/bash -e

rm -f "${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache"
find "${ROOTFS_DIR}/var/lib/apt/lists/" -type f -delete
on_chroot << EOF
apt-get update
apt-get -y dist-upgrade --auto-remove --purge
apt-get clean
EOF
# The update above exists so dist-upgrade sees current indexes. Do not ship them.
find "${ROOTFS_DIR}/var/lib/apt/lists/" -type f -delete
