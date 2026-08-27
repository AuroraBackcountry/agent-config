#!/usr/bin/env bash
# vault-daily.sh: once-daily commit + push of the vault (the Knowledge layer's
# backup). Replaces session-end.sh's per-session snapshot, which committed two
# append-only log files ~56x/day and grew ~/Vault/.git to 84 MB in a month.
# Installed as a launchd agent by install.sh — launchd (not cron) because a
# schedule missed while the laptop sleeps runs on the next wake; cron skips it.
# Best-effort and offline-safe: a failed push is retried by the next run, since
# push sends everything unpushed. Always exits 0; one log line per run in
# ~/.cache/vault-daily.log is the evidence it ran.

vault="${VAULT_DIR:-$HOME/Vault}"
log="$HOME/.cache/vault-daily.log"
mkdir -p "$HOME/.cache" 2>/dev/null || true

[ -e "$vault/.git" ] || exit 0
cd "$vault" || exit 0

git add -A >/dev/null 2>&1
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -qm "vault snapshot $(date '+%Y-%m-%d')" >/dev/null 2>&1
fi

status=no-remote
if git remote get-url origin >/dev/null 2>&1; then
  if git push -q origin HEAD >/dev/null 2>&1; then status=pushed; else status=push-failed; fi
fi

printf '%s %s HEAD=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$status" \
  "$(git rev-parse --short HEAD 2>/dev/null)" >> "$log" 2>/dev/null || true
exit 0
