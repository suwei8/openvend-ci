#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend OCI compose status\n'

if ! command -v docker >/dev/null 2>&1; then
  echo 'docker=missing'
  exit 1
fi

if docker compose version >/dev/null 2>&1; then
  docker compose ps || true
else
  echo 'docker_compose=missing'
fi
