#!/bin/bash -e

####################
# General services
####################

# Setup service: iperf3
copy_overlay /lib/systemd/system/iperf3.service -o root -g root -m 644

# Setup service: iperf2
copy_overlay /lib/systemd/system/iperf2.service -o root -g root -m 644
copy_overlay /lib/systemd/system/iperf2-udp.service -o root -g root -m 644

# ser2net comes in as a dependency of the mode packages (wlanpi-server,
# wlanpi-hotspot) and is only needed after switching into those modes;
# the mode switchers start it. Do not run it by default, and cap its
# stop timeout so it can never extend shutdown (issue #102).
copy_overlay /etc/systemd/system/ser2net.service.d/override.conf -o root -g root -m 644

on_chroot <<CHEOF
	systemctl enable iperf3
	systemctl enable cockpit.socket
	systemctl disable ser2net || true
	systemctl stop ser2net 2>/dev/null || true
CHEOF
