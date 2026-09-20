# openvend-ci

This repository contains CI orchestration and sanitized test reports
only. Product source remains private.

## What lives here

- `.github/workflows/` — dispatch-only rehearsal workflows that
  check out a private `suwei8/openvend` commit on a standard hosted
  runner and execute the isolated Docker + nginx rehearsal suite.
- `ci/` — the report sanitizer (allowlist fields + secret scan) and
  summary generator.
- `reports` (orphan branch) — sanitized JSON rehearsal reports,
  laid out as `reports/<source-sha>/<run-id>/`.

## Trust model

- The private source is read via a **read-only deploy key**
  (`OPENVEND_READ_DEPLOY_KEY` secret) — git-read on `suwei8/openvend`
  only, zero API capability, narrower than a PAT.
- Reports are pushed by this repo's own `GITHUB_TOKEN`
  (`contents: write` on this repo only). The private checkout uses
  `persist-credentials: false` — no credential can leak into later
  git operations.
- Workflows run on `workflow_dispatch` input only, pinned to a full
  40-hex `source_sha` (floating refs are rejected).
- No `actions/upload-artifact` anywhere — report retention uses the
  `reports` orphan branch instead of Artifact Storage.
