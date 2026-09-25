#!/bin/bash -e

####################
# General services
####################

# ser2net comes in as a dependency of the mode packages (wlanpi-server,
# wlanpi-hotspot) and is only needed after switching into those modes;
# the mode switchers start it. Do not run it by default, and cap its
# stop timeout so it can never extend shutdown (issue #102).
copy_overlay /etc/systemd/system/ser2net.service.d/override.conf -o root -g root -m 644

on_chroot <<CHEOF
	# The iperf package ships its units disabled; iperf3 enables its own.
	systemctl enable iperf2 iperf2-ufw
	systemctl enable cockpit.socket
	systemctl disable ser2net || true
	systemctl stop ser2net 2>/dev/null || true
	# isc-dhcp-server comes in as a dependency of the mode packages
	# (wlanpi-server, wlanpi-hotspot) and fails at boot in classic mode with
	# "no subnet declaration". The mode switchers enable it when needed.
	systemctl disable isc-dhcp-server || true
CHEOF
