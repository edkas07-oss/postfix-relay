# AGENTS.md — Developer & AI Agent Guidelines for Postfix Enterprise Relay

## 🎯 Repository Purpose
This repository provides the image lifecycle, build scripts, test suites, and configurations for the containerized **Postfix Enterprise SMTP Relay Bridge** within the Tomcat Monitoring & Diagnostics platform.

The service functions as an intermediate Mail Transfer Agent (MTA) that accepts authenticated incident notifications (Port 587 Submission / STARTTLS + SASL) from the Tomcat Diagnostic Service, enforces secure queue delivery, and forwards emails downstream to Mailpit (`mailpit:1025`) for visual SRE inspection.

## 🏛️ Architecture Rules & Non-Negotiables
1. **Authenticated Delivery:** Enforce Cyrus SASL authentication (`PLAIN`/`LOGIN`) and STARTTLS encryption on Port `587`.
2. **Zero Plaintext Credentials:** Runtime credentials MUST NOT be baked into the container image.
3. **100% Offline Self-Contained Isolation:** No traffic may egress outside the internal private network (`devops-lab`).

## 🛠️ Build & Validation Commands
- **Build Container Image:** `./scripts/build.sh`
- **Smoke Test Suite:** `./scripts/test.sh`
- **Run Container:** `./scripts/run.sh`
- **Clean Container:** `./scripts/clean.sh`
