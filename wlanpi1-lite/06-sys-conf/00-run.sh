#!/bin/bash -e

on_chroot <<CHEOF
# disable and mask NM
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl mask NetworkManager

# enable systemd-networkd
systemctl enable systemd-networkd.service
systemctl start systemd-networkd.service
CHEOF

