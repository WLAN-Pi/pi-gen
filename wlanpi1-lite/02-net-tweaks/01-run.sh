#!/bin/bash -e

if [ -v WPA_COUNTRY ]; then
	on_chroot <<- EOF
		SUDO_USER="${FIRST_USER_NAME}" raspi-config nonint do_wifi_country "${WPA_COUNTRY}"
	EOF
elif [ -d "${ROOTFS_DIR}/var/lib/NetworkManager" ]; then
	# NetworkManager unblocks all WLAN devices by default. Prevent that:
	cat > "${ROOTFS_DIR}/var/lib/NetworkManager/NetworkManager.state" <<- EOF
		[main]
		WirelessEnabled=false
	EOF
fi

on_chroot << EOF
systemctl disable systemd-networkd-wait-online
systemctl mask systemd-networkd-wait-online
systemctl disable NetworkManager-wait-online.service
systemctl mask NetworkManager-wait-online.service
EOF