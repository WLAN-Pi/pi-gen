#!/bin/bash -e

on_chroot << EOF
echo "=== tshark install ==="

echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

DEBIAN_FRONTEND=noninteractive apt install -y tshark

if command -v setcap >/dev/null 2>&1; then
  setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap || \
  echo "Setting capabilities failed, using setuid as fallback"
fi

if [ ! -u /usr/bin/dumpcap ]; then
  chmod u+s /usr/bin/dumpcap
fi

echo "=== tshark done ==="
EOF
