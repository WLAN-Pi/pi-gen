#!/bin/bash -e

install -v -m 644 files/fstab "${ROOTFS_DIR}/etc/fstab"

# Load i2c-dev at boot: provides /dev/i2c-1 used by wlanpi-model to detect
# the M4+ Mcuzone EEPROM at 0x50 via i2cdetect (was /etc/modules on bookworm)
echo "i2c-dev" > "${ROOTFS_DIR}/etc/modules-load.d/i2c-dev.conf"

on_chroot << EOF
if ! id -u ${FIRST_USER_NAME} >/dev/null 2>&1; then
	adduser --disabled-password --gecos "" ${FIRST_USER_NAME}
fi

if [ -n "${FIRST_USER_PASS}" ]; then
	echo "${FIRST_USER_NAME}:${FIRST_USER_PASS}" | chpasswd
fi
echo "root:root" | chpasswd
EOF

