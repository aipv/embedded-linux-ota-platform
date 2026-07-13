#!/usr/bin/env bash
#
# Flash an sdimg file to an SD card or eMMC device
#
# Usage:
#   ./scripts/flash_image.sh <file> <device_name>
#
# Example:
#   ./scripts/flash_image.sh ota-platform-minimal-image-raspberrypi3-64.sdimg mmcblk0

set -e

IMAGE_FILE="${1:-}"
DEVICE_NAME="${2:-}"

if [[ -z "${IMAGE_FILE}" ]] || [[ -z "${DEVICE_NAME}" ]]; then
    echo "Error: Both image file and device name are required" >&2
    echo "Usage: $0 <file> <device_name>" >&2
    echo "Example: $0 ota-platform-minimal-image-raspberrypi3-64.sdimg mmcblk0" >&2
    exit 1
fi

DEVICE="/dev/${DEVICE_NAME}"

if [[ ! -f "${IMAGE_FILE}" ]]; then
    echo "Error: File not found: ${IMAGE_FILE}" >&2
    exit 1
fi

if [[ ! -b "${DEVICE}" ]]; then
    echo "Error: Device not found: ${DEVICE}" >&2
    echo "Please check the device name and ensure it exists" >&2
    exit 1
fi

echo "Listing block devices:"
lsblk
echo ""

# Unmount any mounted partitions on the device
echo "Checking for mounted partitions on ${DEVICE}..."
# Get list of mounted partitions belonging to this device
MOUNTED_PARTS=$(mount | grep -E "^${DEVICE}[^a-zA-Z]" | cut -d' ' -f1 || true)
if [[ -n "${MOUNTED_PARTS}" ]]; then
    echo "Unmounting mounted partitions..."
    echo "${MOUNTED_PARTS}" | xargs -r umount -v
    echo ""
fi

echo "=========================================="
echo "Flash Image to Device"
echo "=========================================="
echo ""
echo "Image file: ${IMAGE_FILE}"
echo "Device:     ${DEVICE}"
echo ""
echo "WARNING: This will ERASE all data on ${DEVICE}!"
echo ""

echo "Flashing ${IMAGE_FILE} to ${DEVICE}..."
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! "${REPLY}" =~ ^yes$ ]]; then
    echo "Aborted."
    exit 1
fi

dd if="${IMAGE_FILE}" of="${DEVICE}" bs=4M status=progress conv=fsync
sync
echo "Done."
