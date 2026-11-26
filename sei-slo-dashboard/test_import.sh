#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CONTAINER_NAME="${CONTAINER_NAME:-sei-slo-grafana-import-test}"
GRAFANA_IMAGE="${GRAFANA_IMAGE:-grafana/grafana:12.0.0}"
PORT="${PORT:-13000}"
GRAFANA_URL="http://127.0.0.1:${PORT}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin}"
KEEP_RUNNING="${KEEP_RUNNING:-1}"

for binary in docker curl jq; do
  if ! command -v "${binary}" >/dev/null 2>&1; then
    echo "missing required command: ${binary}" >&2
    exit 1
  fi
done

if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER_NAME}"; then
  docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

docker run -d --rm \
  --name "${CONTAINER_NAME}" \
  -p "${PORT}:3000" \
  -e "GF_SECURITY_ADMIN_USER=${ADMIN_USER}" \
  -e "GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}" \
  -e GF_AUTH_ANONYMOUS_ENABLED=false \
  "${GRAFANA_IMAGE}" >/dev/null

echo "waiting for Grafana at ${GRAFANA_URL}"
for _ in $(seq 1 60); do
  if curl -fsS -u "${ADMIN_USER}:${ADMIN_PASSWORD}" "${GRAFANA_URL}/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

curl -fsS -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  -H 'Content-Type: application/json' \
  -X POST "${GRAFANA_URL}/api/datasources" \
  -d '{"name":"Prometheus","uid":"Prometheus","type":"prometheus","access":"proxy","url":"http://prometheus:9090","isDefault":true,"jsonData":{"timeInterval":"15s"}}' >/dev/null

payload="$(mktemp)"
trap 'rm -f "${payload}"' EXIT
jq -c '{dashboard: ., overwrite: true, folderId: 0}' "${SCRIPT_DIR}/sei_slo.json" > "${payload}"

import_response="$(
  curl -fsS -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
    -H 'Content-Type: application/json' \
    -X POST "${GRAFANA_URL}/api/dashboards/db" \
    --data-binary @"${payload}"
)"

status="$(printf '%s' "${import_response}" | jq -r '.status')"
if [[ "${status}" != "success" ]]; then
  echo "dashboard import failed: ${import_response}" >&2
  exit 1
fi

curl -fsS -u "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  "${GRAFANA_URL}/api/dashboards/uid/sei-slo" \
  | jq -r '"imported \(.dashboard.title) uid=\(.dashboard.uid) id=\(.dashboard.id) panels=\(.dashboard.panels | length)"'

echo "dashboard URL: ${GRAFANA_URL}/d/sei-slo/sei-slo"

if [[ "${KEEP_RUNNING}" == "0" ]]; then
  docker stop "${CONTAINER_NAME}" >/dev/null
  echo "stopped ${CONTAINER_NAME}"
else
  echo "stop with: docker stop ${CONTAINER_NAME}"
fi
