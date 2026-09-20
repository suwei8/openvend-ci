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
- Third-party actions are pinned to immutable commit SHAs
  (`actions/checkout` v4.4.0, `actions/setup-python` v5.6.0) — no
  floating major tags, since this workflow handles a private-source
  credential.
- No `actions/upload-artifact` anywhere — report retention uses the
  `reports` orphan branch instead of Artifact Storage.
- Public reports carry **no raw traffic timeline** — bounded
  aggregates only, so git history stays small and the public
  information surface stays narrow.

## Public-log trust boundary

GitHub Actions logs on a public repository are **world-readable**.
Because this repo can check out private source, the only permitted
trigger is a human `workflow_dispatch` against an already-reviewed,
trusted exact OpenVend commit SHA. It is therefore forbidden to:

- auto-test arbitrary external PRs or execute fork content,
- run unreviewed / unknown private commits,
- add `pull_request` / `pull_request_target` triggers,
- let any public event carry the private-checkout credential.

If a run ever prints unexpected content, treat the log as public
disclosure and rotate `OPENVEND_READ_DEPLOY_KEY`.
