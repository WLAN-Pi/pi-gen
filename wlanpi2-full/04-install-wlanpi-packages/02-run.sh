#!/bin/bash -e

on_chroot <<CHEOF
	for package in wlanpi-grafana grafana; do
		if dpkg-query -W "\$package" >/dev/null 2>&1; then
			apt-get purge -y "\$package"
		fi
	done
	rm -rf /etc/grafana /var/lib/grafana /var/log/grafana
	rm -f /etc/apt/sources.list.d/grafana.list /etc/apt/keyrings/grafana.asc
CHEOF
