# Repository Instructions

## Repository Purpose

Repository ini menyediakan image lifecycle, build, run, test, dan konfigurasi OCI Postfix Enterprise SMTP Relay Bridge (Pola A) untuk platform observabilitas DevOps Lab.
Service bertindak sebagai Enterprise Mail Transfer Agent (MTA) perantara yang menerima email investigasi/alert terotentikasi (Port 587 Submission / STARTTLS + SASL) dari Diagnostic Service / Alertmanager, mengelola antrean & rate limiting secara aman, dan meneruskannya (forward / downstream relay) ke Mailpit lokal (`mailpit:1025`).

## Source of Truth

- Gunakan dokumentasi Diagnostic MVP & DevOps Engineering Handbook sebagai source contract architecture, security, dan notification.
- Gunakan `PROJECT`, `VERSION`, dan `CONFIG` bersama untuk menentukan identitas aplikasi dan dependency baseline.

## Working Rules

- Jalankan `./scripts/build.sh` untuk membangun image OCI lokal.
- Jalankan `./scripts/test.sh` untuk validasi versi dan binary Postfix.
- Pastikan container berjalan pada network `devops-lab` dan terhubung ke `mailpit:1025`.
- Jangan menyimpan secret material atau credential plain-text di Git.

## Verification

- Jalankan `./scripts/test.sh`.
- Jalankan verification probe end-to-end melalui Diagnostic Service atau script verifikasi monitoring.
