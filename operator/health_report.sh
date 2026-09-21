#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend OCI Operator health report\n'
printf 'host=%s\n' "$(hostname)"
printf 'time=%s\n' "$(date -u +%FT%TZ)"

if command -v docker >/dev/null 2>&1; then
  docker ps --format '{{.Names}}\t{{.Status}}' || true
fi
