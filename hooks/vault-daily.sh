#!/usr/bin/env bash
# vault-daily.sh: once-daily commit + push of the vault (the Knowledge layer's
# backup). Replaces session-end.sh's per-session snapshot, which committed two
# append-only log files ~56x/day and grew ~/Vault/.git to 84 MB in a month.
# Installed as a launchd agent by install.sh: StartCalendarInterval 17:00 plus
# RunAtLoad, so a machine that was powered off at 17:00 catches up at next
# login (launchd replays a slot missed during sleep, never one missed while
# shut down).
# EVERY run writes one status line to the log — including no-vault and cd
# failure — so a moved vault is distinguishable from the agent not firing.
# Always exits 0. Pure-logic paths checked by tests/vault-daily.test.sh.
# ponytail: the push itself is untested (a real check needs a remote — mocking
# one is fixture machinery this script doesn't earn) and fetch-free: a commit
# reaching origin from anywhere else wedges every later push non-fast-forward
# until a manual pull, visible here as push-failed. Single-writer vault by
# design; upgrade path: pull --rebase before push.
# ponytail: under launchd a shell-profile VAULT_DIR never arrives — the job
# always backs up ~/Vault. If the vault moves, the no-vault log line is what
# surfaces the mismatch; fix by editing the default here or the plist.

vault="${VAULT_DIR:-$HOME/Vault}"
log="${VAULT_DAILY_LOG:-$HOME/.cache/vault-daily.log}"
mkdir -p "$(dirname "$log")" 2>/dev/null || true
note() { printf '%s %s HEAD=%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" \
  "$(git -C "$vault" rev-parse --short HEAD 2>/dev/null || echo none)" >> "$log" 2>/dev/null || true; }

[ -e "$vault/.git" ] || { note "no-vault ($vault)"; exit 0; }
cd "$vault" || { note "cd-failed ($vault)"; exit 0; }

# Secrets gate: refuse to snapshot or push while any env-named file is TRACKED.
# This catches a FILENAME, not a secret — a key pasted into a decisions note
# sails straight through, so trust this gate exactly as far as a name check
# reaches. It exists because the vault's first push required a history rewrite
# to remove precisely this class of file.
if [ -n "$(git ls-files -- '*.env' '.env*' 2>/dev/null)" ]; then
  note "refused-secrets (a tracked env file; untrack it, then re-run)"
  exit 0
fi

git add -A >/dev/null 2>&1
committed=ok
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -qm "vault snapshot $(date '+%Y-%m-%d')" >/dev/null 2>&1 || committed=commit-FAILED
fi

status=no-remote
if git remote get-url origin >/dev/null 2>&1; then
  if git push -q origin HEAD >/dev/null 2>&1; then status=pushed; else status=push-failed; fi
fi
[ "$committed" = ok ] || status="$committed $status"
note "$status"
exit 0
