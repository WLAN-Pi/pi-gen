#!/bin/bash -e

install -v -m 755 files/boot-info "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/commit-current-partition "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/tryboot-alternate "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/update-alternate-partition "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/generate-go-fstab "${ROOTFS_DIR}/usr/local/sbin/"
