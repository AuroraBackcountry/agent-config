#!/usr/bin/env bash
# memory-lint.sh <repo-dir>: the doctor pass's mechanical checks, cheap enough for every
# session start. Prints one line per finding and exits 1 if any; silent, exit 0 when clean.
#   - STATUS.md against the STATUS rule (hooks/status-lint.sh)
#   - in repos I own: CLAUDE.md a full copy of AGENTS.md (should be the one line `@AGENTS.md`),
#     and AGENTS.md over 300 lines or 30 KB (area detail belongs in .claude/rules/)
#   - the vault MOC holding build state: PR numbers or ids (it is an index)
#   - auto-memory recording a STATUS-only PR ("STATUS #440")
# The judgment checks (stale sections, find-replace corruption) stay in memory-checkpoint's
# doctor pass; a finding here is the cue to run it. Checked by tests/memory-lint.test.sh.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$repo" ] || exit 0
vault="${VAULT_DIR:-$HOME/Vault}"
memroot="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
found=0
say() { printf '%s\n' "$1"; found=1; }

bash "$here/status-lint.sh" "$repo" && : || found=1

# Owned = origin owned by one of OWNED_GH_OWNERS, or no origin. A guest repo's files are the
# owners' to fix, never mine (shortcut: a fixed owner list; a new org must be added here).
owners="${OWNED_GH_OWNERS:-AuroraBackcountry Aurora-Backcountry}"
origin="$(git -C "$repo" remote get-url origin 2>/dev/null)"
owner="$(printf '%s' "$origin" | sed -E 's#^(https://[^/]+/|git@[^:]+:)([^/]+)/.*#\2#')"
owned=0; { [ -z "$origin" ] || [[ " $owners " == *" $owner "* ]]; } && owned=1

a="$repo/AGENTS.md"; c="$repo/CLAUDE.md"
if [ "$owned" = 1 ] && [ -f "$a" ] && [ -f "$c" ] && [ ! -L "$c" ] && [ ! -L "$a" ] && cmp -s "$a" "$c"; then
  say "CLAUDE.md: a full copy of AGENTS.md (make it the one line @AGENTS.md)"
fi
if [ "$owned" = 1 ] && [ -f "$a" ] && [ ! -L "$a" ]; then
  lines=$(wc -l < "$a" | tr -d ' '); bytes=$(wc -c < "$a" | tr -d ' ')
  if [ "$lines" -gt 300 ] || [ "$bytes" -gt 30720 ]; then
    say "AGENTS.md: $lines lines, $((bytes / 1024)) KB, over 300 lines or 30 KB (move area detail to .claude/rules/)"
  fi
fi

# Project key: the main repo's directory name (worktrees file under their parent); one alias.
main="$(dirname "$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)")"
key="$(basename "$main")"; [ "$key" = ".agents" ] && key="agent-config"
moc="$vault/projects/$key/README.md"
if [ -f "$moc" ]; then
  grep -n -E '(^|[[:space:](])#[0-9]{2,5}\b|`[0-9a-f]{7,12}`' "$moc" | head -n 1 | sed 's/^\([0-9]*\):.*/vault MOC:\1: a PR number or id (the MOC is an index)/' | grep . && found=1
fi

mem="$memroot/$(printf '%s' "$main" | sed 's/[^A-Za-z0-9]/-/g')/memory"
if [ -d "$mem" ]; then
  hit="$(grep -l -E 'STATUS (PR )?#[0-9]{2,}' "$mem"/*.md 2>/dev/null | head -n 1)"
  [ -n "$hit" ] && say "memory/$(basename "$hit"): records a STATUS-only PR (git holds merges)"
fi

exit "$found"
