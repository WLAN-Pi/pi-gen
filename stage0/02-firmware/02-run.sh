#!/bin/bash -e

install -m 644 files/wlanpi-kernel*.deb "${ROOTFS_DIR}/tmp/"

# Install customized kernel for Go
on_chroot << EOF
apt-get -y install /tmp/wlanpi-kernel*.deb
EOF
rm -f "${ROOTFS_DIR}/tmp/wlanpi-kernel*"
