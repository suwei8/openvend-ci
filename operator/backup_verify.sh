#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend backup verification\n'

BACKUP_DIR="${OPENVEND_BACKUP_DIR:-./backups}"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "backup directory not found: $BACKUP_DIR"
  exit 1
fi

LATEST=$(find "$BACKUP_DIR" -type f \( -name '*.db.gz' -o -name '*.sqlite.gz' \) | sort | tail -n1 || true)

if [ -z "$LATEST" ]; then
  echo 'no compressed database backup found'
  exit 1
fi

sha256sum "$LATEST"
echo "backup=$LATEST"

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

gzip -cd "$LATEST" > "$TMP"
python3 - "$TMP" <<'PY'
import sqlite3
import sys

conn = sqlite3.connect(sys.argv[1])
result = conn.execute('PRAGMA integrity_check').fetchone()[0]
print('integrity_check=', result)
if result != 'ok':
    raise SystemExit(1)
PY
