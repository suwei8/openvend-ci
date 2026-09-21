#!/usr/bin/env bash
set -euo pipefail

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/tmp/openvend-health-summary.md}"

section() {
  local title="$1"
  echo "## ${title}" | tee -a "$SUMMARY_FILE"
}

run_cmd() {
  echo '```' | tee -a "$SUMMARY_FILE"
  "$@" 2>&1 | tee -a "$SUMMARY_FILE" || true
  echo '```' | tee -a "$SUMMARY_FILE"
}

: > "$SUMMARY_FILE"

printf '# OpenVend OCI Health Report\n' | tee -a "$SUMMARY_FILE"
printf 'Generated: %s\n\n' "$(date -u)" | tee -a "$SUMMARY_FILE"

echo "Starting readonly health check..."

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

echo "Readonly health report completed." | tee -a "$SUMMARY_FILE"
