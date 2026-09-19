# 📦 Installation & Deployment Guide — Postfix Enterprise SMTP Relay

[![Base Image](https://img.shields.io/badge/Base-Alpine_3.24-blue.svg)](Containerfile)
[![SMTP Port](https://img.shields.io/badge/Submission_Port-587-orange.svg)](README.md)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-SASL_%2B_STARTTLS-brightgreen.svg)](CONFIG)

This guide provides comprehensive instructions for building, deploying, configuring, and verifying the **Postfix Enterprise SMTP Relay Bridge** across local environments, lab clusters, and production fleets.

---

## 📑 Table of Contents

- [1. System & Container Engine Prerequisites](#1-system--container-engine-prerequisites)
- [2. Building the OCI Container Image](#2-building-the-oci-container-image)
- [3. Standalone Container Execution (Podman / Docker)](#3-standalone-container-execution-podman--docker)
- [4. Automated Fleet Deployment via `tmctl`](#4-automated-fleet-deployment-via-tmctl)
- [5. SASL Authentication & TLS Configuration](#5-sasl-authentication--tls-configuration)
- [6. Post-Installation Verification & Mail Flow Tests](#6-post-installation-verification--mail-flow-tests)

---

## 1. System & Container Engine Prerequisites

### Supported Operating Systems
* **Linux:** Amazon Linux 2023, Ubuntu (20.04 / 22.04 / 24.04 LTS), Debian (11 / 12), RHEL / Rocky Linux (8 / 9).
* **Windows:** Windows Server 2019 / 2022 / 2025 (via Docker Engine / WSL2 / Linux Containers).

### Container Engine Runtimes
* **Podman:** Version 4.0+.
* **Docker Engine:** Version 24.0+.

### Network Ports Required
* **Port 587 (SMTP Submission):** Cyrus SASL authenticated STARTTLS gateway for Tomcat Diagnostic Service.
* **Port 25 (Internal SMTP):** Internal unauthenticated relay.

---

## 2. Building the OCI Container Image

Build the container image using the automated build script:

```bash
# Clone repository
git clone git@github.com:edkas07-oss/postfix-relay.git
cd postfix-relay

# Build local container image
./scripts/build.sh
```

This compiles:
* `localhost/postfix-relay:latest`
* `localhost/postfix-relay:1.0.0`

---

## 3. Standalone Container Execution (Podman / Docker)

Run the container locally on the `devops-lab` bridge network:

```bash
./scripts/run.sh
```

Or execute directly via Podman:
```bash
podman run -d \
  --name postfix-relay \
  --net devops-lab \
  -p 587:587 \
  -v /opt/tm-home/tls/postfix.crt:/etc/postfix/tls/server.crt:ro,z \
  -v /opt/tm-home/tls/postfix.key:/etc/postfix/tls/server.key:ro,z \
  -v /opt/tm-home/tls/postfix-ca.crt:/etc/postfix/tls/ca.crt:ro,z \
  localhost/postfix-relay:latest
```

---

## 4. Automated Fleet Deployment via `tmctl`

In production fleets, the relay container is managed declaratively using `tmctl`:

```bash
# Deploy postfix relay target
tmctl stack deploy --target postfix

# Check container status
tmctl stack status
```

---

## 5. SASL Authentication & TLS Configuration

### SASL User Setup
The container initializes SASL credentials automatically from the host workspace or environment parameters:
* **Username:** `smtp-user`
* **Password:** Dynamically read from `/opt/tm-home/secrets/smtp-password`.

### Downstream Mail Delivery
Postfix forwards all authenticated incident report emails downstream to `mailpit:1025`, allowing SREs to view reports in real time at `http://localhost:8025`.

---

## 6. Post-Installation Verification & Mail Flow Tests

Verify STARTTLS encryption and SASL delivery:

```bash
# 1. Run automated smoke test suite
./scripts/test.sh

# 2. Test STARTTLS connection via OpenSSL
openssl s_client -connect localhost:587 -starttls smtp

# 3. Send test email using EHLO and verify in Mailpit UI (http://localhost:8025)
nc localhost 587 <<EOF
EHLO localhost
QUIT
EOF
```
