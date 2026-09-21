#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend OCI nginx check\n'

if command -v docker >/dev/null 2>&1; then
  docker ps --format '{{.Names}}' | grep -i nginx || true
fi

if command -v nginx >/dev/null 2>&1; then
  nginx -t || true
else
  echo 'host_nginx=not_installed'
fi
