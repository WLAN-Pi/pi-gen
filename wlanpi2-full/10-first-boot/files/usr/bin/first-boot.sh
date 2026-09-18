#!/bin/bash
set -euo pipefail

LOGFILE="/var/log/wlanpi-firstboot.log"
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true
exec > >(tee -a "$LOGFILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting first boot configuration"

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

log "Configuring firewall defaults and enabling"
ufw default deny incoming
ufw default allow outgoing
ufw --force enable
log "Firewall enabled successfully (rules configured via /etc/ufw/user.rules)"

log "First boot configuration completed"
exit 0
