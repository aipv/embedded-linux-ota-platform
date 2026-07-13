#!/usr/bin/env bash
#
# Test the full OTA platform workflow
#
# Usage:
#   ./scripts/test_ota_platform.sh [build_options]
#
# This script:
#   1. Sources setup-environment
#   2. Runs build_image.sh
#   3. Uploads the artifact
#   4. Deploys the artifact

# Disable nounset temporarily for sourcing setup-environment
set +u
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure BBSERVER is set before sourcing setup-environment
export BBSERVER="${BBSERVER:-localhost:0}"

echo "========================================"
echo "OTA Platform Test"
echo "========================================"
echo ""

# Step 1: Source setup-environment
echo "Step 1: Sourcing setup-environment..."
source "${PROJECT_DIR}/setup-environment"
echo ""

# Re-enable nounset after sourcing
set -u

# Step 2: Build image
echo "Step 2: Building image..."
"${SCRIPT_DIR}/build_image.sh" "$@"
echo ""

# Step 3: Upload artifact
echo "Step 3: Uploading artifact..."
"${SCRIPT_DIR}/upload_artifact.sh"
echo ""

# Step 4: Deploy artifact
echo "Step 4: Deploying artifact..."
"${SCRIPT_DIR}/deploy_artifact.sh"

echo ""
echo "========================================"
echo "OTA Platform Test completed."
echo "========================================"
