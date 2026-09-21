#!/usr/bin/env bash
set -euo pipefail

echo '== runtime snapshot =='
date -u
hostname

echo '-- docker containers --'
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

echo '-- compose services --'
docker compose ps || true

echo '-- disk --'
df -h
