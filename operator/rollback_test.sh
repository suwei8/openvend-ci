#!/usr/bin/env bash
set -euo pipefail

cat <<'PLAN'
ROLLBACK TEST CHECKLIST

1. stop target runtime
2. restore previous nginx candidate
3. start legacy runtime
4. wait authenticated internal health
5. reload nginx
6. verify external endpoints
7. verify single writer condition

This operator currently validates the rollback path contract only.
PLAN
