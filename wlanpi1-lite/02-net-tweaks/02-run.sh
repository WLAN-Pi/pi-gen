#!/bin/bash -e

echo "Copying eth1.network file ..."
copy_overlay /etc/systemd/network/eth1.network -o root -g root -m 644
