#!/bin/bash -e

# 99-reduce-image-size/00-run.sh
# Reduces lite image root partition size by removing unnecessary files

echo "=========================================="
echo "Starting image size reduction cleanup..."
echo "=========================================="

INITIAL_SIZE=$(du -sm "${ROOTFS_DIR}" | cut -f1)
echo "Initial root filesystem size: ${INITIAL_SIZE}MB"

echo ""
echo "[1/4] Removing non-English locales..."
if [ -d "${ROOTFS_DIR}/usr/share/locale" ]; then
    LOCALE_COUNT_BEFORE=$(find "${ROOTFS_DIR}/usr/share/locale" -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo "  Found ${LOCALE_COUNT_BEFORE} locale directories"

    # Keep only English locales (en, en_US, en_GB, etc.)
    find "${ROOTFS_DIR}/usr/share/locale" -mindepth 1 -maxdepth 1 -type d ! -name 'en*' -exec rm -rf {} \; 2>/dev/null || true

    LOCALE_COUNT_AFTER=$(find "${ROOTFS_DIR}/usr/share/locale" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    echo "  Kept ${LOCALE_COUNT_AFTER} English locale directories"
    echo "  Removed $((LOCALE_COUNT_BEFORE - LOCALE_COUNT_AFTER)) non-English locales"
else
    echo "  Locale directory not found, skipping"
fi

echo ""
echo "[2/4] Removing man pages..."
if [ -d "${ROOTFS_DIR}/usr/share/man" ]; then
    MAN_SIZE=$(du -sm "${ROOTFS_DIR}/usr/share/man" | cut -f1)
    echo "  Man pages size: ${MAN_SIZE}MB"
    rm -rf "${ROOTFS_DIR}/usr/share/man"/*
    echo "  Man pages removed"
else
    echo "  Man directory not found, skipping"
fi

echo ""
echo "[3/4] Removing documentation (preserving licenses)..."
if [ -d "${ROOTFS_DIR}/usr/share/doc" ]; then
    DOC_SIZE=$(du -sm "${ROOTFS_DIR}/usr/share/doc" | cut -f1)
    echo "  Documentation size before: ${DOC_SIZE}MB"

    # Find all packages with documentation
    find "${ROOTFS_DIR}/usr/share/doc" -mindepth 1 -maxdepth 1 -type d | while read -r pkgdir; do
        # Keep only copyright/license files, remove everything else
        find "$pkgdir" -type f ! -name 'copyright' ! -name 'COPYING*' ! -name 'LICENSE*' -delete 2>/dev/null || true
        # Remove empty directories
        find "$pkgdir" -type d -empty -delete 2>/dev/null || true
    done

    DOC_SIZE_AFTER=$(du -sm "${ROOTFS_DIR}/usr/share/doc" 2>/dev/null | cut -f1)
    echo "  Documentation size after: ${DOC_SIZE_AFTER}MB"
    echo "  Removed $((DOC_SIZE - DOC_SIZE_AFTER))MB (kept licenses)"
else
    echo "  Documentation directory not found, skipping"
fi

echo ""
echo "[4/4] Cleaning APT cache..."
if [ -d "${ROOTFS_DIR}/var/cache/apt" ]; then
    APT_SIZE=$(du -sm "${ROOTFS_DIR}/var/cache/apt" | cut -f1)
    echo "  APT cache size: ${APT_SIZE}MB"

    on_chroot << EOF
apt-get clean
rm -rf /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*.bin
EOF

    APT_SIZE_AFTER=$(du -sm "${ROOTFS_DIR}/var/cache/apt" 2>/dev/null | cut -f1)
    echo "  APT cache cleaned: ${APT_SIZE}MB -> ${APT_SIZE_AFTER}MB"
else
    echo "  APT cache directory not found, skipping"
fi

FINAL_SIZE=$(du -sm "${ROOTFS_DIR}" | cut -f1)
SAVED=$((INITIAL_SIZE - FINAL_SIZE))

echo ""
echo "=========================================="
echo "Image size reduction complete!"
echo "=========================================="
echo "Initial size:  ${INITIAL_SIZE}MB"
echo "Final size:    ${FINAL_SIZE}MB"
echo "Space saved:   ${SAVED}MB"
echo "=========================================="
