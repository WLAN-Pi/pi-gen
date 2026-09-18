#!/bin/bash
# LOCAL DEVELOPMENT ONLY - NOT USED BY CI
# 
# This script creates an A/B partitioned image from a lite image build.
# For CI builds, see .github/workflows/build.yml (ab-partition-image job)
#
# Usage: ./local-dev-ab-partition.sh
# 
# The script will:
#   1. Find the most recent lite image in export-image/05-finalise/deploy/
#   2. Decompress it
#   3. Run scripts/ab-partition to create A/B layout
#   4. Compress and checksum the result
#   5. Place output back in deploy directory
#
# Environment variables:
#   AB_ROOT_SIZE - Size of each root partition in MB (default: 2500)
#
set -e

DEPLOY_DIR="./export-image/05-finalise/deploy"
AB_SCRIPT="./scripts/ab-partition"
AB_SUFFIX="AB_PARTITION"
AB_ROOT_SIZE="${AB_ROOT_SIZE:-2500}"

if [ ! -f "$AB_SCRIPT" ]; then
    echo "Error: required script not found: $AB_SCRIPT"
    exit 1
fi

if [ ! -x "$AB_SCRIPT" ]; then
    chmod +x "$AB_SCRIPT"
fi

echo "Looking for lite image in $DEPLOY_DIR"
LITE_IMG=$(find "$DEPLOY_DIR" -name "*lite*.img.gz" -print -quit)

if [ -z "$LITE_IMG" ]; then
    echo "Error: no lite image found in $DEPLOY_DIR"
    exit 1
fi

echo "Found lite image: $LITE_IMG"

LITE_BASE=$(basename "$LITE_IMG")
LITE_NOEXT="${LITE_BASE%.img.gz}"

OUTPUT_BASE="${LITE_NOEXT}-${AB_SUFFIX}.img"

echo ""
echo "Decompressing image"
gunzip -c "$LITE_IMG" > "original.img"

ORIG_SIZE=$(du -h original.img | cut -f1)
echo "Decompressed image size: $ORIG_SIZE"
echo ""

echo "Creating A/B partitioned image"
echo "Output: $OUTPUT_BASE"
echo "Root partition size: $AB_ROOT_SIZE MB"
echo ""

sudo "$AB_SCRIPT" "original.img" "$OUTPUT_BASE" "$AB_ROOT_SIZE"

if [ ! -f "$OUTPUT_BASE" ]; then
    echo "Error: A/B partition script failed"
    exit 1
fi

AB_SIZE=$(du -h "$OUTPUT_BASE" | cut -f1)
echo ""
echo "A/B partitioned image size: $AB_SIZE"
echo ""

echo "Compressing A/B image"
gzip -9 "$OUTPUT_BASE"

echo "Calculating checksum"
sha256sum "$OUTPUT_BASE.gz" > "$OUTPUT_BASE.gz.sha256"

echo "Moving to deploy directory"
sudo mv "$OUTPUT_BASE.gz" "$DEPLOY_DIR/"
sudo mv "$OUTPUT_BASE.gz.sha256" "$DEPLOY_DIR/"
sudo chown "$(id -u):$(id -g)" "$DEPLOY_DIR/$OUTPUT_BASE.gz"
sudo chown "$(id -u):$(id -g)" "$DEPLOY_DIR/$OUTPUT_BASE.gz.sha256"

rm -f "original.img"

echo ""
echo "A/B partitioned image created successfully"
echo "Location: $DEPLOY_DIR/$OUTPUT_BASE.gz"
echo "Checksum: $DEPLOY_DIR/$OUTPUT_BASE.gz.sha256"
echo ""
ls -lh "$DEPLOY_DIR/$OUTPUT_BASE.gz"
