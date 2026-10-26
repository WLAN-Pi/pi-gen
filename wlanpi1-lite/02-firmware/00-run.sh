#!/bin/bash -e

install -d "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d"
install -m 644 files/99-wlanpi-be200-firmware "${ROOTFS_DIR}/etc/dpkg/dpkg.cfg.d/99-wlanpi-be200-firmware"
