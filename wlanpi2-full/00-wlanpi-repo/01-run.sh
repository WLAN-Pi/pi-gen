#!/bin/bash -e

# Ensure curl is installed in the chroot environment
on_chroot <<CHEOF
	echo "Installing curl"
	apt update
	apt install -y curl
CHEOF

# Add the repositories
on_chroot <<CHEOF
	echo "Add packagecloud wlanpi/main repository"
	curl -s https://packagecloud.io/install/repositories/wlanpi/main/script.deb.sh | os=debian dist=${RELEASE} bash

	if [ "${INCLUDE_PACKAGECLOUD_DEV}" = "1" ]; then
		echo "Add packagecloud wlanpi/dev repository"
		curl -s https://packagecloud.io/install/repositories/wlanpi/dev/script.deb.sh | os=debian dist=${RELEASE} bash
	else
		echo "Skipping add packagecloud wlanpi/dev repository - see GitHub Actions workflow inputs"
	fi

	echo "Running apt update"
	apt update
CHEOF
