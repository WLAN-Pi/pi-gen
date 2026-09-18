#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/wlanpi-firstboot.log"
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
exec > >(tee -a "$LOGFILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting first boot configuration"

log "Setting Wi-Fi country to US"
if raspi-config nonint do_wifi_country US; then
    log "Wi-Fi country set successfully"
else
    log "WARNING: failed to set country code"
fi

if echo '#!/bin/sh
echo "Welcome to WLAN Pi OS. This device is intended for educational, laboratory, and non-commercial testing purposes. WLAN Pi provides ABSOLUTELY NO WARRANTY. You are solely responsible for complying with applicable laws and regulations."' > /etc/update-motd.d/20-wlanpi-legal && chmod +x /etc/update-motd.d/20-wlanpi-legal; then
    log "Legal notice MOTD created successfully"
else
    log "ERROR: Failed to create MOTD"
    exit 1
fi

log "Checking for ufw"
if ! command -v ufw >/dev/null 2>&1; then
    log "WARNING: ufw not found, skipping firewall configuration"
    exit 0
fi

log "Configuring firewall rules"

ufw allow 22/tcp
log "Added SSH (port 22/tcp)"

ufw allow 67/udp
log "Added DHCP server (port 67/udp)"

ufw allow 36872/udp
log "Added ephemeral/avahi-related (port 36872/udp)"

ufw allow proto udp from 224.0.0.0/4 to any port 5353
log "Added mDNS IPv4 multicast rule"

ufw allow proto udp from fe80::/10 to any port 5353
log "Added mDNS IPv6 link-local rule"

ufw allow 3264/tcp
ufw allow 3264/udp
log "Added oscium-spectrum ports (3264/tcp 3264/udp)"

ufw allow 6174/tcp
ufw allow 6174/udp
log "Added oscium-capture ports (6174/tcp 6174/udp)"

log "Setting firewall defaults"
ufw default deny incoming
ufw default allow outgoing
log "Firewall defaults set (deny incoming, allow outgoing)"

# log "Enabling firewall logging"
# ufw logging on

log "Enabling firewall"
ufw --force enable
log "Firewall enabled successfully"

log "First boot configuration completed"
exit 0
