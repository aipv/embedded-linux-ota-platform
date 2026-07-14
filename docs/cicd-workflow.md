# CI/CD Workflow

This document describes the GitHub Actions integration used by the
**Embedded Linux OTA Platform**.

The CI/CD workflow connects the development PC, GitHub repository,
self-hosted Yocto builder, Mender OTA server, and Raspberry Pi test device.

<p align="center">
  <img
    src="images/cicd-architecture.svg"
    alt="Embedded Linux OTA Platform CI/CD architecture"
    width="800"
  />
</p>

The CI/CD implementation is split into two workflows:

```text
.github/workflows/
├── ci.yml
└── deployment.yml
```

- `ci.yml` validates the repository and produces a verified Yocto build.
- `deployment.yml` builds, deploys, monitors, and validates an OTA update on
  the physical test device.

---

## Overview

```text
Development PC
      |
      | Git push / pull request
      v
GitHub Repository
      |
      | GitHub Actions
      v
Self-hosted Yocto Runner
      |
      +--> Shell validation
      +--> Yocto metadata validation
      +--> Image build and verification
      |
      +--> Upload Mender Artifact
      +--> Create deployment
      +--> Monitor deployment
      +--> Validate device over SSH
      v
Mender Server and Test Device
```

The project uses the following CI helper commands:

| Command | Purpose |
|---|---|
| `ci-shell-check` | Validate Bash syntax, ShellCheck results, formatting, repository files, and embedded paths |
| `ci-yocto-check` | Parse BitBake metadata and verify required image tasks |
| `ci-build-check` | Build the image and run `check-build --verify` |
| `test-pipeline` | Run the complete build, deployment, monitoring, and device validation workflow |

---

# 1. CI Workflow

Workflow file:

```text
.github/workflows/ci.yml
```

## Triggers

The current workflow runs for:

```yaml
on:
  push:
    branches:
      - master
      - ci-workflow

  pull_request:
  workflow_dispatch:
```

This means the workflow starts when:

- A commit is pushed to `master`
- A commit is pushed to `ci-workflow`
- A pull request is created or updated
- The workflow is started manually from the GitHub Actions page

## Concurrency

```yaml
concurrency:
  group: ota-ci-${{ github.ref }}
  cancel-in-progress: true
```

Only the newest CI run for the same Git reference is kept active. An older run
is cancelled when a newer commit is pushed to the same branch.

## CI Stages

```text
Shell checks
      |
      v
Yocto metadata checks
      |
      v
Build verification
```

---

## 1.1 Shell Checks

Job name:

```text
shell-check
```

Runner:

```yaml
runs-on: ubuntu-24.04
```

This stage uses a GitHub-hosted Ubuntu runner because it does not require the
Yocto build environment or access to the local network.

The job:

1. Checks out the repository and all submodules
2. Installs `shellcheck` and `shfmt`
3. Executes:

```bash
scripts/ci-shell-check
```

The script checks:

- Bash syntax with `bash -n`
- ShellCheck warnings and errors
- `shfmt` formatting
- Tracked certificate and secret files
- Required sample and configuration files
- Host-specific absolute paths in key source files

---

## 1.2 Yocto Metadata Checks

Job name:

```text
yocto-check
```

Runner labels:

```yaml
runs-on:
  - self-hosted
  - linux
  - x64
  - yocto
```

This stage runs only after `shell-check` succeeds.

The job initializes the project environment and executes:

```bash
source scripts/setup-env
ci-yocto-check
```

`ci-yocto-check` performs:

```bash
bitbake -p
bitbake "${YOCTO_IMAGE}" -c listtasks
```

It also verifies that these required tasks exist:

```text
do_rootfs
do_image_mender
do_image_wic
```

This catches configuration, layer, recipe, and task graph problems without
running a complete image build.

The metadata check does not execute recipe tasks such as `do_configure`, so the
Mender certificate is not required for this job.

---

## 1.3 Build Verification

Job name:

```text
build-check
```

Runner labels:

```yaml
runs-on:
  - self-hosted
  - linux
  - x64
  - yocto
```

This stage starts only after `yocto-check` succeeds.

### Restore local credentials

The Mender certificate and API credential file are intentionally excluded from
Git. The current self-hosted runner copies them from the local development
checkout:

```bash
cp /home/test/workspace/embedded-linux-ota-platform/certificates/mender.crt    certificates/

cp /home/test/workspace/embedded-linux-ota-platform/certificates/secrets.conf    certificates/
```

The source files must exist on the self-hosted runner before this job starts.

For a shared or multi-runner setup, use a dedicated directory such as:

```text
/home/test/ota-secrets/
```

and reference that location from the workflow instead of a development
checkout.

### Build command

The job executes:

```bash
source scripts/setup-env

ci-build-check     --release ci     --build-id "${GITHUB_RUN_NUMBER}-${GITHUB_SHA::8}"     --log-dir "${PROJECT_DIR}/pipeline-logs"
```

The build ID combines:

```text
GitHub run number
+
first eight characters of the Git commit
```

Example:

```text
12-4e7a2514
```

`ci-build-check` performs:

```text
build-image
      |
      v
check-build --verify
```

It verifies:

- Yocto build completion
- Mender Artifact generation
- Disk image generation
- `build.meta.json`
- File sizes
- SHA256 checksums
- Internal Mender Artifact name
- Git branch, commit, and dirty state

---

## 1.4 CI Reports

The CI workflow collects:

```text
ci-reports/
├── build.meta.json
├── pipeline-logs/
├── submodules.txt
└── git-status.txt
```

The report bundle is uploaded with:

```yaml
uses: actions/upload-artifact@v6
```

Artifact name:

```text
ota-ci-reports-<run-number>
```

Retention:

```text
14 days
```

The report bundle contains metadata and logs, not the complete Yocto image
outputs.

---

# 2. Deployment Workflow

Workflow file:

```text
.github/workflows/deployment.yml
```

This workflow performs a complete OTA test against the configured Mender
server and physical test device.

## Triggers

```yaml
on:
  push:
    branches:
      - deployment

  workflow_dispatch:
```

The workflow starts automatically when a commit is pushed to the `deployment`
branch.

It can also be started manually from:

```text
GitHub Repository
→ Actions
→ Deployment Branch OTA Test
→ Run workflow
```

## Manual Inputs

| Input | Default | Purpose |
|---|---|---|
| `release` | `deployment` | Artifact release component |
| `refresh_host_key` | `false` | Refresh the stored SSH key after reflashing the device |
| `skip_upload` | `false` | Skip uploading an Artifact that already exists |

For automatic runs triggered by a push, the release is:

```text
deployment
```

---

## 2.1 Physical Device Lock

```yaml
concurrency:
  group: ota-test-device
  cancel-in-progress: false
```

Only one workflow may use the physical test device at a time.

Additional deployment runs wait instead of cancelling the active OTA update.

This prevents two workflows from:

- Creating competing deployments
- Rebooting the same device simultaneously
- Overwriting each other's validation results

---

## 2.2 Runner and Environment

Runner labels:

```yaml
runs-on: [self-hosted, linux, x64, yocto]
```

Timeout:

```text
360 minutes
```

GitHub environment:

```yaml
environment: ota-test
```

The `ota-test` environment can be used for:

- Deployment approvals
- Branch restrictions
- Environment-specific secrets and variables
- Deployment history

The self-hosted runner must be able to access:

- The Yocto download and sstate caches
- The Mender Server
- The target device over SSH
- The local certificate and secrets files

---

## 2.3 Restore Local Credentials

The deployment workflow restores:

```text
certificates/mender.crt
certificates/secrets.conf
```

using:

```bash
install -d -m 700 certificates

install -m 600     /home/test/workspace/embedded-linux-ota-platform/certificates/mender.crt     certificates/mender.crt

install -m 600     /home/test/workspace/embedded-linux-ota-platform/certificates/secrets.conf     certificates/secrets.conf
```

The workflow verifies the certificate with:

```bash
openssl x509     -in certificates/mender.crt     -noout     -subject     -issuer     -dates
```

These files remain outside Git and are copied into the checked-out workspace
only for the current workflow.

---

## 2.4 Pre-deployment Checks

Before deployment, the workflow executes:

```bash
scripts/ci-shell-check
```

and:

```bash
source scripts/setup-env
ci-yocto-check
```

This prevents a deployment from starting when the repository has Shell,
formatting, BitBake metadata, or required task problems.

---

## 2.5 Complete OTA Test Pipeline

The workflow initializes the environment without enabling Bash nounset until
after the Poky environment is loaded:

```bash
set -eo pipefail
source scripts/setup-env
set -u
```

This is required because `oe-init-build-env` may read optional variables such
as `BBSERVER` before they are defined.

The workflow then constructs the `test-pipeline` command:

```bash
test-pipeline     --release deployment     --build-id "${GITHUB_RUN_NUMBER}-${GITHUB_SHA::8}"     --log-dir "${PROJECT_DIR}/pipeline-logs"     --yes
```

For a manual run, optional flags may be added:

```bash
--refresh-host-key
--skip-upload
```

---

## 2.6 Pipeline Stages

`test-pipeline` runs the full OTA lifecycle:

```text
Stage 1  Build image
          build-image

Stage 2  Verify local build
          check-build --verify

Stage 3  Deploy build
          deploy-build

Stage 4  Wait for OTA update
          deploy-status

Stage 5  Validate device
          validate-build
```

### Build

`build-image` generates:

```text
build/conf/project.inc
build/build.meta.json
```

and the Yocto outputs:

```text
*.mender
*.wic
*.wic.bz2
```

### Verify

`check-build --verify` validates the generated metadata, output files,
checksums, and the internal Artifact name.

### Deploy

`deploy-build`:

1. Uploads the Mender Artifact
2. Creates a deployment for the configured device
3. Returns or records the deployment identity

### Monitor

`deploy-status` polls the Mender Management API until the deployment:

- Succeeds
- Fails
- Is aborted
- Reaches the configured timeout

### Runtime validation

`validate-build` connects to the target device over SSH and checks:

- SSH connectivity
- systemd state
- Mender service state
- Running Artifact name
- Kernel and hostname
- Root filesystem usage
- Optional application services

---

## 2.7 Deployment Reports

The deployment workflow collects:

```text
ci-reports/
├── build.meta.json
├── deployment.meta.json
├── pipeline-logs/
├── git-status.txt
└── submodules.txt
```

The report bundle is uploaded as:

```text
deployment-test-<run-number>
```

Retention:

```text
30 days
```

The upload step uses:

```yaml
actions/upload-artifact@v6
```

which uses the current Node.js runtime supported by GitHub Actions.

---

# 3. Self-hosted Runner

The Yocto and deployment jobs require a self-hosted runner.

Recommended labels:

```text
self-hosted
linux
x64
yocto
```

The runner can be installed on the development PC.

Recommended directory layout:

```text
/home/test/
├── workspace/
│   └── embedded-linux-ota-platform/
├── actions-runner/
│   └── _work/
└── yocto-cache/
    ├── downloads/
    └── sstate-cache/
```

The development checkout and GitHub Actions checkout are separate:

```text
Development:
  /home/test/workspace/embedded-linux-ota-platform

Runner:
  /home/test/actions-runner/_work/
      embedded-linux-ota-platform/
      embedded-linux-ota-platform/
```

The workflows should never depend on files generated inside a previous runner
checkout. Persistent credentials and caches should be stored outside `_work`.

---

# 4. Shared Yocto Cache

A persistent cache significantly reduces build time.

Recommended directories:

```text
/home/test/yocto-cache/downloads
/home/test/yocto-cache/sstate-cache
```

Both local development builds and the self-hosted runner can use these
directories.

Example configuration:

```bash
YOCTO_CACHE_DIR="${HOME}/yocto-cache"
DL_DIR="${YOCTO_CACHE_DIR}/downloads"
SSTATE_DIR="${YOCTO_CACHE_DIR}/sstate-cache"
```

Existing `downloads` and `sstate-cache` directories can be copied or moved to
the new location and reused.

Do not upload the complete sstate cache through GitHub Actions artifacts. Keep
it on persistent local storage attached to the self-hosted runner.

---

# 5. Branch Strategy

The current workflow design uses:

| Branch | Workflow |
|---|---|
| `master` | Standard CI |
| `ci-workflow` | CI workflow development and testing |
| `deployment` | Complete build, OTA deployment, and runtime validation |

Recommended process:

```text
Feature branch
      |
      | Pull request
      v
master
      |
      | Merge or promote tested commit
      v
deployment
      |
      | Push
      v
Physical device OTA test
```

Protect the `deployment` branch so only trusted developers can push to it.

The deployment workflow has access to:

- Local credentials
- The Mender API
- The test device
- The local network

Do not allow untrusted pull request code to run through this workflow.

---

# 6. Running the Workflows

## Automatic CI

Push to a configured CI branch:

```bash
git push origin master
```

or:

```bash
git push origin ci-workflow
```

## Automatic device deployment

Push to the deployment branch:

```bash
git push origin deployment
```

## Manual deployment

Open:

```text
GitHub
→ Actions
→ Deployment Branch OTA Test
→ Run workflow
```

Select the `deployment` branch and configure the optional inputs.

## Re-run a cancelled workflow

Open the workflow run and select:

```text
Re-run jobs
```

or:

```text
Re-run all jobs
```

No additional Git commit is required.

---

# 7. Troubleshooting

## Runner is waiting

Verify the runner is online:

```bash
cd /home/test/actions-runner
./run.sh
```

or, when installed as a service:

```bash
sudo ./svc.sh status
```

The GitHub runner page should show:

```text
Idle
```

## Certificate is missing

Verify the local source files:

```bash
ls -l     /home/test/workspace/embedded-linux-ota-platform/certificates/mender.crt     /home/test/workspace/embedded-linux-ota-platform/certificates/secrets.conf
```

Verify the restored files in the runner workspace:

```bash
ls -l certificates/mender.crt certificates/secrets.conf
```

## `BBSERVER: unbound variable`

Do not enable `set -u` before sourcing the Poky environment:

```bash
set -eo pipefail
source scripts/setup-env
set -u
```

Alternatively, make `setup-env` temporarily disable nounset while sourcing
`oe-init-build-env`.

## Deployment remains in progress

Check the device:

```bash
journalctl -u mender-updated.service -f
journalctl -u mender-authd.service -f
```

Verify name resolution:

```bash
getent hosts docker.mender.io
```

The image must contain a valid hosts or DNS entry for the Mender server.

Example:

```text
192.168.0.88 docker.mender.io s3.docker.mender.io
```

Verify BitBake received the host configuration:

```bash
bitbake-getvar -r "${YOCTO_IMAGE}" PROJECT_MENDER_SERVER_HOST
bitbake-getvar -r "${YOCTO_IMAGE}" PROJECT_MENDER_SERVER_HOST_IP
```

## Upload Artifact Node.js warning

Use:

```yaml
uses: actions/upload-artifact@v6
```

instead of older versions that target the deprecated Node.js 20 runtime.

---

# 8. Security

- Never commit `certificates/mender.crt`
- Never commit `certificates/secrets.conf`
- Keep the `deployment` branch restricted
- Do not run untrusted pull request code on the self-hosted runner
- Keep the GitHub runner software updated
- Use a dedicated directory for persistent credentials
- Restrict filesystem permissions on certificate and token files
- Use the `ota-test-device` concurrency lock
- Consider adding approval rules to the `ota-test` GitHub environment

Recommended permissions:

```bash
chmod 700 /home/test/ota-secrets
chmod 600 /home/test/ota-secrets/mender.crt
chmod 600 /home/test/ota-secrets/secrets.conf
```

---

# 9. Related Documents

- `README.md`
- `docs/installation.md`
- `docs/configuration.md`
- `docs/ota-workflow.md`
- `scripts/README.md`
- `certificates/README.md`
