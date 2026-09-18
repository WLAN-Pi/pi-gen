#!/bin/bash -e

# Installs a firstboot service:
# 1. Performs root filesystem resize
# 2. Configures serial console based on available hardware, reboots if console changes
# Install location: wlanpi1-lite/06-sys-conf/02-run.sh

# --- Configure Console and Resize Filesystem on First Boot ---
on_chroot <<'CHEOF'
cat <<'EOF' > /etc/systemd/system/firstboot.service
[Unit]
Description=Configure Console and Resize Filesystem on First Boot
ConditionPathExists=!/etc/.resize_complete
After=systemd-udev-settle.service local-fs.target
Requires=local-fs.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c ' \
    touch /var/log/firstboot.log || { \
        echo "Error: Cannot create log file"; \
        exit 1; \
    }; \
    exec 1>/var/log/firstboot.log 2>&1; \
    set -x; \
    root_dev=$(findmnt -no SOURCE / | grep -v overlay | head -1); \
    if [ -z "$root_dev" ]; then \
        root_dev=$(lsblk -npo KNAME,MOUNTPOINT | grep "/$" | awk "{print \\$1}" | head -1); \
    fi; \
    if [ -z "$root_dev" ] || [ "$root_dev" = "overlay" ]; then \
        echo "Error: Could not detect root device (got: $root_dev)"; \
        exit 1; \
    fi; \
    base_device=$(echo "$root_dev" | sed "s/p[0-9]*$//"); \
    part_num=$(echo "$root_dev" | grep -o "[0-9]*$"); \
    if [ -z "$part_num" ]; then \
        echo "Error: Could not determine partition number"; \
        exit 1; \
    fi; \
    timeout 30 bash -c "parted -s $base_device resizepart $part_num 100% && partprobe $base_device && resize2fs $root_dev"; \
    if [ $? -ne 0 ]; then \
        echo "Error: Resize operation failed or timed out after 30 seconds"; \
        exit 1; \
    fi; \
    sync; \
    touch /etc/.resize_complete; \
    echo "Success: Filesystem resized successfully" \
    '

[Install]
WantedBy=multi-user.target
EOF

systemctl enable firstboot.service
CHEOF
