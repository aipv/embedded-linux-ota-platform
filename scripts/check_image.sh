#!/usr/bin/env bash
#
# Check the sdimg file exists, then copy it to a destination
# Uses scp for remote destinations (user@host:/path) or cp for local paths
#
# Usage:
#   source setup-environment
#   ./scripts/check_image.sh [destination]
#
# Examples:
#   ./scripts/check_image.sh                       # Check and copy to local /tmp/
#   ./scripts/check_image.sh root@192.168.0.82:/tmp  # Check and copy to remote host

set -e

DESTINATION="${1:-}"

if [[ -z "${DESTINATION}" ]]; then
    # Default to local /tmp/
    DESTINATION="/tmp/"
    COPY_CMD="cp"
elif [[ "${DESTINATION}" == *@*:* ]]; then
    # Remote destination: user@host:/path
    COPY_CMD="scp"
else
    # Local destination
    COPY_CMD="cp"
fi

if [[ -z "${TARGET_IMAGE_FILE}" ]]; then
    echo "Error: TARGET_IMAGE_FILE is not set" >&2
    echo "Please source setup-environment first" >&2
    exit 1
fi

echo "Checking image file..."
ls -la "${TARGET_IMAGE_FILE}"

if [[ ! -f "${TARGET_IMAGE_FILE}" ]]; then
    echo "Error: File not found: ${TARGET_IMAGE_FILE}" >&2
    exit 1
fi

echo "Copying ${TARGET_IMAGE_FILE} to ${DESTINATION}..."
${COPY_CMD} "${TARGET_IMAGE_FILE}" "${DESTINATION}"
echo "Done."
