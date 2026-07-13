#!/usr/bin/env bash
#
# Deploy a Mender artifact to a device
#
# Usage:
#   source setup-environment
#   ./scripts/deploy_artifact.sh [artifact_name]
#
# If artifact_name is not provided, reads from TARGET_MENDER_FILE

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source project configuration
if [[ -f "${PROJECT_DIR}/project.conf" ]]; then
    source "${PROJECT_DIR}/project.conf"
fi

# Source project.inc for dynamic variables
if [[ -f "${PROJECT_DIR}/build/conf/project.inc" ]]; then
    source "${PROJECT_DIR}/build/conf/project.inc"
fi

# Source secrets if available
if [[ -f "${PROJECT_DIR}/certificates/secrets.conf" ]]; then
    source "${PROJECT_DIR}/certificates/secrets.conf"
fi

# Source setup-environment if available
if [[ -f "${PROJECT_DIR}/setup-environment" ]]; then
    if [[ -z "${BUILDDIR:-}" ]]; then
        source "${PROJECT_DIR}/setup-environment" >/dev/null 2>&1
    fi
fi

if [[ $# -eq 1 ]]; then
    ARTIFACT_NAME="$1"
elif [[ -n "${TARGET_MENDER_FILE:-}" ]] && [[ -f "${TARGET_MENDER_FILE}" ]]; then
    # Read artifact name from the actual mender file
    ARTIFACT_NAME=$(mender-artifact read "${TARGET_MENDER_FILE}" 2>/dev/null \
        | awk -F': ' '/^  Name:/ {print $2}')
    if [[ -z "${ARTIFACT_NAME}" ]]; then
        echo "Error: Could not read artifact name from ${TARGET_MENDER_FILE}" >&2
        exit 1
    fi
else
    echo "Error: artifact_name not provided and TARGET_MENDER_FILE is not set or not found" >&2
    echo "Usage: $0 [artifact_name]" >&2
    exit 1
fi

if [[ -z "${MENDER_ACCESS_TOKEN:-}" ]]; then
    echo "Error: MENDER_ACCESS_TOKEN is not set" >&2
    echo "Please configure your Personal Access Token in certificates/secrets.conf" >&2
    exit 1
fi

if [[ -z "${DEVICE_MENDER_ID:-}" ]]; then
    echo "Error: DEVICE_MENDER_ID is not set" >&2
    exit 1
fi

if [[ -z "${MENDER_SERVER_URL:-}" ]]; then
    echo "Error: MENDER_SERVER_URL is not set" >&2
    exit 1
fi

DEPLOYMENT_NAME="deploy-${ARTIFACT_NAME}"

echo "========================================"
echo "Creating Mender Deployment"
echo "========================================"
echo "Server     : ${MENDER_SERVER_URL}"
echo "Device ID  : ${DEVICE_MENDER_ID}"
echo "Artifact   : ${ARTIFACT_NAME}"
echo "Deployment : ${DEPLOYMENT_NAME}"
echo ""

read -rp "Continue? [y/N] " ANSWER
if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

curl -i -X POST \
    "${MENDER_SERVER_URL}/api/management/v1/deployments/deployments" \
    -H "Authorization: Bearer ${MENDER_ACCESS_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"${DEPLOYMENT_NAME}\",
        \"artifact_name\": \"${ARTIFACT_NAME}\",
        \"devices\": [
            \"${DEVICE_MENDER_ID}\"
        ]
    }"

echo ""
echo "Deployment request sent."
