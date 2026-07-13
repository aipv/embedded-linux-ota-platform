#!/usr/bin/env bash
#
# Check the output image and artifact files
#
# Usage:
#   source setup-environment
#   ./scripts/check_output.sh [options]
#
# Options:
#   --all     Show all artifacts (default: show only current configuration)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
SHOW_ALL=false
if [[ "${1:-}" == "--all" ]]; then
    SHOW_ALL=true
fi

# Source project configuration
if [[ -f "${PROJECT_DIR}/project.conf" ]]; then
    source "${PROJECT_DIR}/project.conf"
fi

# Source setup-environment if available (sets YOCTO_MACHINE, YOCTO_IMAGE, etc.)
if [[ -f "${PROJECT_DIR}/setup-environment" ]]; then
    # Only source if BUILDDIR is not already set
    if [[ -z "${BUILDDIR:-}" ]]; then
        source "${PROJECT_DIR}/setup-environment" >/dev/null 2>&1
    fi
fi

DEPLOY_DIR="${DEPLOY_DIR:-${PROJECT_DIR}/${YOCTO_BUILD_DIR:-build}/tmp/deploy/images/${YOCTO_MACHINE:-unknown}}"

if [[ ! -d "$DEPLOY_DIR" ]]; then
    echo "Error: deploy directory not found:"
    echo "  $DEPLOY_DIR"
    exit 1
fi

echo "======================================================================"
echo "Deploy directory: $DEPLOY_DIR"
echo "======================================================================"
echo ""

shopt -s nullglob

if [[ "$SHOW_ALL" == "true" ]]; then
    # Show all sdimg files
    sdimg_files=("$DEPLOY_DIR"/*.sdimg)
    if [[ ${#sdimg_files[@]} -gt 0 ]]; then
        echo "sdimg files:"
        for f in "${sdimg_files[@]}"; do
            echo "  $(ls -lh "$f" | awk '{print $5, $9}')"
        done
        echo ""
    fi
fi

# Check for .mender artifact files
if [[ "$SHOW_ALL" == "true" ]]; then
    mender_pattern="*.mender"
else
    # Show only current configuration
    mender_pattern="${YOCTO_IMAGE}-${YOCTO_MACHINE}.mender"
fi

mender_files=("$DEPLOY_DIR"/$mender_pattern)
if [[ ${#mender_files[@]} -gt 0 ]]; then
    echo "Mender artifacts:"
    for artifact in "${mender_files[@]}"; do
        echo "  File: $artifact"
        mender-artifact read "$artifact" 2>/dev/null | grep -E "^(  Name|  Version|  Compatible)" | sed 's/^/    /'
        echo ""
    done
fi

if [[ ${#mender_files[@]} -eq 0 ]]; then
    echo "No mender artifact found for: $mender_pattern"
    exit 1
fi
