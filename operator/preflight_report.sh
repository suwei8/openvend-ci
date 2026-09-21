#!/usr/bin/env bash
set -euo pipefail

fail(){ echo "FAIL: $*"; exit 1; }

command -v docker >/dev/null || fail 'docker missing'
docker info >/dev/null || fail 'docker unavailable'

echo "PASS docker"

git rev-parse HEAD 2>/dev/null || true
git status --porcelain 2>/dev/null || true

docker compose config >/dev/null 2>&1 && echo 'PASS compose' || echo 'SKIP compose'

echo 'preflight complete'
