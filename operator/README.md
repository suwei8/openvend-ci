# OpenVend OCI Operator

## Current phase

Phase 7-7.1.2: readonly OCI health reporting.

The first capability intentionally performs no mutation:

- no restart
- no compose changes
- no nginx reload
- no database writes

## Evolution

```
Health Report
      |
      v
Backup Verify
      |
      v
Cutover Preflight
      |
      v
Deployment Actions
```

All mutation capabilities require explicit later design and approval.
