#!/bin/bash -e

fw="${ROOTFS_DIR}/lib/firmware"

if [ -z "$(find "${fw}" -maxdepth 1 -name 'iwlwifi-gl-c0-fm-c0-*.ucode' -print -quit)" ]; then
	echo "error: no iwlwifi-gl-c0-fm-c0-*.ucode in ${fw}" >&2
	exit 1
fi

stray="$(find "${fw}" \( -name 'iwlwifi-*' -o -name 'ibt-*' \) ! -name 'iwlwifi-gl-c0-fm-c0-*' ! -name 'iwlwifi-gl-c0-fm-c0.pnvm')"
if [ -n "${stray}" ]; then
	echo "error: Intel firmware outside the BE200 set in ${fw}:" >&2
	echo "${stray}" >&2
	exit 1
fi
