# Certificates

This directory contains the local certificates and credentials required to
communicate with a Mender server.

The files in this directory are intended for **local development only**.

Only the sample files are stored in the Git repository. The real certificate
and credential files are created locally and **must not be committed**.

---

## Directory Layout

```text
certificates/
├── README.md
├── mender.crt.sample
├── secrets.conf.sample
├── mender.crt
└── secrets.conf
```

| File                  | Description                          | Git |
| --------------------- | ------------------------------------ | --- |
| `README.md`           | This document                        | ✓   |
| `mender.crt.sample`   | Example Mender server CA certificate | ✓   |
| `secrets.conf.sample` | Example credential configuration     | ✓   |
| `mender.crt`          | Local Mender server CA certificate   | ✗   |
| `secrets.conf`        | Local API credentials                | ✗   |

---

# Mender Server Certificate

The OTA deployment tools communicate with the Mender server over HTTPS.

The server certificate used by the project must be stored as:

```text
certificates/mender.crt
```

For a self-hosted Mender installation, the certificate is typically located at:

```text
compose/certs/mender.crt
```

Copy it into this directory:

```bash
cp compose/certs/mender.crt certificates/mender.crt
```

The hostname contained in the certificate must match the configured
`MENDER_SERVER_URL`.

Example:

```text
https://docker.mender.io
```

The file `mender.crt.sample` is only an example certificate and should **not**
be used for production deployments.

---

# Mender API Credentials

Create a local configuration file:

```bash
cp certificates/secrets.conf.sample certificates/secrets.conf
chmod 600 certificates/secrets.conf
```

Edit the file and configure your Personal Access Token:

```bash
# Personal Access Token generated from the Mender Web UI.
MENDER_ACCESS_TOKEN="<your-access-token>"
```

The Personal Access Token can be created from:

```
Mender Web UI
    ↓
My Account
    ↓
Personal Access Tokens
```

This token is used by the deployment scripts:

* `deploy-build`
* `deploy-status`
* `ota-deployment`

Never commit `secrets.conf` to Git.

---

# Verify the Certificate

Display the certificate information:

```bash
openssl x509 \
    -in mender.crt \
    -noout \
    -subject \
    -issuer \
    -dates \
    -ext subjectAltName
```

Verify that:

* the certificate is valid
* the certificate has not expired
* the hostname matches `MENDER_SERVER_URL`

---

# Quick Setup

After cloning the repository:

```bash
cp certificates/mender.crt.sample certificates/mender.crt
cp certificates/secrets.conf.sample certificates/secrets.conf

chmod 600 certificates/secrets.conf
```

Update the following files with your local configuration:
* `certificates/mender.crt`
* `certificates/secrets.conf`

