# OTA Workflow

This document describes the complete Over-the-Air (OTA) workflow of the
**Embedded Linux OTA Platform**.

The workflow covers the complete lifecycle of an OTA image:

1. Initialize the development environment
2. Build the Yocto image
3. Verify the local build
4. Deploy the OTA update
5. Monitor deployment progress
6. Validate the target device

---

# Overall Workflow

```text
                 setup-env
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

The complete automated workflow is implemented by:

```text
ota-deployment
```

The complete CI/CD pipeline is implemented by:

```text
test-pipeline
```

---

# Step 1 – Initialize the Environment

Initialize the project:

```bash
source scripts/setup-env
```

The script performs the following tasks:

- Loads `project.conf`
- Loads `certificates/secrets.conf` (if available)
- Initializes the Yocto build environment
- Creates `build/conf/project.inc` if it does not exist
- Exports project environment variables
- Adds `scripts/` to `PATH`

After initialization, all project commands are available.

---

# Step 2 – Build the Image

Build the default image:

```bash
build-image
```

Specify a release:

```bash
build-image --release dev
```

Specify a build ID:

```bash
build-image --release production --build-id 1.0.0
```

The build generates:

```text
build/
├── build.meta.json
└── conf/
    └── project.inc
```

It also generates the Yocto outputs:

- Mender Artifact (`.mender`)
- Disk image (`.wic`, `.wic.bz2`, etc.)

---

# Step 3 – Verify the Build

Validate the latest local build:

```bash
check-build
```

Perform full verification:

```bash
check-build --verify
```

The script verifies:

- Build metadata
- Artifact existence
- Disk image existence
- SHA256 checksums
- Internal Mender Artifact name

`build.meta.json` becomes the **single source of truth** for all subsequent deployment and validation steps.

---

# Step 4 – Deploy the OTA Update

Deploy the latest build:

```bash
deploy-build
```

Workflow:

```text
Local Artifact
      |
      +--> Upload Artifact
      |
      +--> Create Deployment
      |
      +--> Deployment ID
```

The deployment uses:

- `build.meta.json`
- `MENDER_ACCESS_TOKEN`
- `DEVICE_MENDER_ID`

---

# Step 5 – Monitor Deployment

Wait until deployment completes:

```bash
deploy-status
```

The script periodically queries the Mender Management API and reports:

- pending
- downloading
- installing
- rebooting
- success
- failure

The command exits with a non-zero status if the deployment fails or times out.

---

# Step 6 – Validate the Device

Verify that the target device is running the expected Artifact:

```bash
validate-build
```

The script checks:

- SSH connectivity
- Hostname
- Kernel version
- Systemd state
- Mender service
- Running Artifact
- Root filesystem usage
- Optional application services

If the device has been reflashed:

```bash
validate-build --refresh-host-key
```

---

# Complete OTA Deployment

Run the complete OTA deployment workflow:

```bash
ota-deployment
```

Internally, the workflow is:

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

This command is recommended for daily OTA testing.

---

# Complete Test Pipeline

Run the complete build, deployment and validation pipeline:

```bash
test-pipeline --yes
```

Pipeline:

```text
build-image
        |
        v
check-build
        |
        v
ota-deployment
```

This workflow is intended for CI/CD systems such as:

- GitHub Actions
- GitLab CI
- Jenkins
- Azure DevOps

---

# Build Metadata

Every successful build generates:

```text
build/build.meta.json
```

The metadata includes:

- Project name
- Release
- Build ID
- Artifact name
- Build timestamp
- Yocto machine
- Yocto image
- Artifact path
- Disk image path
- SHA256 checksums
- Git branch
- Git commit
- Repository dirty state

All deployment tools use this file instead of deriving build information from filenames.

---

# Typical Workflows

## Local Development

```bash
source scripts/setup-env

build-image

check-build --verify
```

## OTA Deployment

```bash
source scripts/setup-env

ota-deployment
```

## Complete Pipeline

```bash
source scripts/setup-env

test-pipeline --yes
```

---

# Related Documents

- `README.md`
- `docs/installation.md`
- `docs/configuration.md`
- `scripts/README.md`
- `certificates/README.md`
