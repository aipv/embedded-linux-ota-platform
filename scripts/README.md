# Scripts Reference

This directory contains the command-line tools used to build, verify, deploy,
monitor, and validate OTA updates for the Embedded Linux OTA Platform.

## Workflow

```text
source scripts/setup-env
        |
        v
build-image
        |
        v
check-build
        |
        v
deploy-build
        |
        v
deploy-status
        |
        v
validate-build
```

The complete automated workflows are:

```text
ota-deployment
    check-build
    deploy-build
    deploy-status
    validate-build
```

```text
test-pipeline
    build-image
    check-build
    ota-deployment
```

---

## Environment Initialization

Before using any command in this directory, initialize the environment:

```bash
source scripts/setup-env
```

`setup-env` adds the `scripts/` directory to `PATH`, so commands can be run
directly:

```bash
build-image
check-build
ota-deployment
```

---

# setup-env

## Function

Initialize the project and Yocto shell environment.

The script:

1. Locates the project root
2. Loads `project.conf`
3. Loads `certificates/secrets.conf` when available
4. Sources `ext/poky/oe-init-build-env`
5. Exports project and build paths
6. Adds `scripts/` to `PATH`
7. Copies `project.inc.sample` to the build configuration directory when
   `project.inc` does not exist
8. Prints the initialized environment

## Usage

```bash
source scripts/setup-env
```

This script must be sourced, not executed.

## Reads

| File | Purpose |
|---|---|
| `project.conf` | Local project configuration |
| `certificates/secrets.conf` | Local Mender API credentials |
| `ext/poky/oe-init-build-env` | Yocto environment initialization |
| `meta-ota-platform/conf/templates/default/project.inc.sample` | Default BitBake project configuration |

## Generates

| File | Purpose |
|---|---|
| `build/conf/project.inc` | Default BitBake configuration when missing |

The existing `project.inc` file is not overwritten.

## Exports

Typical exported variables include:

```text
PROJECT_DIR
PROJECT_CONFIG
SECRETS_CONFIG
SCRIPTS_DIR
BUILDDIR
CONF_DIR
DEPLOY_DIR_IMAGE
PROJECT_INC
BUILD_META_FILE
YOCTO_MACHINE
YOCTO_IMAGE
MENDER_SERVER_URL
DEVICE_IP_ADDRESS
DEVICE_SSH_USER
DEVICE_MENDER_ID
MENDER_ACCESS_TOKEN
```

---

# build-image

## Function

Generate the BitBake project configuration, build the configured Yocto image,
and create immutable build metadata.

## Usage

```bash
build-image
```

Specify the release:

```bash
build-image --release dev
```

Specify the release and build ID:

```bash
build-image \
    --release production \
    --build-id 1.0.0
```

Short options:

```bash
build-image -r production -b 1.0.0
```

## Reads

| Source | Purpose |
|---|---|
| Environment exported by `setup-env` | Project, Yocto, Mender, and path configuration |
| `project.conf` values already loaded in the shell | Static project configuration |
| Yocto recipes and layers | Image build inputs |

## Generates

| File | Purpose |
|---|---|
| `build/conf/project.inc` | BitBake configuration for the current build |
| `build/build.meta.json` | Build manifest for later scripts |
| `.mender` file | Mender OTA Artifact |
| `.wic`, `.wic.bz2`, or another WIC output | Initial device image |

## Dynamic Values

The script generates:

```text
IMAGE_RELEASE
IMAGE_BUILD_ID
MENDER_ARTIFACT_NAME
```

The Artifact name format is:

```text
PROJECT_NAME-IMAGE_RELEASE-IMAGE_BUILD_ID
```

Example:

```text
embedded-linux-ota-platform-dev-20260713181359
```

## Build Metadata

`build.meta.json` contains:

- Project name and directory
- Release
- Build ID
- Artifact name
- Build timestamp
- Yocto machine and image
- Artifact path, size, and SHA256
- Disk image path, size, and SHA256
- Git branch, commit, and dirty status

---

# check-build

## Function

Load and validate the latest local build.

The script can be used both as a command and as a shell library.

## Usage

Display build information:

```bash
check-build
```

Verify SHA256 values and the internal Mender Artifact name:

```bash
check-build --verify
```

Print the raw metadata:

```bash
check-build --json
```

Quiet validation:

```bash
check-build --quiet
```

## Reads

| File | Purpose |
|---|---|
| `build/build.meta.json` | Build manifest |
| Mender Artifact | File existence, size, SHA256, and internal name |
| Disk image | File existence, size, and SHA256 |

## Generates

None.

## Library Usage

Other scripts can source it:

```bash
source "${SCRIPTS_DIR}/check-build"

check_build_load
check_build_verify
```

## Exported Build Variables

After `check_build_load`, the following variables are available:

```text
BUILD_PROJECT_NAME
BUILD_PROJECT_DIR
BUILD_RELEASE
BUILD_ID
BUILD_ARTIFACT_NAME
BUILD_TIME
BUILD_YOCTO_MACHINE
BUILD_YOCTO_IMAGE
BUILD_YOCTO_BUILDDIR
BUILD_ARTIFACT_FILE
BUILD_ARTIFACT_SIZE
BUILD_ARTIFACT_SHA256
BUILD_DISK_IMAGE_FILE
BUILD_DISK_IMAGE_SIZE
BUILD_DISK_IMAGE_SHA256
BUILD_GIT_BRANCH
BUILD_GIT_COMMIT
BUILD_GIT_DIRTY
```

---

# deploy-build

## Function

Upload the latest local Mender Artifact and create a deployment for a target
device.

## Usage

```bash
deploy-build
```

Verify the build before upload:

```bash
deploy-build --verify
```

Skip Artifact upload and create only the deployment:

```bash
deploy-build --skip-upload
```

Run without confirmation:

```bash
deploy-build --yes
```

Override the device ID:

```bash
deploy-build --device-id DEVICE_ID
```

Override the deployment name:

```bash
deploy-build --name deployment-name
```

## Reads

| Source | Purpose |
|---|---|
| `check-build` | Artifact name and path |
| `build/build.meta.json` | Build metadata |
| `MENDER_SERVER_URL` | Mender Management API endpoint |
| `MENDER_ACCESS_TOKEN` | Management API authentication |
| `DEVICE_MENDER_ID` | Target Mender device |

## Generates

No local files.

The script creates:

- A Mender Artifact entry on the server
- A Mender deployment for the selected device

---

# deploy-status

## Function

Continuously monitor a Mender deployment until it succeeds, fails, is aborted,
or reaches the configured timeout.

## Usage

```bash
deploy-status
```

Set polling interval:

```bash
deploy-status --interval 10
```

Set timeout:

```bash
deploy-status --timeout 3600
```

## Reads

| Source | Purpose |
|---|---|
| `check-build` | Current Artifact name |
| `build/build.meta.json` | Build identity |
| `MENDER_SERVER_URL` | Mender Management API endpoint |
| `MENDER_ACCESS_TOKEN` | API authentication |

## Generates

None.

## Exit Status

| Result | Exit code |
|---|---|
| Deployment completed successfully | `0` |
| Deployment failed or was aborted | non-zero |
| Timeout reached | non-zero |
| Deployment not found | non-zero |

---

# validate-build

## Function

SSH to the target device and verify that the deployed build is running
correctly.

## Usage

```bash
validate-build
```

Override host and user:

```bash
validate-build \
    --host 192.168.0.82 \
    --user root
```

Validate additional systemd services:

```bash
validate-build \
    --service my-application.service \
    --service another-service.service
```

Refresh the stored SSH host key after reflashing:

```bash
validate-build --refresh-host-key
```

Skip the Artifact name comparison:

```bash
validate-build --skip-artifact-check
```

## Reads

| Source | Purpose |
|---|---|
| `check-build` | Expected Artifact name |
| `DEVICE_IP_ADDRESS` | SSH host |
| `DEVICE_SSH_USER` | SSH user |
| Target device | Runtime state and installed Artifact |

## Checks

- SSH connectivity
- Hostname
- Kernel version
- Uptime
- systemd overall state
- Mender service state
- Running Mender Artifact name
- Optional application services
- Root filesystem usage
- Required runtime directories

## Generates

None.

---

# ota-deployment

## Function

Run the complete OTA deployment workflow for an already-built image.

## Workflow

```text
check-build --verify
        |
        v
deploy-build
        |
        v
deploy-status
        |
        v
validate-build
```

## Usage

```bash
ota-deployment
```

Non-interactive operation:

```bash
ota-deployment --yes
```

Refresh the SSH host key after reflashing:

```bash
ota-deployment --refresh-host-key
```

Skip Artifact upload:

```bash
ota-deployment --skip-upload
```

Skip SSH validation:

```bash
ota-deployment --skip-validation
```

Validate additional services:

```bash
ota-deployment \
    --service my-application.service
```

## Reads

- Environment exported by `setup-env`
- `build/build.meta.json`
- Mender access token
- Device ID
- Device SSH configuration

## Generates

No local build files.

It creates a Mender deployment and prints a deployment summary.

---

# test-pipeline

## Function

Run the complete build, deployment, and device validation pipeline.

This command is intended as the foundation for CI/CD integration.

## Workflow

```text
build-image
        |
        v
check-build --verify
        |
        v
ota-deployment
```

## Usage

Interactive pipeline:

```bash
test-pipeline
```

Non-interactive CI/CD pipeline:

```bash
test-pipeline --yes
```

Specify release and build ID:

```bash
test-pipeline \
    --release staging \
    --build-id "${CI_PIPELINE_ID}" \
    --yes
```

Only build and validate:

```bash
test-pipeline \
    --skip-deployment \
    --yes
```

Store stage logs:

```bash
test-pipeline \
    --log-dir "${PROJECT_DIR}/pipeline-logs" \
    --yes
```

## Reads

- Environment exported by `setup-env`
- Project configuration
- Certificates and secrets
- Yocto source layers
- Target device configuration

## Generates

| Output | Purpose |
|---|---|
| `build/conf/project.inc` | BitBake build configuration |
| `build/build.meta.json` | Build manifest |
| Yocto image outputs | OTA and initial-flash images |
| Pipeline logs | Optional stage logs |

## CI/CD Behavior

- Uses non-zero exit codes on failure
- Stops immediately when a stage fails
- Prints the failed stage
- Prints elapsed time
- Supports non-interactive mode
- Supports per-stage log files
- Supports build-only operation
- Supports optional deployment and validation

---

# Common Files

## project.conf

Local project configuration.

Typical values:

```text
PROJECT_NAME
YOCTO_BUILD_DIR
YOCTO_MACHINE
YOCTO_IMAGE
MENDER_SERVER_URL
MENDER_SERVER_HOST_IP
MENDER_SERVER_CRT
DEVICE_SSH_USER
DEVICE_IP_ADDRESS
DEVICE_MENDER_ID
```

## certificates/secrets.conf

Local credentials.

Typical value:

```text
MENDER_ACCESS_TOKEN
```

This file must not be committed to Git.

## build/conf/project.inc

Generated BitBake configuration for the current build.

It contains static project values and dynamic build values.

## build/build.meta.json

Immutable build manifest generated after a successful build.

All deployment and validation scripts use this file as the source of truth for
the latest local build.

---

# Typical Workflows

## Local build

```bash
source scripts/setup-env
build-image
check-build --verify
```

## OTA deployment

```bash
source scripts/setup-env
ota-deployment
```

## Complete pipeline

```bash
source scripts/setup-env
test-pipeline --yes
```

## Build-only CI job

```bash
source scripts/setup-env

test-pipeline \
    --release "${CI_COMMIT_REF_NAME:-dev}" \
    --build-id "${CI_PIPELINE_ID:-manual}" \
    --skip-deployment \
    --log-dir "${PROJECT_DIR}/pipeline-logs" \
    --yes
```

---

# Dependencies

The scripts may require:

```text
bash
bitbake
curl
jq
ssh
ssh-keygen
sha256sum
stat
find
mender-artifact
```

The Yocto environment must be initialized before running commands that depend
on BitBake or the build directory.

---

# Security Notes

- Never commit `certificates/secrets.conf`
- Never print `MENDER_ACCESS_TOKEN`
- Do not disable SSH host-key validation globally
- Use `--refresh-host-key` only after confirming that the target device was
  intentionally reflashed or replaced
- Keep `build.meta.json` immutable after creation
- Verify the build before deployment in automated pipelines
