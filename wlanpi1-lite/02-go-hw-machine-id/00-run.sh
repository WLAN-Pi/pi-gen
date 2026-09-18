#!/bin/bash -e

install -v -d "${ROOTFS_DIR}/usr/local/sbin"

install -v -m 755 files/go-hw-machine-id.sh "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/go-serial2json.sh "${ROOTFS_DIR}/usr/local/sbin/"
install -v -m 755 files/go-device-info-decoder.sh "${ROOTFS_DIR}/usr/local/sbin/"

install -v -m 644 files/wlanpi-go-hw-machine-id.service "${ROOTFS_DIR}/etc/systemd/system/"

on_chroot << EOF
# Force machine-id empty to trigger systemd first-boot behavior
echo -n > /etc/machine-id
chmod 444 /etc/machine-id

# Create first-boot marker
mkdir -p /run/systemd
touch /run/systemd/first-boot

# Debugging?
# sudo systemctl daemon-reload
# sudo systemd-analyze condition ConditionFirstBoot=yes

# Enable service
systemctl enable wlanpi-go-hw-machine-id.service
EOF