# Embedded Linux OTA Platform

[![CI](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/ci.yml)
[![Deployment](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/deployment.yml/badge.svg)](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/deployment.yml)
![Yocto](https://img.shields.io/badge/Yocto-Scarthgap-blue)
![Mender](https://img.shields.io/badge/Mender-OTA-success)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-success)

Embedded Linux OTA Platform is a reference project for building, deploying, and validating **Over-the-Air (OTA)** software updates using the **Yocto Project** and **Mender**.

## Project Status

- ✅ Yocto image build
- ✅ Mender Artifact generation
- ✅ OTA deployment
- ✅ Runtime validation
- ✅ GitHub Actions CI
- ✅ Self-hosted GitHub Runner
- ✅ End-to-end OTA workflow

## Build Status

| Workflow | Status |
|----------|--------|
| CI | ![CI](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/ci.yml/badge.svg) |
| Deployment | ![Deployment](https://github.com/aipv/embedded-linux-ota-platform/actions/workflows/deployment.yml/badge.svg) |


## CI/CD Architecture

The complete GitHub Actions workflow is described in
[docs/cicd-workflow.md](docs/cicd-workflow.md).

<p align="center">
  <img src="docs/images/cicd-architecture.svg" width="900">
</p>

## Features

* Yocto Scarthgap
* Mender OTA integration
* Automatic Artifact generation
* Build metadata management
* OTA deployment automation
* Device validation over SSH
* End-to-end OTA test pipeline
* CI/CD ready

---

## Project Structure

```text
embedded-linux-ota-platform/
├── certificates/
├── docs/
├── ext/
├── meta-ota-platform/
├── scripts/
├── project.conf
└── README.md
```

---

## Quick Start

Clone the repository:

```bash
git clone <repository-url>
cd embedded-linux-ota-platform

git submodule update --init --recursive
```

Create the local credentials:

```bash
cp certificates/mender.crt.sample certificates/mender.crt
cp certificates/secrets.conf.sample certificates/secrets.conf
```

Update the local configuration:

- `project.conf`
- `certificates/mender.crt`
- `certificates/secrets.conf`

Initialize the development environment and build the image:

```bash
source scripts/setup-env

build-image
ota-deployment
```

Run the complete automated pipeline:

```bash
test-pipeline --yes
```

## Workflow

```text
setup-env
    │
    ▼
build-image
    │
    ▼
check-build
    │
    ▼
deploy-build
    │
    ▼
deploy-status
    │
    ▼
validate-build
```

---

## Documentation

| Document                 | Description                          |
| ------------------------ | ------------------------------------ |
| `docs/installation.md`   | Development environment installation |
| `docs/configuration.md`  | Project configuration                |
| `docs/ota-workflow.md`   | OTA workflow                         |
| `docs/cicd-workflow.md`  | GitHub Actions CI/CD workflow        |
| `scripts/README.md`      | Command reference                    |
| `certificates/README.md` | Certificates and credentials         |

---

## License

See the `LICENSE` file.
