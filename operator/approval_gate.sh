#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-cutover-approved.json}"
SHA="${OPENVEND_APPROVED_SHA:?OPENVEND_APPROVED_SHA required}"

cat > "$OUT" <<EOF
{
  "approved_sha": "$SHA",
  "runner": "$(hostname)",
  "approved_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "gate": "manual-approval"
}
EOF

echo "approval artifact: $OUT"
