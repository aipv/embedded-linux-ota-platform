# Installation Guide

This document describes how to prepare a development environment for the **Embedded Linux OTA Platform**.

The installation consists of the following steps:

1. Install the host development environment
2. Download the project dependencies
3. Install and start the Mender Server

---

# 1. System Requirements

The project has been verified on:

| Component      | Version                             |
| -------------- | ----------------------------------- |
| Ubuntu         | 24.04 LTS (recommended)             |
| Yocto Project  | Scarthgap                           |
| Python         | 3.10+                               |
| Git            | 2.40+                               |
| Docker         | 24+                                 |
| Docker Compose | v2                                  |
| Disk Space     | 100 GB minimum (200 GB recommended) |
| RAM            | 16 GB minimum (32 GB recommended)   |

---

# 2. Install Host Packages

Install the required packages:

```bash
sudo apt update

sudo apt install -y \
    gawk \
    wget \
    git \
    diffstat \
    unzip \
    texinfo \
    gcc \
    build-essential \
    chrpath \
    socat \
    cpio \
    python3 \
    python3-pip \
    python3-pexpect \
    python3-jinja2 \
    python3-subunit \
    xz-utils \
    iputils-ping \
    zstd \
    pzstd \
    unzstd \
    file \
    locales \
    libegl1-mesa \
    libsdl1.2-dev \
    pylint \
    xterm \
    jq \
    curl \
    openssl
```

Configure UTF-8 locale if required:

```bash
sudo locale-gen en_US.UTF-8
```

---

# 3. Install Docker

Install Docker:

```bash
sudo apt install docker.io docker-compose-v2
```

Enable Docker:

```bash
sudo systemctl enable docker
sudo systemctl start docker
```

Allow the current user to use Docker:

```bash
sudo usermod -aG docker $USER
```

Log out and log in again.

Verify:

```bash
docker version
docker compose version
```

---

# 4. Download Project

Clone the project:

```bash
git clone <project-url>

cd embedded-linux-ota-platform
```

Initialize submodules:

```bash
git submodule update --init --recursive
```

---

# 5. Install Mender Server

Clone the Mender integration repository:

```bash
git clone https://github.com/mendersoftware/integration.git

cd integration
```

Checkout the desired release:

```bash
git checkout 4.0.x
```

Start the demo server:

```bash
./demo up
```

The first startup may take several minutes.

When the server is ready, open:

```text
https://docker.mender.io
```

The default credentials are documented by the Mender project.

---

# 6. Verify Mender Server

Check that all containers are running:

```bash
docker ps
```

Open the Web UI:

```text
https://docker.mender.io
```

Verify that:

* HTTPS works
* Login succeeds
* Devices page is accessible

Generate a Personal Access Token from the WebUI, which is required by the scripts.
---

# Next Steps

After completing the installation, it is ready to start and build the project.

---


