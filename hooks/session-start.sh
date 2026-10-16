#!/usr/bin/env bash
# session-start.sh: runs at every Claude Code start.
# 1. Re-bakes a stale ~/.claude/CLAUDE.md (closes the ff-pull hole: post-commit fires
#    only on local commits, so a pull of commits made elsewhere leaves the global stale).
# 2. Prints one line per recent failure. A SessionStart hook's stdout reaches the
#    session, so a failed vault push or self-heal is seen the same day instead of
#    sitting in a log nobody reads (the 2026-10-14 push-failed went unnoticed).
# 3. Runs the doctor pass's mechanical checks on the session repo (hooks/memory-lint.sh:
#    STATUS rule, CLAUDE.md copies, AGENTS.md size, vault MOC state, merge records) and
#    prints one line if anything is off; the judgment checks stay in memory-checkpoint.
# Silent when healthy. Always exits 0. Checked by tests/session-start.test.sh.

AGENTS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sync="${SESSION_START_SYNC:-$AGENTS_HOME/sync.sh}"
heal_log="${SYNC_HEAL_LOG:-$HOME/.cache/sync-heal.log}"
vault_log="${VAULT_DAILY_LOG:-$HOME/.cache/vault-daily.log}"
dir="${SESSION_START_DIR:-$PWD}"

bash "$sync" --check >/dev/null 2>&1 || bash "$sync" >/dev/null 2>&1 \
  || printf '%s self-heal failed — run sync.sh in a terminal\n' "$(date '+%F %T')" >> "$heal_log" 2>/dev/null

warn() { printf 'Agent kit warning (tell the user): %s\n' "$1"; }

if [ -f "$vault_log" ]; then
  last="$(tail -n 1 "$vault_log")"
  case "$last" in
    *" pushed HEAD="*) ;;
    *) warn "the last vault backup did not push: \"$last\" (log: $vault_log)" ;;
  esac
  [ -n "$(find "$vault_log" -mtime +2 2>/dev/null)" ] && warn "no vault backup has run for over 2 days (log: $vault_log)"
fi

[ -n "$(find "$heal_log" -mtime -7 2>/dev/null)" ] && warn "rules self-heal failed in the last 7 days: \"$(tail -n 1 "$heal_log")\" — run $AGENTS_HOME/sync.sh in a terminal"

top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
if [ -n "$top" ]; then
  breaks="$(bash "$AGENTS_HOME/hooks/memory-lint.sh" "$top" 2>/dev/null)"
  if [ -n "$breaks" ]; then
    warn "memory files for $top break the rules in $(printf '%s\n' "$breaks" | wc -l | tr -d ' ') place(s), first: $(printf '%s\n' "$breaks" | head -n 1). Offer memory-checkpoint's doctor pass; repo fixes ride the next working branch, never a PR of their own. Full list: bash $AGENTS_HOME/hooks/memory-lint.sh $top"
  fi
fi

exit 0
