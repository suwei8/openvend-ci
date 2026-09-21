#!/usr/bin/env bash
set -euo pipefail

fail() { echo "FAIL: $*" >&2; exit 1; }

ROOT=${OPENVEND_ROOT:-/opt/openvend}

command -v docker >/dev/null || fail "docker unavailable"

echo "== cutover preflight =="

echo "[1] docker"
docker info >/dev/null 2>&1 || fail "docker daemon unavailable"

echo "[2] compose"
cd "$ROOT" 2>/dev/null || fail "openvend root missing: $ROOT"
docker compose config >/dev/null || fail "compose config invalid"

echo "[3] git freeze"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git status --porcelain | grep -q . && fail "working tree dirty"
  echo "HEAD=$(git rev-parse HEAD)"
fi

echo "[4] containers"
docker compose ps || true

echo "[5] nginx"
docker ps --format '{{.Names}}' | grep -q nginx || fail "nginx container missing"

echo "[6] database containers"
for c in openvend-api openvend-fastapi; do
  if docker ps --format '{{.Names}}' | grep -qx "$c"; then
    echo "$c present"
  fi
done

echo "PASS: cutover preflight checks completed"
