#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend backup preflight\n'
printf 'host=%s\n' "$(hostname)"

command -v docker >/dev/null || { echo 'docker missing'; exit 1; }

docker ps --format '{{.Names}}\t{{.Status}}' | sed -n '1,20p'

if docker ps --format '{{.Names}}' | grep -qx 'openvend-api'; then
  echo 'api container detected'
else
  echo 'warning: openvend-api container not detected'
fi
