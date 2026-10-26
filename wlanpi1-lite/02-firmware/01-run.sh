#!/bin/bash -e

firmware_roots=()
seen_ids=" "
for candidate in "${ROOTFS_DIR}/lib/firmware" "${ROOTFS_DIR}/usr/lib/firmware"; do
	if [ -d "${candidate}" ]; then
		id="$(stat -c '%d:%i' "${candidate}")"
		case "${seen_ids}" in
			*" ${id} "*) ;;
			*)
				firmware_roots+=("${candidate}")
				seen_ids="${seen_ids}${id} "
				;;
		esac
	fi
done

if [ "${#firmware_roots[@]}" -eq 0 ]; then
	echo "error: BE200 firmware check found no firmware directory" >&2
	exit 1
fi

ucode_count="$(find "${firmware_roots[@]}" -maxdepth 1 -type f -name 'iwlwifi-gl-c0-fm-c0-*.ucode' | wc -l)"
ucode_count="${ucode_count// /}"
if [ "${ucode_count}" -lt 1 ]; then
	echo "error: BE200 firmware check found no iwlwifi-gl-c0-fm-c0-*.ucode file" >&2
	exit 1
fi

stray="$(find "${firmware_roots[@]}" \( -name 'iwlwifi-*' -o -name 'ibt-*' \) ! -name 'iwlwifi-gl-c0-fm-c0-*' ! -name 'iwlwifi-gl-c0-fm-c0.pnvm' -print)"
if [ -n "${stray}" ]; then
	echo "error: BE200 firmware check found Intel firmware outside iwlwifi-gl-c0-fm-c0-* and iwlwifi-gl-c0-fm-c0.pnvm" >&2
	printf '%s\n' "${stray}" >&2
	exit 1
fi

if [ ! -f "${ROOTFS_DIR}/etc/modprobe.d/iwlwifi.conf" ]; then
	echo "error: BE200 firmware check did not find /etc/modprobe.d/iwlwifi.conf" >&2
	exit 1
fi
