#!/bin/bash -e

# Install systemd service overrides
install -v -d "${ROOTFS_DIR}/etc/systemd/system/irtt.service.d"
install -v -m 644 files/etc/systemd/system/irtt.service.d/override.conf "${ROOTFS_DIR}/etc/systemd/system/irtt.service.d/override.conf"

install -v -d "${ROOTFS_DIR}/etc/systemd/system/tftpd-hpa.service.d"
install -v -m 644 files/etc/systemd/system/tftpd-hpa.service.d/override.conf "${ROOTFS_DIR}/etc/systemd/system/tftpd-hpa.service.d/override.conf"

# Install tftpd-hpa config with correct bind address (fixes boot-time DNS resolution issue)
install -v -d "${ROOTFS_DIR}/etc/default"
install -v -m 644 files/etc/default/tftpd-hpa "${ROOTFS_DIR}/etc/default/tftpd-hpa"

on_chroot << EOF
echo "=== Adding Kismet repository ==="
# Add Kismet repository for trixie (using official installation method)
wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key --quiet | gpg --dearmor | tee /usr/share/keyrings/kismet-archive-keyring.gpg >/dev/null
echo 'deb [arch=arm64 signed-by=/usr/share/keyrings/kismet-archive-keyring.gpg] https://www.kismetwireless.net/repos/apt/release/trixie trixie main' | tee /etc/apt/sources.list.d/kismet.list >/dev/null
apt update
echo "=== Kismet repository added ==="

echo "=== Installing Kismet ==="
apt install -y kismet
echo "=== Kismet installed ==="

echo "=== tshark install ==="
# Set tshark/wireshark preseed
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

# Install tshark
apt install -y tshark 
echo "=== tshark done ==="

echo "=== netperf, fping, irtt install ==="
apt install -y netperf fping irtt
apt install -y --no-install-recommends flent
echo "=== netperf, fping, irtt done ==="

echo "=== Configuring irtt to use wlanpi user ==="
# Override irtt.service to use wlanpi user instead of nobody
# This fixes systemd warning: "Special user nobody configured, this is not safe!"
# The override file is installed from files/etc/systemd/system/irtt.service.d/override.conf
systemctl daemon-reload
echo "=== irtt configuration done ==="

echo "=== Configuring tftpd-hpa network timing ==="
# Override tftpd-hpa.service to wait for network-online.target
# This prevents service startup failures when network is not ready
# The override file is installed from files/etc/systemd/system/tftpd-hpa.service.d/override.conf
systemctl daemon-reload
echo "=== tftpd-hpa configuration done ==="
EOF
