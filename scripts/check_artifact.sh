#!/usr/bin/env bash
#
# Check if an artifact exists on the Mender server
#
# Usage:
#   source setup-environment
#   ./scripts/check_artifact.sh [options]
#
# Options:
#   --all     Show all artifacts
#   (default) Check if target artifact exists on server

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

# Parse arguments
SHOW_ALL=false
if [[ "${1:-}" == "--all" ]]; then
    SHOW_ALL=true
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

if [[ "$SHOW_ALL" == "true" ]]; then
    echo "========================================"
    echo "All Mender Artifacts"
    echo "========================================"
    echo ""
    curl -s \
        -H "Authorization: Bearer ${MENDER_ACCESS_TOKEN}" \
        "${MENDER_SERVER_URL}/api/management/v1/deployments/artifacts" \
    | jq .
else
    # Get artifact name from target mender file
    if [[ -z "${TARGET_MENDER_FILE:-}" ]]; then
        echo "Error: TARGET_MENDER_FILE is not set" >&2
        echo "Please source setup-environment first" >&2
        exit 1
    fi

    ARTIFACT_NAME=$(mender-artifact read "${TARGET_MENDER_FILE}" 2>/dev/null \
        | awk -F': ' '/^  Name:/ {print $2}')

    if [[ -z "${ARTIFACT_NAME}" ]]; then
        echo "Error: Could not read artifact name from ${TARGET_MENDER_FILE}" >&2
        exit 1
    fi

    echo "========================================"
    echo "Checking Artifact on Server"
    echo "========================================"
    echo "Artifact Name: ${ARTIFACT_NAME}"
    echo ""

    RESULT=$(curl -s \
        -H "Authorization: Bearer ${MENDER_ACCESS_TOKEN}" \
        "${MENDER_SERVER_URL}/api/management/v1/deployments/artifacts" \
    | jq --arg name "${ARTIFACT_NAME}" '.[] | select(.name == $name)')

    if [[ -z "${RESULT}" ]] || [[ "${RESULT}" == "null" ]]; then
        echo "Not found."
    else
        echo "${RESULT}" | jq .
    fi
fi
