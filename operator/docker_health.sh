#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend OCI docker health\n'

command -v docker >/dev/null 2>&1 || {
  echo 'docker=missing'
  exit 1
}

docker info --format 'docker_server={{.ServerVersion}}' || true
docker ps --format '{{.Names}}\t{{.Status}}'
