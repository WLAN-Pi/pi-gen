#!/bin/bash -e

# Ensure curl is installed in the chroot environment
on_chroot <<CHEOF
	echo "Installing curl"
	apt update
	apt install -y curl
CHEOF

# Add the Grafana repository. It provides the grafana package that
# wlanpi-grafana depends on. apt accepts the ASCII-armored key directly
# as signed-by (apt >= 2.4, trixie ships 3.x).
on_chroot <<CHEOF
	echo "Add Grafana repository"
	install -d -m 755 /etc/apt/keyrings
	curl -fsSL https://apt.grafana.com/gpg-full.key -o /etc/apt/keyrings/grafana.asc
	chmod 644 /etc/apt/keyrings/grafana.asc
	echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main' > /etc/apt/sources.list.d/grafana.list

	echo "Running apt update"
	apt update
CHEOF
