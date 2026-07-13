# Installation Guide

This document describes how to prepare a development environment for the **Embedded Linux OTA Platform**.

The installation consists of the following steps:

1. Install the host development environment
2. Download the project source code
3. Install and start the Mender Server
4. Configure the project
5. Verify the installation

---

# 1. System Requirements

The project has been verified on:

| Component | Version |
|----------|---------|
| Ubuntu | 24.04 LTS (recommended) |
| Yocto Project | Scarthgap |
| Python | 3.10+ |
| Git | 2.40+ |
| Docker | 24+ |
| Docker Compose | v2 |
| Disk Space | 100 GB minimum (200 GB recommended) |
| RAM | 16 GB minimum (32 GB recommended) |

---

# 2. Install Host Packages

```bash
sudo apt update

sudo apt install -y \
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    python3-jinja2 python3-subunit xz-utils iputils-ping \
    zstd pzstd unzstd file locales libegl1-mesa \
    libsdl1.2-dev pylint xterm jq curl openssl
```

Configure the locale if required:

```bash
sudo locale-gen en_US.UTF-8
```

---

# 3. Install Docker

```bash
sudo apt install docker.io docker-compose-v2

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER
```

Log out and log in again.

Verify:

```bash
docker version
docker compose version
docker ps
```

---

# 4. Download the Project

```bash
git clone <repository-url>

cd embedded-linux-ota-platform

git submodule update --init --recursive
```

---

# 5. Install Mender Server

Clone the Mender Integration repository:

```bash
git clone https://github.com/mendersoftware/integration.git

cd integration
```

Checkout the version compatible with this project:

```bash
git checkout 4.0.x
```

Start the demo server:

```bash
./demo up
```

The first startup may take several minutes.

Open:

```text
https://docker.mender.io
```

---

# 6. Verify the Mender Server

Verify:

- HTTPS is accessible
- Login succeeds
- Devices page is available
- Artifacts page is available
- Deployments page is available

Generate a **Personal Access Token**:

```text
Mender Web UI
    ↓
My Account
    ↓
Personal Access Tokens
```

---

# 7. Configure the Project

Create the local configuration files:

```bash
cp certificates/mender.crt.sample    certificates/mender.crt

cp certificates/secrets.conf.sample    certificates/secrets.conf
```

Edit:

- `project.conf`
- `certificates/secrets.conf`

Replace the sample certificate with the certificate from your Mender server.

---

# 8. Initialize the Development Environment

```bash
source scripts/setup-env
```

The script:

- Loads `project.conf`
- Loads `certificates/secrets.conf`
- Initializes the Yocto environment
- Creates `build/conf/project.inc` if it does not exist
- Exports the project environment variables

---

# 9. Verify the Installation

Build the first image:

```bash
build-image
```

Verify the build:

```bash
check-build
```

---

# Next Steps

Deploy the image:

```bash
ota-deployment
```

Or run the complete automated pipeline:

```bash
test-pipeline --yes
```

See the project `README.md` for the complete workflow and command reference.
