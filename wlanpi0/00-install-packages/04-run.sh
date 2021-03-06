#!/bin/bash -e

on_chroot <<CHEOF
	# Add Kismet repository
	wget -O - https://www.kismetwireless.net/repos/kismet-release.gpg.key | apt-key add -
	echo 'deb https://www.kismetwireless.net/repos/apt/release/buster buster main' | tee /etc/apt/sources.list.d/kismet.list
	
	# Add our own custom repository
	echo "deb [trusted=yes] https://apt.fury.io/dfinimundi /" | tee /etc/apt/sources.list.d/wlanpi.list

	apt-get update
CHEOF
