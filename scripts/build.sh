#!/usr/bin/env bash
# Membangun image lokal postfix-relay; tidak melakukan pull implicit.
set -euo pipefail
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(dirname "${SCRIPT_DIR}")"
source "${ROOT}/CONFIG"
readonly VERSION="$(<"${ROOT}/VERSION")"

podman build --pull=never \
  --build-arg "BASE_IMAGE=${BASE_IMAGE}" \
  --build-arg "IMAGE_PROJECT=$(<"${ROOT}/PROJECT")" \
  --build-arg "IMAGE_VERSION=${VERSION}" \
  --build-arg "POSTFIX_VERSION=${POSTFIX_VERSION}" \
  --tag "${IMAGE_NAME}:${VERSION}" \
  --tag "${IMAGE_NAME}:latest" \
  "${ROOT}"
