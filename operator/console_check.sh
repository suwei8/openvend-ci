#!/usr/bin/env bash
set -euo pipefail

# Console readiness check for Phase 7-7.
# Fail closed: missing container or failed probes return non-zero.

CONTAINER="${CONSOLE_CONTAINER:-openvend-console}"
URLS=(
  "${CONSOLE_URL:-http://127.0.0.1/}"
  "${CONSOLE_DEEP_LINK_URL:-http://127.0.0.1/index.html}"
)

echo "[console] container=${CONTAINER}"

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "[console] container missing"
  exit 1
fi

state=$(docker inspect -f '{{.State.Status}}' "$CONTAINER")
if [[ "$state" != "running" ]]; then
  echo "[console] state=${state}"
  exit 1
fi

for url in "${URLS[@]}"; do
  echo "[console] probe ${url}"
  curl --fail --silent --show-error --max-time 10 "$url" >/dev/null
done

echo "[console] ready"
