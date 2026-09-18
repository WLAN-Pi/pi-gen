#!/bin/bash -e

# shellcheck disable=SC2119
run_sub_stage()
{
	log "Begin ${SUB_STAGE_DIR}"
	pushd "${SUB_STAGE_DIR}" > /dev/null
	for i in {00..99}; do
		if [ -f "${i}-debconf" ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-debconf"
			on_chroot << EOF
debconf-set-selections <<SELEOF
$(cat "${i}-debconf")
SELEOF
EOF

			log "End ${SUB_STAGE_DIR}/${i}-debconf"
		fi
		if [ -f "${i}-packages-nr" ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages-nr"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${i}-packages-nr")"
			if [ -n "$PACKAGES" ]; then
				on_chroot << EOF
apt-get -o Acquire::Retries=3 install --no-install-recommends -y $PACKAGES
EOF
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages-nr"
		fi
		if [ -f "${i}-packages" ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < "${i}-packages")"
			if [ -n "$PACKAGES" ]; then
				on_chroot << EOF
apt-get -o Acquire::Retries=3 install -y $PACKAGES
EOF
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages"
		fi
		if [ -d "${i}-patches" ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-patches"
			pushd "${STAGE_WORK_DIR}" > /dev/null
			if [ "${CLEAN}" = "1" ]; then
				rm -rf .pc
				rm -rf ./*-pc
			fi
			QUILT_PATCHES="${SUB_STAGE_DIR}/${i}-patches"
			SUB_STAGE_QUILT_PATCH_DIR="$(basename "$SUB_STAGE_DIR")-pc"
			mkdir -p "$SUB_STAGE_QUILT_PATCH_DIR"
			ln -snf "$SUB_STAGE_QUILT_PATCH_DIR" .pc
			quilt upgrade
			if [ -e "${SUB_STAGE_DIR}/${i}-patches/EDIT" ]; then
				echo "Dropping into bash to edit patches..."
				bash
			fi
			RC=0
			quilt push -a || RC=$?
			case "$RC" in
				0|2)
					;;
				*)
					false
					;;
			esac
			popd > /dev/null
			log "End ${SUB_STAGE_DIR}/${i}-patches"
		fi
		if [ -x ${i}-run.sh ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run.sh"
			./${i}-run.sh
			log "End ${SUB_STAGE_DIR}/${i}-run.sh"
		elif [ -f ${i}-run.sh ]; then
			log "Skip ${SUB_STAGE_DIR}/${i}-run.sh (not executable)"
		fi
		if [ -f ${i}-run-chroot.sh ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
			on_chroot < ${i}-run-chroot.sh
			log "End ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
		fi
	done
	popd > /dev/null
	log "End ${SUB_STAGE_DIR}"
}


run_stage(){
	log "Begin ${STAGE_DIR}"
	STAGE="$(basename "${STAGE_DIR}")"

	pushd "${STAGE_DIR}" > /dev/null

	STAGE_WORK_DIR="${WORK_DIR}/${STAGE}"
	ROOTFS_DIR="${STAGE_WORK_DIR}"/rootfs

	unmount "${WORK_DIR}/${STAGE}"

	if [ ! -f SKIP_IMAGES ]; then
		if [ -f "${STAGE_DIR}/EXPORT_IMAGE" ]; then
			EXPORT_DIRS="${EXPORT_DIRS} ${STAGE_DIR}"
		fi
	fi
	if [ ! -f SKIP ]; then
		if [ "${CLEAN}" = "1" ]; then
			if [ -d "${ROOTFS_DIR}" ]; then
				rm -rf "${ROOTFS_DIR}"
			fi
		fi
		if [ -x prerun.sh ]; then
			log "Begin ${STAGE_DIR}/prerun.sh"
			./prerun.sh
			log "End ${STAGE_DIR}/prerun.sh"
		fi
		for SUB_STAGE_DIR in "${STAGE_DIR}"/*; do
			if [ -d "${SUB_STAGE_DIR}" ] && [ ! -f "${SUB_STAGE_DIR}/SKIP" ]; then
				run_sub_stage
			fi
		done
	fi

	unmount "${WORK_DIR}/${STAGE}"

	PREV_STAGE="${STAGE}"
	PREV_STAGE_DIR="${STAGE_DIR}"
	PREV_ROOTFS_DIR="${ROOTFS_DIR}"
	popd > /dev/null
	log "End ${STAGE_DIR}"
}

term() {
	if [ "$?" -ne 0 ]; then
		BUILD_FAIL_TIME=$(date +%s)
		BUILD_FAIL_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
		if [ -n "${BUILD_START_TIME}" ]; then
			BUILD_FAIL_DURATION=$((BUILD_FAIL_TIME - BUILD_START_TIME))
			BUILD_FAIL_FORMATTED=$(printf '%02d:%02d:%02d' $((BUILD_FAIL_DURATION/3600)) $((BUILD_FAIL_DURATION%3600/60)) $((BUILD_FAIL_DURATION%60)))
			log "Build failed at: ${BUILD_FAIL_TIMESTAMP} (after ${BUILD_FAIL_FORMATTED})"
			echo ""
			echo "========================================"
			echo "Build FAILED"
			echo "========================================"
			echo "Started:  ${BUILD_START_TIMESTAMP}"
			echo "Failed:   ${BUILD_FAIL_TIMESTAMP}"
			echo "Duration: ${BUILD_FAIL_FORMATTED}"
			echo "========================================"
			echo ""
		else
			log "Build failed"
		fi
	else
		log "Build finished"
	fi
	unmount "${STAGE_WORK_DIR}"
	if [ "$STAGE" = "export-image" ]; then
		for img in "${STAGE_WORK_DIR}/"*.img; do
			unmount_image "$img"
		done
	fi
}

if [ "$(id -u)" != "0" ]; then
	echo "Please run as root" 1>&2
	exit 1
fi

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $BASE_DIR = *" "* ]]; then
	echo "There is a space in the base path of pi-gen"
	echo "This is not a valid setup supported by debootstrap."
	echo "Please remove the spaces, or move pi-gen directory to a base path without spaces" 1>&2
	exit 1
fi

export BASE_DIR

if [ -f config ]; then
	# shellcheck disable=SC1091
	source config
fi

while getopts "c:" flag
do
	case "$flag" in
		c)
			EXTRA_CONFIG="$OPTARG"
			# shellcheck disable=SC1090
			source "$EXTRA_CONFIG"
			;;
		*)
			;;
	esac
done

export PI_GEN=${PI_GEN:-pi-gen}
export PI_GEN_REPO=${PI_GEN_REPO:-https://github.com/WLAN-Pi/pi-gen/}
export PI_GEN_RELEASE=${PI_GEN_RELEASE:-WLAN Pi}

export ARCH=arm64
export RELEASE=${RELEASE:-trixie} # Don't forget to update stage0/prerun.sh
export IMG_NAME="${IMG_NAME:-wlanpi-os-$RELEASE-$ARCH}"

export WLANPI_BASE_VERSION=${WLANPI_BASE_VERSION:-$(date '+%y.%m')}
export WLANPI_VERSION=${WLANPI_VERSION:-$(date '+%y.%m')}
export WLANPI_CODENAME=${WLANPI_CODENAME:-"theanine"}
export WLANPI_FULL_VERSION=${WLANPI_FULL_VERSION:-"${WLANPI_VERSION}-${WLANPI_CODENAME}"}
export IMG_FILENAME="${IMG_NAME}-${WLANPI_FULL_VERSION}"
export ARCHIVE_FILENAME="${ARCHIVE_FILENAME:-${IMG_FILENAME}}"
export WLANPI_HOME_URL="https://wlanpi.com"
export WLANPI_SUPPORT_URL="https://github.com/orgs/WLAN-Pi/discussions"
export WLANPI_BUG_REPORT_URL="https://github.com/WLAN-Pi"
export IMG_DATE="${IMG_DATE:-"$(date +%Y%m%d-%H%M%S)"}"
export INCLUDE_PACKAGECLOUD_DEV=${INCLUDE_PACKAGECLOUD_DEV:-1}
export SKIP_FULL_IMAGE=${SKIP_FULL_IMAGE:-false}

echo "=== BUILD VARS ==="
echo "WLANPI_BASE_VERSION is ${WLANPI_BASE_VERSION}"
echo "WLANPI_VERSION is ${WLANPI_VERSION}"
echo "WLANPI_CODENAME is ${WLANPI_CODENAME}"
echo "WLANPI_FULL_VERSION is ${WLANPI_FULL_VERSION}"
echo "RELEASE is ${RELEASE}"
echo "ARCH is ${ARCH}"
echo "IMG_NAME is ${IMG_NAME}"
echo "IMG_FILENAME is ${IMG_FILENAME}"
echo "ARCHIVE_FILENAME is ${ARCHIVE_FILENAME}"
echo "DEPLOY_COMPRESSION is ${DEPLOY_COMPRESSION}"
echo "COMPRESSION_LEVEL is ${COMPRESSION_LEVEL}"
echo "WORK_DIR is ${WORK_DIR}"
echo "DEPLOY_DIR is ${DEPLOY_DIR}"
echo "APT_PROXY is ${APT_PROXY:-<not set>}"
echo "STAGE_LIST is ${STAGE_LIST}"
echo "SKIP_FULL_IMAGE is ${SKIP_FULL_IMAGE}"
echo "INCLUDE_PACKAGECLOUD_DEV is ${INCLUDE_PACKAGECLOUD_DEV}"
echo "IMG_DATE is ${IMG_DATE}"
echo "WLANPI_HOME_URL is ${WLANPI_HOME_URL}"
echo "WLANPI_SUPPORT_URL is ${WLANPI_SUPPORT_URL}"
echo "WLANPI_BUG_REPORT_URL is ${WLANPI_BUG_REPORT_URL}"
echo "=== /BUILD VARS ==="

# Validation checks
if [ -z "${ARCHIVE_FILENAME}" ]; then
	echo "WARNING: ARCHIVE_FILENAME is empty, output files may have broken names!"
fi

export USE_QEMU="${USE_QEMU:-0}"
export SCRIPT_DIR="${BASE_DIR}/scripts"
export WORK_DIR="${WORK_DIR:-"${BASE_DIR}/work/${IMG_NAME}"}"
export DEPLOY_DIR=${DEPLOY_DIR:-"${BASE_DIR}/deploy"}

echo "Builds are incremental: stage state persists in ${WORK_DIR} and re-runs reuse it."
echo "If a stage edit appears to do nothing, remove ${WORK_DIR} (or use SKIP files) to force a rebuild."

# DEPLOY_ZIP was deprecated in favor of DEPLOY_COMPRESSION
# This preserve the old behavior with DEPLOY_ZIP=0 where no archive was created
if [ -z "${DEPLOY_COMPRESSION}" ] && [ "${DEPLOY_ZIP:-1}" = "0" ]; then
	echo "DEPLOY_ZIP has been deprecated in favor of DEPLOY_COMPRESSION"
	echo "Similar behavior to DEPLOY_ZIP=0 can be obtained with DEPLOY_COMPRESSION=none"
	echo "Please update your config file"
	DEPLOY_COMPRESSION=none
fi
export DEPLOY_COMPRESSION=${DEPLOY_COMPRESSION:-zip}
export COMPRESSION_LEVEL=${COMPRESSION_LEVEL:-6}
export LOG_FILE="${WORK_DIR}/build.log"

export TARGET_HOSTNAME=${TARGET_HOSTNAME:-wlanpi}

export FIRST_USER_NAME=${FIRST_USER_NAME:-wlanpi}
export FIRST_USER_PASS
export DISABLE_FIRST_BOOT_USER_RENAME=${DISABLE_FIRST_BOOT_USER_RENAME:-0}
export WPA_COUNTRY
export ENABLE_SSH="${ENABLE_SSH:-0}"
export PUBKEY_ONLY_SSH="${PUBKEY_ONLY_SSH:-0}"

export LOCALE_DEFAULT="${LOCALE_DEFAULT:-en_GB.UTF-8}"

export KEYBOARD_KEYMAP="${KEYBOARD_KEYMAP:-gb}"
export KEYBOARD_LAYOUT="${KEYBOARD_LAYOUT:-English (UK)}"

export TIMEZONE_DEFAULT="${TIMEZONE_DEFAULT:-Europe/London}"

export GIT_HASH=${GIT_HASH:-"$(git rev-parse HEAD)"}

export PUBKEY_SSH_FIRST_USER

export CLEAN
export APT_PROXY

export STAGE
export STAGE_DIR
export STAGE_WORK_DIR
export PREV_STAGE
export PREV_STAGE_DIR
export ROOTFS_DIR
export PREV_ROOTFS_DIR
export IMG_SUFFIX
export NOOBS_NAME
export NOOBS_DESCRIPTION
export EXPORT_DIR
export EXPORT_ROOTFS_DIR

export QUILT_PATCHES
export QUILT_NO_DIFF_INDEX=1
export QUILT_NO_DIFF_TIMESTAMPS=1
export QUILT_REFRESH_ARGS="-p ab"

# shellcheck source=scripts/common
source "${SCRIPT_DIR}/common"
# shellcheck source=scripts/dependencies_check
source "${SCRIPT_DIR}/dependencies_check"

if [ "$SETFCAP" != "1" ]; then
	export CAPSH_ARG="--drop=cap_setfcap"
fi

mkdir -p "${WORK_DIR}"
trap term EXIT INT TERM

dependencies_check "${BASE_DIR}/depends-arm64"

echo "Verifying native arm64 support..."
if ! arch-test -n arm64; then
	echo "ERROR: Native arm64 execution is not supported on this system."
	echo "This script requires a native arm64 host."
	exit 1
fi

#check username is valid
if [[ ! "$FIRST_USER_NAME" =~ ^[a-z][-a-z0-9_]*$ ]]; then
	echo "Invalid FIRST_USER_NAME: $FIRST_USER_NAME"
	exit 1
fi

if [[ "$DISABLE_FIRST_BOOT_USER_RENAME" == "1" ]] && [ -z "${FIRST_USER_PASS}" ]; then
	echo "To disable user rename on first boot, FIRST_USER_PASS needs to be set"
	echo "Not setting FIRST_USER_PASS makes your system vulnerable and open to cyberattacks"
	exit 1
fi

if [[ "$DISABLE_FIRST_BOOT_USER_RENAME" == "1" ]]; then
	echo "User rename on the first boot is disabled"
	echo "Be advised of the security risks linked to shipping a device with default username/password set."
fi

if [[ -n "${APT_PROXY}" ]] && ! curl --silent "${APT_PROXY}" >/dev/null ; then
	echo "Could not reach APT_PROXY server: ${APT_PROXY}"
	echo "Start apt-cacher-ng, or unset APT_PROXY and try again."
	exit 1
fi

if [[ -n "${WPA_PASSWORD}" && ${#WPA_PASSWORD} -lt 8 || ${#WPA_PASSWORD} -gt 63  ]] ; then
	echo "WPA_PASSWORD" must be between 8 and 63 characters
	exit 1
fi

if [[ "${PUBKEY_ONLY_SSH}" = "1" && -z "${PUBKEY_SSH_FIRST_USER}" ]]; then
	echo "Must set 'PUBKEY_SSH_FIRST_USER' to a valid SSH public key if using PUBKEY_ONLY_SSH"
	exit 1
fi

BUILD_START_TIME=$(date +%s)
BUILD_START_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
log "Begin ${BASE_DIR}"
log "Build started at: ${BUILD_START_TIMESTAMP}"

STAGE_LIST=${STAGE_LIST:-${BASE_DIR}/stage*}
if [ "$SKIP_FULL_IMAGE" = "true" ]; then
    FILTERED_STAGE_LIST=""
    for stage in ${STAGE_LIST}; do
        if [[ "$stage" != *"wlanpi2-full"* ]]; then
            [ -n "$FILTERED_STAGE_LIST" ] && FILTERED_STAGE_LIST+=" "
            FILTERED_STAGE_LIST+="$stage"
        fi
    done
    STAGE_LIST="$FILTERED_STAGE_LIST"
fi
export STAGE_LIST

EXPORT_CONFIG_DIR=$(realpath "${EXPORT_CONFIG_DIR:-"${BASE_DIR}/export-image"}")
if [ ! -d "${EXPORT_CONFIG_DIR}" ]; then
	echo "EXPORT_CONFIG_DIR invalid: ${EXPORT_CONFIG_DIR} does not exist"
	exit 1
fi
export EXPORT_CONFIG_DIR

for STAGE_DIR in $STAGE_LIST; do
	STAGE_DIR=$(realpath "${STAGE_DIR}")
	run_stage
done

CLEAN=1
for EXPORT_DIR in ${EXPORT_DIRS}; do
	STAGE_DIR=${EXPORT_CONFIG_DIR}
	# shellcheck source=/dev/null
	source "${EXPORT_DIR}/EXPORT_IMAGE"
	EXPORT_ROOTFS_DIR=${WORK_DIR}/$(basename "${EXPORT_DIR}")/rootfs
	run_stage
	if [ -e "${EXPORT_DIR}/EXPORT_NOOBS" ]; then
		# shellcheck source=/dev/null
		source "${EXPORT_DIR}/EXPORT_NOOBS"
		STAGE_DIR="${BASE_DIR}/export-noobs"
		run_stage
	fi
done

if [ -x "${BASE_DIR}/postrun.sh" ]; then
	log "Begin postrun.sh"
	cd "${BASE_DIR}"
	./postrun.sh
	log "End postrun.sh"
fi

BUILD_END_TIME=$(date +%s)
BUILD_END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))
BUILD_DURATION_FORMATTED=$(printf '%02d:%02d:%02d' $((BUILD_DURATION/3600)) $((BUILD_DURATION%3600/60)) $((BUILD_DURATION%60)))

log "End ${BASE_DIR}"
log "Build completed at: ${BUILD_END_TIMESTAMP}"
log "Total build time: ${BUILD_DURATION_FORMATTED} (${BUILD_DURATION} seconds)"

echo ""
echo "========================================"
echo "Build Summary"
echo "========================================"
echo "Started:  ${BUILD_START_TIMESTAMP}"
echo "Finished: ${BUILD_END_TIMESTAMP}"
echo "Duration: ${BUILD_DURATION_FORMATTED}"
echo "========================================"
echo ""
