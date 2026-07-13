#!/usr/bin/env bash
#
# Build the Yocto image and update environment
#
# Usage:
#   source setup-environment
#   ./scripts/build_image.sh [options]
#
# Options:
#   -b <build_id>    Set IMAGE_BUILD_ID
#   -r <release>     Set IMAGE_RELEASE
#   -h               Show this help
#
# Examples:
#   ./scripts/build_image.sh                    # Build with new timestamp
#   ./scripts/build_image.sh -b v1.0.0          # Build with custom build ID
#   ./scripts/build_image.sh -r prod            # Build with release name

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source project configuration
if [[ -f "${PROJECT_DIR}/project.conf" ]]; then
    source "${PROJECT_DIR}/project.conf"
fi

BUILD_ID=""
RELEASE=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Build the Yocto image and update environment.

Options:
  -b <build_id>    Set IMAGE_BUILD_ID
  -r <release>     Set IMAGE_RELEASE
  -h               Show this help

Examples:
  $(basename "$0")                    # Build with new timestamp
  $(basename "$0") -b v1.0.0          # Build with custom build ID
  $(basename "$0") -r prod            # Build with release name
EOF
}

while getopts ":b:r:h" opt; do
    case "$opt" in
        b)
            BUILD_ID="$OPTARG"
            ;;
        r)
            RELEASE="$OPTARG"
            ;;
        h)
            usage
            exit 0
            ;;
        :)
            echo "Error: Option -$OPTARG requires an argument." >&2
            usage
            exit 1
            ;;
        \?)
            echo "Error: Unknown option -$OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done

# Generate new timestamp if BUILD_ID not provided
if [[ -z "$BUILD_ID" ]]; then
    BUILD_ID="$(date -u +%Y%m%d%H%M%S)"
fi

# Update project.conf with new values
if [[ -n "$BUILD_ID" ]]; then
    sed -i "s/^IMAGE_BUILD_ID=.*/IMAGE_BUILD_ID=\"$BUILD_ID\"/" "${PROJECT_DIR}/project.conf"
fi

if [[ -n "$RELEASE" ]]; then
    sed -i "s/^IMAGE_RELEASE=.*/IMAGE_RELEASE=\"$RELEASE\"/" "${PROJECT_DIR}/project.conf"
fi

# Generate new MENDER_ARTIFACT_NAME from the values we already have
MENDER_ARTIFACT_NAME="${PROJECT_NAME}-${RELEASE:-${IMAGE_RELEASE}}-${BUILD_ID}"

# Update project.inc with new values
PROJECT_INC="${PROJECT_DIR}/build/conf/project.inc"
sed -i "s/^IMAGE_RELEASE = .*/IMAGE_RELEASE = \"${RELEASE:-${IMAGE_RELEASE}}\"/" "${PROJECT_INC}"
sed -i "s/^IMAGE_BUILD_ID = .*/IMAGE_BUILD_ID = \"${BUILD_ID}\"/" "${PROJECT_INC}"
sed -i "s/^MENDER_ARTIFACT_NAME = .*/MENDER_ARTIFACT_NAME = \"${MENDER_ARTIFACT_NAME}\"/" "${PROJECT_INC}"

echo "Updated: IMAGE_RELEASE=${RELEASE:-${IMAGE_RELEASE}}, IMAGE_BUILD_ID=${BUILD_ID}, MENDER_ARTIFACT_NAME=${MENDER_ARTIFACT_NAME}"

# Check if already in Yocto environment (BUILDDIR is set)
if [[ -z "${BUILDDIR:-}" ]]; then
    # Not in Yocto environment, source setup-environment to init Yocto env
    source "${PROJECT_DIR}/setup-environment"
else
    # Already in Yocto environment, reload project.conf to get updated values
    source "${PROJECT_DIR}/project.conf"
fi

echo ""
echo "========================================"
echo "Building Yocto Image"
echo "========================================"
echo "Image      : ${YOCTO_IMAGE:-unknown}"
echo "Build ID   : $BUILD_ID"
[[ -n "$RELEASE" ]] && echo "Release    : $RELEASE"
echo ""

bitbake "${YOCTO_IMAGE}"

echo ""
echo "========================================"
echo "Build completed successfully."
echo "========================================"
