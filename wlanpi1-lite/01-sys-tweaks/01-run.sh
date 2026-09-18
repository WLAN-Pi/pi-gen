#!/bin/bash -e

install -m 755 files/resize2fs_once	"${ROOTFS_DIR}/etc/init.d/"

install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"

install -m 644 files/console-setup   	"${ROOTFS_DIR}/etc/default/"

on_chroot << EOF
systemctl disable hwclock.sh || true
systemctl disable nfs-common || true
systemctl disable rpcbind || true
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
systemctl unmask regenerate_ssh_host_keys || true
systemctl enable regenerate_ssh_host_keys || true
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
systemctl disable resize2fs_once
EOF
	echo "leaving QEMU mode"
else
	on_chroot << EOF
systemctl enable resize2fs_once
EOF
fi

on_chroot <<EOF
for GRP in input spi i2c gpio netdev; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev render; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

if [ -f "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd" ]; then
  sed -i "s/^pi /$FIRST_USER_NAME /" "${ROOTFS_DIR}/etc/sudoers.d/010_pi-nopasswd"
fi

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*

# Regenerate the deleted host keys on any boot where they are missing, not
# just ConditionFirstBoot (see comment in the drop-in)
install -d "${ROOTFS_DIR}/etc/systemd/system/sshd-keygen.service.d"
install -m 644 files/sshd-keygen-anyboot.conf "${ROOTFS_DIR}/etc/systemd/system/sshd-keygen.service.d/"

sed -i "s/PLACEHOLDER//" "${ROOTFS_DIR}/etc/default/keyboard"
on_chroot << EOF
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration
EOF

sed -i "s/^#Storage=.*/Storage=volatile/" "${ROOTFS_DIR}/etc/systemd/journald.conf"
sed -i "s/^#RuntimeMaxUse=.*/RuntimeMaxUse=50M/" "${ROOTFS_DIR}/etc/systemd/journald.conf"
