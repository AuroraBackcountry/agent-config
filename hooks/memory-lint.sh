#!/usr/bin/env bash
# memory-lint.sh <repo-dir>: the doctor pass's mechanical checks, cheap enough for every
# session start. Prints one line per finding and exits 1 if any; silent, exit 0 when clean.
#   - STATUS.md and the status docs it names against the STATUS rule (hooks/status-lint.sh)
#   - in repos I own: CLAUDE.md a full copy of AGENTS.md (should be the one line `@AGENTS.md`),
#     and AGENTS.md over 300 lines or 30 KB (area detail belongs in .claude/rules/)
#   - the vault MOC holding build state: PR numbers or ids (it is an index)
#   - auto-memory recording a STATUS-only PR ("STATUS #440"), over its 64 KB budget, or holding
#     one trap in two files
#   - in repos I own: scripts/status-lint.sh (the CI copy) differing from hooks/status-lint.sh
# Each finding names its one fix and where it lands; a warning with no fix path is not added.
# The judgment checks (stale sections, find-replace corruption) stay in memory-checkpoint's
# doctor pass; a finding here is the cue to run it. Checked by tests/memory-lint.test.sh.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(git -C "${1:-$PWD}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$repo" ] || exit 0
vault="${VAULT_DIR:-$HOME/Vault}"
memroot="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
budget="${MEMORY_BUDGET_KB:-64}"
found=0
say() { printf '%s\n' "$1"; found=1; }

bash "$here/status-lint.sh" "$repo" && : || found=1

# A guest repo's files are the owners' to fix, never mine (hooks/owned.sh).
owned=0; bash "$here/owned.sh" "$repo" && owned=1

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
copy="$repo/scripts/status-lint.sh"
if [ "$owned" = 1 ] && [ -f "$copy" ] && ! cmp -s "$copy" "$here/status-lint.sh"; then
  say "scripts/status-lint.sh: differs from $here/status-lint.sh (copy it over on the next working branch)"
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
  # One budget for the folder, not per file: a per-file limit is passed by splitting the file.
  kb=$(( $(cat "$mem"/*.md 2>/dev/null | wc -c) / 1024 ))
  [ "$kb" -gt "$budget" ] && say "memory/: $kb KB, over the $budget KB budget (delete each entry a test or hook now enforces, or whose tool, file or code is gone; never archive by age)"
  # One trap, one file: the same bold bullet headline (case, punctuation and "(dates)" aside, 3+ words) in two files.
  dup="$(for f in "$mem"/*.md; do
      grep -oE '^- \*\*[^*]+\*\*' "$f" | tr 'A-Z' 'a-z' | sed -E 's/\([^)]*\)//g; s/[^a-z0-9]+/ /g; s/^ +| +$//g' \
        | awk 'NF >= 3' | sort -u | sed "s|^|$(basename "$f")	|"
    done 2>/dev/null | awk -F'\t' '{ n[$2]++; w[$2] = w[$2] " " $1 } n[$2] == 2 { print "\"" $2 "\" in" w[$2]; exit }')"
  [ -n "$dup" ] && say "memory/: one trap in two files: $dup (keep it in one file, delete the other copy)"
fi

exit "$found"
