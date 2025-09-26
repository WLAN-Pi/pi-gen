#!/bin/bash -e

on_chroot <<CHEOF
	# Add Kismet repository
	wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | apt-key add -
	echo 'deb https://www.kismetwireless.net/repos/apt/release/bullseye bullseye main' | tee /etc/apt/sources.list.d/kismet.list
	
	# Add packagecloud wlanpi/main repository
	curl -s https://packagecloud.io/install/repositories/wlanpi/main/script.deb.sh | bash

	# Packagecloud wlanpi/dev repository
 	# curl -s https://packagecloud.io/install/repositories/wlanpi/dev/script.deb.sh | bash

	# Add Bullseye Backports repository
	echo 'deb http://archive.debian.org/debian bullseye-backports main' | tee /etc/apt/sources.list.d/bullseye-backports.list
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138

	# Add Grafana repository
	if [ ! -f /etc/apt/sources.list.d/grafana.list ]; then
		echo "Adding grafana repository"
		mkdir -p /etc/apt/keyrings/
		wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
		echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
	fi

	# Add InfluxData repository (influxdb, influxdb2, telegraf, chronograf)
	if [ ! -f /etc/apt/sources.list.d/influxdb.list ]; then
		echo "Adding InfluxData repository"
		curl https://repos.influxdata.com/influxdata-archive.key | gpg --dearmor | sudo tee /usr/share/keyrings/influxdb-archive-keyring.gpg >/dev/null
		echo "deb [signed-by=/usr/share/keyrings/influxdb-archive-keyring.gpg] https://repos.influxdata.com/debian $(grep "VERSION_CODENAME=" /etc/os-release |awk -F= {'print $2'} | sed s/\"//g) stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
	fi

	echo "Running apt update"
	apt update

	# Install flent with basic tools
	apt install -y netperf fping irtt
	apt install -y --no-install-recommends flent
CHEOF
