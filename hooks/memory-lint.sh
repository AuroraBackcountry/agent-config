#!/usr/bin/env bash
# memory-lint.sh <repo-dir>: the doctor pass's mechanical checks, cheap enough for every
# session start. Prints one line per finding on stdout and exits 1 if any; stdout silent, exit 0
# when clean.
#   - STATUS.md and the status docs it names against the STATUS rule (hooks/status-lint.sh)
#   - in repos I own: CLAUDE.md a full copy of AGENTS.md (should be the one line `@AGENTS.md`),
#     and AGENTS.md over 300 lines or 30 KB (area detail belongs in .claude/rules/)
#   - the vault MOC holding build state: PR numbers or ids (it is an index)
#   - auto-memory recording a STATUS-only PR ("STATUS #440"), a MEMORY.md past what loads each
#     session (200 lines or 25 KB), or one trap in two files; the folder total goes to stderr as
#     information, never a finding
#   - in repos I own: scripts/status-lint.sh (the CI copy) differing from hooks/status-lint.sh
# Each finding names its one fix and where it lands; a warning with no fix path is not added.
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
  # The budget is what loads every session: Claude Code loads the first 200 lines or 25KB of
  # MEMORY.md and drops the rest (code.claude.com/docs/en/memory); 25,000 bytes is the stricter
  # reading. Other memory files load only when read, so their size is information, never a finding.
  idx="$mem/MEMORY.md"
  if [ -f "$idx" ]; then
    lines=$(wc -l < "$idx" | tr -d ' '); bytes=$(wc -c < "$idx" | tr -d ' ')
    if [ "$lines" -gt 200 ] || [ "$bytes" -gt 25000 ]; then
      say "memory/MEMORY.md: $lines lines, $(( (bytes + 999) / 1000 )) KB, past the 200 lines or 25 KB that load each session (one short line per memory; detail goes in its topic file)"
    fi
  fi
  printf 'memory/: %s KB in all (information only; only MEMORY.md loads each session)\n' "$(( $(cat "$mem"/*.md 2>/dev/null | wc -c) / 1024 ))" >&2
  # One trap, one file: the same bold bullet headline (case, punctuation and "(dates)" aside, 3+ words) in two files.
  dup="$(for f in "$mem"/*.md; do
      grep -oE '^- \*\*[^*]+\*\*' "$f" | tr 'A-Z' 'a-z' | sed -E 's/\([^)]*\)//g; s/[^a-z0-9]+/ /g; s/^ +| +$//g' \
        | awk 'NF >= 3' | sort -u | sed "s|^|$(basename "$f")	|"
    done 2>/dev/null | awk -F'\t' '{ n[$2]++; w[$2] = w[$2] " " $1 } n[$2] == 2 { print "\"" $2 "\" in" w[$2]; exit }')"
  [ -n "$dup" ] && say "memory/: one trap in two files: $dup (keep it in one file, delete the other copy)"
fi

exit "$found"
