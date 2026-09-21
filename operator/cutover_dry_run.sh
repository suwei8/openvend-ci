#!/usr/bin/env bash
set -euo pipefail

cat <<'PLAN'
CUTOVER DRY RUN

1. validate candidate nginx configuration
2. stop legacy runtime
3. assert legacy stopped
4. start FastAPI runtime
5. wait internal health gate
6. reload nginx
7. verify external health gate
8. verify database writer integrity

No production mutation executed.
PLAN
