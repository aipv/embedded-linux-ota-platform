#!/usr/bin/env bash
#
# Upload a Mender artifact to the Mender server
#
# Usage:
#   ./scripts/upload_artifact.sh <artifact-file.mender>
#
# The artifact will be uploaded to the Mender server configured in project.conf

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
    ARTIFACT_FILE="$1"
elif [[ -n "${TARGET_MENDER_FILE:-}" ]] && [[ -f "${TARGET_MENDER_FILE}" ]]; then
    ARTIFACT_FILE="${TARGET_MENDER_FILE}"
else
    echo "Error: artifact file not specified and TARGET_MENDER_FILE is not set or not found" >&2
    echo "Usage: $0 [artifact-file.mender]" >&2
    echo "       (without parameter, uses TARGET_MENDER_FILE from setup-environment)" >&2
    exit 1
fi

if [[ ! -f "$ARTIFACT_FILE" ]]; then
    echo "Error: artifact file not found: $ARTIFACT_FILE" >&2
    exit 1
fi

if [[ -z "${MENDER_ACCESS_TOKEN:-}" ]]; then
    echo "Error: MENDER_ACCESS_TOKEN is not set" >&2
    echo "Please configure your Personal Access Token in certificates/secrets.conf" >&2
    exit 1
fi

if [[ -z "${MENDER_SERVER_URL:-}" ]]; then
    echo "Error: MENDER_SERVER_URL is not set" >&2
    exit 1
fi

echo "========================================"
echo "Uploading Mender Artifact"
echo "========================================"
echo "Server     : $MENDER_SERVER_URL"
echo "Artifact   : $ARTIFACT_FILE"
echo ""

read -rp "Continue? [y/N] " ANSWER
if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

curl -i -X POST \
    "${MENDER_SERVER_URL}/api/management/v1/deployments/artifacts" \
    -H "Authorization: Bearer ${MENDER_ACCESS_TOKEN}" \
    -F "artifact=@${ARTIFACT_FILE}"

echo ""
echo "Upload request sent."
