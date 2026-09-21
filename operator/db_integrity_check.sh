#!/usr/bin/env bash
set -euo pipefail

printf 'OpenVend database integrity check\n'

if ! docker ps --format '{{.Names}}' | grep -qx 'openvend-api'; then
  echo 'openvend-api container not running'
  exit 1
fi

docker exec openvend-api python - <<'PY'
import sqlite3
import sys

paths = ['/app/data/openvend.db', '/data/openvend.db']
for path in paths:
    try:
        db = sqlite3.connect(path)
        result = db.execute('PRAGMA integrity_check').fetchone()[0]
        print(path, result)
        if result != 'ok':
            sys.exit(1)
        break
    except Exception:
        continue
else:
    print('database path not found')
    sys.exit(1)
PY
