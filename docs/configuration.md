# Configuration Guide

This document describes how to configure the Embedded Linux OTA Platform after
installation.

## Overview

The project uses three local configuration files:

```text
project.conf
certificates/mender.crt
certificates/secrets.conf
```

These files are local to each developer and should not be committed to Git.

---

# 1. Project Configuration

Update the project.conf configuration file:

Typical configuration:

- PROJECT_NAME
- YOCTO_MACHINE
- YOCTO_IMAGE
- YOCTO_BUILD_DIR
- MENDER_SERVER_URL
- MENDER_SERVER_HOST_IP
- MENDER_SERVER_CRT
- DEVICE_IP_ADDRESS
- DEVICE_SSH_USER
- DEVICE_MENDER_ID

Example:

```bash
PROJECT_NAME="embedded-linux-ota-platform"

YOCTO_MACHINE="raspberrypi3-64"
YOCTO_IMAGE="ota-platform-minimal-image"

YOCTO_BUILD_DIR="${PROJECT_DIR}/build"

MENDER_SERVER_URL="https://docker.mender.io"
MENDER_SERVER_HOST_IP="192.168.0.100"
MENDER_SERVER_CRT="${PROJECT_DIR}/certificates/mender.crt"

DEVICE_IP_ADDRESS="192.168.0.82"
DEVICE_SSH_USER="root"
DEVICE_MENDER_ID="<device-id>"
```

---

# 2. Mender Server Certificate

Copy the certificate:

```bash
cp compose/certs/mender.crt certificates/mender.crt
```

The certificate must match the hostname configured in
`MENDER_SERVER_URL`.

Verify the certificate:

```bash
openssl x509 -in certificates/mender.crt -noout -subject -issuer -dates
```

---

# 3. Mender API Credentials

Create the local secrets file:

```bash
cp certificates/secrets.conf.sample certificates/secrets.conf
chmod 600 certificates/secrets.conf
```

Configure the Personal Access Token:

```bash
MENDER_ACCESS_TOKEN="<your-personal-access-token>"
```

Generate the token from:

```text
Mender Web UI
    ↓
My Account
    ↓
Personal Access Tokens
```

---

# 4. Initialize the Environment

After configuration:

```bash
source scripts/setup-env
```

The script:

- Loads `project.conf`
- Loads `certificates/secrets.conf`
- Initializes the Yocto environment
- Creates `build/conf/project.inc` if missing
- Exports project environment variables

---

# 5. Verify the Configuration

Display the environment:

```bash
source scripts/setup-env
```

Build the image:

```bash
build-image
```

Verify the build:

```bash
check-build
```

Deploy an OTA update:

```bash
ota-deployment
```

---

# Local Files

The following files are local and should not be committed:

```text
certificates/mender.crt
certificates/secrets.conf
```

The repository provides these templates:

```text
certificates/mender.crt.sample
certificates/secrets.conf.sample
```

---

# Related Documents

- README.md
- docs/installation.md
- certificates/README.md
- scripts/README.md
