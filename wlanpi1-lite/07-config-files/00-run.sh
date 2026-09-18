#!/bin/bash -e

# Resolve the latest wireless-regdb from the Debian pool at build time;
# a pinned filename 404s whenever the pool rotates to a new version
REGDB_POOL="https://deb.debian.org/debian/pool/main/w/wireless-regdb/"
REGDB_DEB="$(curl -s "${REGDB_POOL}" | grep -oE 'wireless-regdb_[0-9.]+-[0-9]+_all\.deb' | sort -uV | tail -n1)"
if [ -z "${REGDB_DEB}" ]; then
	echo "ERROR: could not determine latest wireless-regdb from ${REGDB_POOL}"
	exit 1
fi
echo "Using wireless-regdb: ${REGDB_DEB}"

on_chroot <<CHEOF
	# Set retry for dhclient
	if grep -q -E "^#?retry " /etc/dhcp/dhclient.conf; then
		sed -i 's/^#\?retry .*/retry 600;/' /etc/dhcp/dhclient.conf
	else
		echo "retry 600;" >> /etc/dhcp/dhclient.conf
	fi

	if grep -A6 "^[[:space:]]*request" /etc/dhcp/dhclient.conf | grep -q "rfc3442-classless-static-routes" && ! grep -q "#.*rfc3442-classless-static-routes" /etc/dhcp/dhclient.conf; then
		sed -i '
		/^[[:space:]]*request/{
			:a
			N
			/;$/!ba
			s/,[[:space:]]*rfc3442-classless-static-routes//
			s/;$/;\n        # rfc3442-classless-static-routes/
		}' /etc/dhcp/dhclient.conf
	fi

	# Send hardware MAC address to DHCP server
	if grep -q -E "^#?send dhcp-client-identifier " /etc/dhcp/dhclient.conf; then
		sed -i 's/^#\?send dhcp-client-identifier .*/send dhcp-client-identifier = hardware;/' /etc/dhcp/dhclient.conf
	else
		echo "send dhcp-client-identifier = hardware;" >> /etc/dhcp/dhclient.conf
	fi

	# Change default systemd boot target from graphical.target to multi-user.target
	systemctl set-default multi-user.target

	# Configure arp_ignore: network/arp
	echo "net.ipv4.conf.eth0.arp_ignore = 1" >> /etc/sysctl.conf

	# Fetch current version of the pci. ids file
	update-pciids

	# Install wireless-regdb
	wget -O /tmp/wireless-regdb.deb ${REGDB_POOL}${REGDB_DEB}
	dpkg -i /tmp/wireless-regdb.deb
	rm -f /tmp/wireless-regdb.deb
	update-alternatives --set regulatory.db /lib/firmware/regulatory.db-upstream

	# Automatically reboot after 5 seconds if a kernel panic occurs
	echo "kernel.panic = 5" >> /etc/sysctl.conf
CHEOF

cat > "${ROOTFS_DIR}/tmp/update-wlanpi-release.sh" << EOF
#!/bin/bash
echo "Debug: WLANPI_VERSION=\${WLANPI_VERSION}"

echo "=== Setting WLAN Pi version information ==="
echo "VERSION=${WLANPI_VERSION}" > /etc/wlanpi-release
chmod 644 /etc/wlanpi-release 

echo "=== /etc/os-release update complete ==="
EOF

chmod +x "${ROOTFS_DIR}/tmp/update-wlanpi-release.sh"

on_chroot << EOF
WLANPI_VERSION="${WLANPI_VERSION}" \
/tmp/update-wlanpi-release.sh 
EOF

rm -f "${ROOTFS_DIR}/tmp/update-wlanpi-release.sh"

# Add our custom sudoers file
copy_overlay /etc/sudoers.d/wlanpidump -o root -g root -m 440

# Copy config file: avahi-daemon
copy_overlay /etc/avahi/avahi-daemon.conf -o root -g root -m 644

# Copy config file: wlanpi-state (WLAN Pi Mode)
copy_overlay /etc/wlanpi-state -o root -g root -m 644

# Make /dev/vcio accessible to the video group (not covered by raspberrypi-sys-mods 10-vc.rules)
copy_overlay /etc/udev/rules.d/99-vcio.rules -o root -g root -m 644
