#!/usr/bin/env bash
# session-end.sh: append a lightweight breadcrumb when a Claude Code session ends.
# Pure shell, no dependencies, non-blocking. Real summaries come from /save.
# Claude Code passes JSON on stdin (ignored here).

vault="${VAULT_DIR:-$HOME/Vault}"
logdir="$vault/logs"
mkdir -p "$logdir" 2>/dev/null || exit 0

ts="$(date '+%Y-%m-%d %H:%M:%S')"
cwd="$PWD"
project="$(basename "$cwd")"
branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

printf '%s | %s | branch=%s | %s\n' "$ts" "$project" "$branch" "$cwd" \
  >> "$logdir/_sessions.log" 2>/dev/null || true
exit 0
