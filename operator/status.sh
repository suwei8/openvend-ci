#!/usr/bin/env bash
set -euo pipefail

echo '=== system ==='
systemctl --failed --no-pager || true

echo '=== docker ==='
docker ps --format '{{.Names}}\t{{.Status}}' || true
