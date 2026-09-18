#!/bin/bash -e

# Setup first boot script
echo "Copying first-boot.sh ..."
copy_overlay /usr/bin/first-boot.sh -o root -g root -m 755

echo "Copying wlanpi-first-boot service file ..."
copy_overlay /lib/systemd/system/wlanpi-first-boot.service -o root -g root -m 644

echo "Enabling wlanpi-first-boot service ..."
on_chroot <<CHEOF
	systemctl enable wlanpi-first-boot
CHEOF


