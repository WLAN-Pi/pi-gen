#!/bin/bash -e

echo "${TIMEZONE_DEFAULT}" > "${ROOTFS_DIR}/etc/timezone"
rm "${ROOTFS_DIR}/etc/localtime"
install -v -D -m 644 files/50-wlanpi-save-interval.conf "${ROOTFS_DIR}/etc/systemd/timesyncd.conf.d/50-wlanpi-save-interval.conf"

on_chroot << EOF
dpkg-reconfigure -f noninteractive tzdata
EOF
