# Postfix Enterprise SMTP Relay Bridge

[![Base Image](https://img.shields.io/badge/base-alpine-blue.svg)](Containerfile)
[![SMTP Port](https://img.shields.io/badge/submission_port-587-orange.svg)](README.md)
[![License](https://img.shields.io/badge/license-Proprietary_&_Confidential-red.svg)](LICENSE)

This repository provides a containerized **Postfix Enterprise SMTP Relay Bridge** for the Tomcat Monitoring & Diagnostics platform. It emulates a hardened corporate mail gateway within the local environment.

---

## 🏛️ Architecture & Mail Flow

```mermaid
flowchart LR
    DS["Tomcat Diagnostic Service"] ==>|Port 587 / STARTTLS + SASL| PR["Postfix Container<br/>(postfix-relay:587)"]
    PR ==>|Downstream Relay / Port 1025| MP["Mailpit Container<br/>(mailpit:1025)"]
    MP ==>|Web UI / Port 8025| SRE["SRE Viewer<br/>(http://localhost:8025)"]
```

---

## 🚀 Key Advantages & Design Invariants

1. **Realistic Enterprise Triage Verification:** The Diagnostic Service tests authenticated SMTP delivery against real-world enterprise protocols (Cyrus SASL username/password, STARTTLS encryption, delivery timeouts, and queue retries).
2. **Visual Incident Triage (Mailpit UI):** Postfix forwards authenticated emails downstream to Mailpit, allowing SRE operators to inspect rich 7-section HTML/text incident reports in their browser (`http://localhost:8025`).
3. **100% Offline & Self-Contained:** Eliminates dependencies on external third-party mail providers (e.g., Sendgrid, Office365) and prevents accidental outbound alert leaks.

---

## 📋 Port Specifications & Network

- **Port 587 (Submission):** Mandatory / opportunistic STARTTLS with Cyrus SASL authentication (`PLAIN`, `LOGIN`).
- **Port 25 (Internal):** Standard internal SMTP relay.
- **Downstream Relay Target:** `mailpit:1025`.
- **Target Network:** `devops-lab`.

---

## 🛠️ Build & Lifecycle Commands

```bash
# Build local container image
./scripts/build.sh

# Execute smoke test suite
./scripts/test.sh

# Run container on devops-lab network
./scripts/run.sh

# Stop and remove container
./scripts/clean.sh
```

---

## 📂 Repository Structure

```text
postfix-relay/
├── AGENTS.md                  Agent governance principles
├── CONFIG                     Configuration parameters & defaults
├── Containerfile              Hardened Alpine Postfix OCI container
├── PROJECT                    Script-readable project identifier
├── README.md                  Technical architecture documentation
├── VERSION                    Release version
├── entrypoint.sh              Runtime SASL initialization & Postfix daemon runner
└── scripts/
    ├── build.sh               Image build script
    ├── clean.sh               Container cleanup utility
    ├── run.sh                 Container runner
    └── test.sh                Automated smoke test suite
```

---

## 👤 Author & Maintainer

- **Lead Engineer & Architect:** Eddy Wiyatno (<edkas07@gmail.com>)
- **Role:** Senior DevOps & Reliability Engineer
- **Project:** Tomcat Monitoring & Diagnostics Platform
