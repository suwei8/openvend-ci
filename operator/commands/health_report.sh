#!/usr/bin/env bash
set -euo pipefail

section() {
  echo "## $1" >> "$GITHUB_STEP_SUMMARY"
}

run_cmd() {
  echo '```' >> "$GITHUB_STEP_SUMMARY"
  "$@" >> "$GITHUB_STEP_SUMMARY" 2>&1 || true
  echo '```' >> "$GITHUB_STEP_SUMMARY"
}

: > "$GITHUB_STEP_SUMMARY"

echo "# OpenVend OCI Health Report" >> "$GITHUB_STEP_SUMMARY"
echo "Generated: $(date -u)" >> "$GITHUB_STEP_SUMMARY"

section "Host"
run_cmd hostname
run_cmd uname -a
run_cmd uptime

section "Resources"
run_cmd df -h
run_cmd free -m

section "Docker"
run_cmd docker version --format '{{.Server.Version}}'
run_cmd docker ps
run_cmd docker compose ls

section "Runtime Ports"
run_cmd bash -c 'ss -tlnp || true'

echo "\nReadonly health report completed." >> "$GITHUB_STEP_SUMMARY"
