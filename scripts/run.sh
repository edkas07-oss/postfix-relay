#!/usr/bin/env bash
# Menjalankan Postfix Enterprise Relay Bridge container pada network devops-lab.
set -euo pipefail
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT="$(dirname "${SCRIPT_DIR}")"
source "${ROOT}/CONFIG"
readonly VERSION="$(<"${ROOT}/VERSION")"

instance_name="${1:-${INSTANCE_NAME}}"
downstream_relay="${2:-mailpit}"
downstream_port="${3:-1025}"

podman container exists "${instance_name}" \
  && { echo "Container sudah ada: ${instance_name}" >&2; exit 1; }
podman network exists "${NETWORK}" || podman network create "${NETWORK}" >/dev/null

run_args=(
  --detach
  --pull=never
  --name "${instance_name}"
  --network "${NETWORK}"
  --network-alias "${instance_name}"
  --restart=on-failure:5
  --env "RELAY_HOST=${downstream_relay}"
  --env "RELAY_PORT=${downstream_port}"
)

podman run "${run_args[@]}" \
  "${IMAGE_NAME}:${VERSION}"

echo "Postfix Relay Bridge container '${instance_name}' started on network '${NETWORK}'."
echo "Listening: Port 587 (Submission / STARTTLS + SASL), Port 25 (SMTP)"
echo "Downstream Relay: [${downstream_relay}]:${downstream_port}"
