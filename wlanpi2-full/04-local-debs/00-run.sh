#!/bin/bash -e

LOCAL_DEBS_DIR="${BASE_DIR}/local-debs"

if [ ! -d "${LOCAL_DEBS_DIR}" ]; then
	exit 0
fi

shopt -s nullglob
debs=("${LOCAL_DEBS_DIR}"/*.deb)
shopt -u nullglob

if [ ${#debs[@]} -eq 0 ]; then
	exit 0
fi

for deb in "${debs[@]}"; do
	log "Staging local deb: $(basename "$deb")"
	install -m 644 "$deb" "${ROOTFS_DIR}/tmp/"
done

on_chroot <<- 'EOF'
	for deb in /tmp/*.deb; do
		[ -f "$deb" ] || continue
		echo "Installing local deb: $(basename "$deb")"
		apt-get install -y --reinstall --allow-downgrades "$deb"
		rm -f "$deb"
	done
EOF
