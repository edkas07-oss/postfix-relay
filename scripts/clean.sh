#!/usr/bin/env bash
# Menghentikan dan menghapus container postfix-relay.
set -euo pipefail
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(dirname "${SCRIPT_DIR}")"
source "${ROOT}/CONFIG"

instance_name="${1:-${INSTANCE_NAME}}"

if podman container exists "${instance_name}"; then
  echo "Stopping and removing container: ${instance_name}..."
  podman rm -f "${instance_name}" >/dev/null
  echo "Container '${instance_name}' removed."
else
  echo "Container '${instance_name}' does not exist."
fi
