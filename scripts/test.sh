#!/usr/bin/env bash
# Smoke test image postfix-relay.
set -euo pipefail
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(dirname "${SCRIPT_DIR}")"
source "${ROOT}/CONFIG"
readonly VERSION="$(<"${ROOT}/VERSION")"
readonly IMAGE="${IMAGE_NAME}:${VERSION}"

echo "Testing image: ${IMAGE}"
podman run --rm --pull=never --entrypoint /usr/sbin/postconf "${IMAGE}" mail_version
echo "Image verification passed."
