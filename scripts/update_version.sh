#!/bin/bash -e

REQUEST_BUMP="$1"
echo "[update_version.sh] Starting with REQUEST_BUMP=${REQUEST_BUMP}"

setup_version() {
    echo "[update_version.sh] Checking for semver tool"
    if [ -f "/tmp/semver" ]; then
        echo "[update_version.sh] semver tool exists"
        return 0
    fi

    echo "[update_version.sh] Downloading semver tool"
    wget -q -O /tmp/semver \
    https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver
    chmod +x /tmp/semver
}

update_version() {
    setup_version

    echo "[update_version.sh] Getting last version"
    LAST_VERSION=${LAST_VERSION:-"$(git tag -l 'v[0-9].[0-9].[0-9]*' | sort -V | tail -n1)"}
    LAST_VERSION_HASH=${LAST_VERSION_HASH:-"$(git rev-parse "${LAST_VERSION}")"}$
    echo "[update_version.sh] LAST_VERSION=${LAST_VERSION}"

    last_version="${LAST_VERSION}"
    # if hash of previous version matches current git hash, we don't update!
    echo "[update_version.sh] Comparing hashes: GIT_HASH=${GIT_HASH} LAST_VERSION_HASH=${LAST_VERSION_HASH}"
    if [ "${GIT_HASH}" == "${LAST_VERSION_HASH}" ]; then
        echo "Hash of previous version matches the current. So, we're not bumping. Create a new empty commit with the appropriate tag"
        echo "${last_version}"
        exit 0
    fi

    REQUEST_BUMP="$(echo "${REQUEST_BUMP}" | tr '[:upper:]' '[:lower:]')"
    echo "[update_version.sh] Processing REQUEST_BUMP=${REQUEST_BUMP}"
    case "${REQUEST_BUMP}" in
        break|major) 
            echo "[update_version.sh] Request Bump: Break/Major detected"
            is_breaking=1 ;;
        feat|minor) 
            echo "[update_version.sh] Request Bump: Feature/Minor detected"
            is_feature=1 ;;
        rc) 
            echo "[update_version.sh] Request Bump: RC detected"
            is_rc=1 ;;
        patch) 
            echo "[update_version.sh] Request Bump: Patch detected"
            is_patch=1 ;;
        release) 
            echo "[update_version.sh] Request Bump: Release detected"
            is_release=1 ;;
        dev) 
            echo "[update_version.sh] Request Bump: Dev detected"
            is_dev=1 ;;
    *)
        # Guess the bump from commit history
        echo "[update_version.sh] Auto-detecting from commits"
        commits="${COMMITS_FROM_LAST}"

        is_breaking="$(echo "${commits}" | awk '{ print $2; }' | { grep "BREAK:" || :; })"
        is_feature="$(echo "${commits}" | awk '{ print $2; }' | { grep "feat:" || :; })"
        is_rc="$(echo "${last_version}" | { grep -- "-rc" || :; })"
        is_dev="$(echo "${last_version}" | { grep -- "-dev" || :; })"
        echo "[update_version.sh] Auto-detect results - breaking:${is_breaking} feature:${is_feature} rc:${is_rc} dev:${is_dev}"
        ;;
    esac

    if [ -n "${is_breaking}" ]; then
        ver_bump="major"
    elif [ -n "${is_feature}" ]; then
        ver_bump="minor"
    elif [ -n "${is_rc}" ]; then
        ver_bump="prerel rc."
    elif [ -n "${is_dev}" ]; then
        ver_bump="prerel dev."
    elif [ -n "${is_release}" ]; then
        ver_bump="release"
    else
        ver_bump="patch"
    fi
    echo "[update_version.sh] Determined ver_bump=${ver_bump}"

    if [ -n "${is_release}" ]; then
        # removes pre-release versioning
        # e.g. v3.0.0-rc1 to v3.0.0 or v3.0.0-dev1 to v3.0.0
        echo "[update_version.sh] Processing release version"
        new_version=$(/tmp/semver get release "${last_version}")
    else
        # Update version according to commit history
        echo "[update_version.sh] Calculating new version"
        new_version=$(/tmp/semver bump ${ver_bump} "${last_version}")

        # Add -rc to the new version code
        if [ -n "${is_rc}" ] && [ "${ver_bump}" != "prerel rc." ]; then
            echo "[update_version.sh] Adding RC designation"
            new_version=$(/tmp/semver bump ${ver_bump} "${new_version}")
        fi

        # Add -dev to the new version code
        if [ -n "${is_dev}" ] && [ "${ver_bump}" != "prerel dev." ]; then
            echo "[update_version.sh] Adding DEV designation"
            new_version=$(/tmp/semver bump ${ver_bump} "${new_version}")
        fi
    fi
    echo "[update_version.sh] Final version: v${new_version}"
    echo "v${new_version}"
}

update_version