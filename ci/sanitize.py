#!/usr/bin/env python3
"""Sanitize cutover rehearsal reports for public publication.

Reads raw cutover-*.json + verdicts.env from --in, writes sanitized
JSON + summary.json + summary.md to --out.

Two layers of defense:

1. ALLOWLIST — only explicitly permitted report fields survive, and
   the raw traffic `timeline` is NEVER published: it is unbounded in
   size, would bloat git history forever, and widens the public
   information surface. Bounded aggregates (slow_requests,
   failures_outside_windows) are capped; full timelines stay in the
   ephemeral runner workspace / private diagnostics only.
2. SECRET SCAN — the final serialized output is grepped for
   forbidden header names, token values/prefixes, env-var names and
   private key material. ANY hit fails the process BEFORE anything
   is pushed; only the RULE NAME is printed, never the match.
"""
import argparse
import json
import re
import sys
import time
from pathlib import Path

# top-level report keys that may be published — an exact field
# allowlist; anything not listed is dropped (timeline included).
ALLOWED = {
    "mode", "legs",
    "counters", "backend_counts", "errors", "slow_requests",
    "switch_window_transport_events", "failures_outside_windows",
    "cross_boundary_request_count",
    "inflight_stall_max_s", "inflight_stall_p95_s",
    "fresh_connection_outage_s",
    "write_overlap_forward", "write_overlap_rollback",
    "media_delta_vs_upload200", "integrity_after",
    "gate_failure", "production_fingerprint_diff",
    "run_media_rows", "run_media_distinct",
}

# bounded list fields — cap entries so public artifacts stay small
BOUNDED = {"errors": 50, "slow_requests": 50,
           "failures_outside_windows": 50}

# forbidden literals — scanned on the FINAL serialized artifacts,
# not just the raw input, so nothing can slip through a transform
FORBIDDEN = [
    "Authorization", "Bearer", "Cookie", "Set-Cookie",
    "X-Device-Key", "X-Oss-Security-Token", "X-Device-Id",
    "DEVICE_CREDENTIAL_SECRET", "OPENVEND_READ_TOKEN",
    "OPENVEND_READ_DEPLOY_KEY", "ADMIN_TOKEN", "GITHUB_TOKEN",
    "BEGIN PRIVATE KEY", "BEGIN RSA PRIVATE KEY", "BEGIN OPENSSH",
    "bootstrap_key", "rehearsal-admin-token",
    "rehearsal-device-secret", "mqtt_generation",
]

# forbidden patterns — named so a hit reports the RULE, never the
# matched secret material
FORBIDDEN_RE = re.compile(
    r"(?P<pem_private_key>-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----)"
    r"|(?P<openssh_private_key>-----BEGIN OPENSSH PRIVATE KEY-----)"
    r"|(?P<github_pat>github_pat_[A-Za-z0-9_]{20,})"
    r"|(?P<ghp_token>ghp_[A-Za-z0-9]{20,})"
    r"|(?P<ghs_token>ghs_[A-Za-z0-9]{20,})"
    r"|(?P<gho_token>gho_[A-Za-z0-9]{20,})"
    r"|(?P<ghu_token>ghu_[A-Za-z0-9]{20,})"
    r"|(?P<ghr_token>ghr_[A-Za-z0-9]{20,})"
    r"|(?P<aws_access_key>AKIA[0-9A-Z]{16})"
    r"|(?P<ssh_private_blob>ssh-ed25519 AAAAC3|ssh-rsa AAAAB3)")


def _strip_exc_args(s):
    """'bucket: RemoteDisconnected('Remote end closed ...')' keeps the
    label + exception CLASS, drops the argument payload."""
    if isinstance(s, str) and "(" in s:
        return s.split("(", 1)[0]
    return s


def sanitize_report(raw):
    out = {k: raw[k] for k in raw if k in ALLOWED}
    for key, cap in BOUNDED.items():
        if isinstance(out.get(key), list):
            out[key] = out[key][:cap]
    out["errors"] = [_strip_exc_args(e)
                     for e in out.get("errors", [])]
    gf = out.get("gate_failure")
    if isinstance(gf, dict):
        gf = dict(gf)
        gf["failures"] = [_strip_exc_args(f)
                          for f in gf.get("failures", [])][:20]
        out["gate_failure"] = gf
    return out


def scan(path):
    text = path.read_text(encoding="utf-8", errors="replace")
    hits = [t for t in FORBIDDEN if t in text]
    for m in FORBIDDEN_RE.finditer(text):
        hits.append(m.lastgroup)
    return sorted(set(hits))


def run_row(name, rep):
    legs = {l["leg"]: l for l in rep.get("legs", [])}
    fo = rep.get("fresh_connection_outage_s") or {}
    wo_f = rep.get("write_overlap_forward") or {}
    wo_r = rep.get("write_overlap_rollback") or {}
    c = rep.get("counters") or {}
    return {
        "run": name,
        "outage_f": fo.get("forward", legs.get("forward", {}).get(
            "outage_s")),
        "outage_r": fo.get("rollback", legs.get("rollback", {}).get(
            "outage_s")),
        "stall_max": rep.get("inflight_stall_max_s"),
        "stall_p95": rep.get("inflight_stall_p95_s"),
        "cross": rep.get("cross_boundary_request_count"),
        "transport_events": rep.get("switch_window_transport_events"),
        "wo_f": wo_f.get("write_overlap_s"),
        "wo_r": wo_r.get("write_overlap_s")
        if isinstance(wo_r, dict) else wo_r,
        "uploads": c.get("upload.200"),
        "media_rows": rep.get("run_media_rows"),
        "media_distinct": rep.get("run_media_distinct"),
        "integrity": rep.get("integrity_after"),
        "gate_failure": rep.get("gate_failure"),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--in", dest="indir", required=True)
    ap.add_argument("--out", dest="outdir", required=True)
    ap.add_argument("--source-sha", required=True)
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--run-url", required=True)
    args = ap.parse_args()

    indir, outdir = Path(args.indir), Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    verdicts = {}
    vf = indir / "verdicts.env"
    if vf.exists():
        for line in vf.read_text().splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                verdicts[k.strip()] = v.strip()

    reports = {}
    for f in sorted(indir.glob("cutover-*.json")):
        name = f.stem.replace("cutover-", "")
        reports[name] = sanitize_report(json.loads(f.read_text()))
        (outdir / f.name).write_text(
            json.dumps(reports[name], indent=1, sort_keys=True))

    rows = {n: run_row(n, r) for n, r in reports.items()}
    overall = "PASS" if reports and all(
        v == "0" for v in verdicts.values()) else "FAIL"

    summary = {
        "source_sha": args.source_sha,
        "run_id": args.run_id,
        "run_url": args.run_url,
        "generated_at": int(time.time()),
        "verdict": overall,
        "verdicts": verdicts,
        "runs": rows,
    }
    (outdir / "summary.json").write_text(
        json.dumps(summary, indent=1, sort_keys=True))

    md = [
        "## Rehearsal — %s" % overall,
        "",
        "source `%s` · [run %s](%s)" % (
            args.source_sha[:12], args.run_id, args.run_url),
        "",
        "| run | verdict | fresh-conn outage f/r | inflight stall "
        "max/p95 | x-boundary | transport ev | write-overlap f/r | "
        "uploads | media rows/distinct | db |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for name, r in rows.items():
        md.append(
            "| %s | %s | %s / %s | %s / %s | %s | %s | %s / %s | %s | "
            "%s/%s | %s |" % (
                name, verdicts.get(name, "?"),
                r["outage_f"], r["outage_r"],
                r["stall_max"], r["stall_p95"], r["cross"],
                r["transport_events"], r["wo_f"], r["wo_r"],
                r["uploads"], r["media_rows"], r["media_distinct"],
                "ok" if r["integrity"] else "FAIL"))
        if r["gate_failure"]:
            g = r["gate_failure"]
            md.append(
                "| ↳ gate @%s → rollback %s recovered=%s |"
                "||||||||||" % (
                    g.get("leg"), g.get("auto_rollback_to"),
                    g.get("rollback_recovered")))
    for name, code in verdicts.items():
        if name not in rows:
            md.append("| %s | %s | (no report) |||||||||"
                      % (name, code))
    md += ["", "_sanitized by ci/sanitize.py — allowlisted fields "
               "only, no raw timeline, secret-scanned before "
               "publication_"]
    (outdir / "summary.md").write_text("\n".join(md) + "\n")

    # secret gate — scan EVERYTHING that would be published
    bad = []
    for f in sorted(outdir.glob("*.json")) + [outdir / "summary.md"]:
        hits = scan(f)
        if hits:
            bad.append((f.name, hits))
    if bad:
        for name, hits in bad:
            print("SANITIZER BLOCKED %s — rules: %s" % (name, hits),
                  file=sys.stderr)
        sys.exit(1)
    print("sanitized %d reports, verdict=%s" % (len(reports), overall))


if __name__ == "__main__":
    main()
