#!/usr/bin/env bash
# One runnable check for hooks/session-end.sh — the things that were actually
# broken: worktree project identity, non-repo noise (58% of breadcrumbs were
# home-directory sessions before the gate), concurrent-append interleaving, and
# the per-session vault git snapshot (moved to vault-daily.sh after it grew
# ~/Vault/.git to 84 MB in a month). No framework, no fixtures: run it, non-zero
# exit means a regression.
#
#   bash tests/session-end.test.sh
set -uo pipefail

HOOK="${SESSION_END_HOOK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/session-end.sh}"  # override to test an old copy
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }
count() { local n=0; [ -f "$2" ] && n="$(grep -cF "$1" "$2")"; printf '%s' "$n"; }

# feed the hook the same JSON Claude Code does
run() { # run <vault> <cwd>
  printf '{"cwd":"%s","reason":"test","transcript_path":"/nonexistent/t.jsonl"}' "$2" \
    | VAULT_DIR="$1" bash "$HOOK"
}
traces_of() { printf '%s/logs/_traces-%s.md' "$1" "$(date +%Y-%m)"; }

# a real repo with a worktree under .claude/worktrees, like Claude Code creates
repo="$tmp/myproject"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init
wt="$repo/.claude/worktrees/loving-swirles-231c69"
git -C "$repo" worktree add -q --detach "$wt" HEAD

echo "1. a worktree session files under the main repo, not the worktree"
v="$tmp/v1"; run "$v" "$wt"
check "trace header names the repo"      "$(count ' myproject (branch' "$(traces_of "$v")")" 1
check "worktree name is not the project" "$(count ' loving-swirles-231c69 (branch' "$(traces_of "$v")")" 0
check "breadcrumb names the repo"        "$(count '| myproject | ' "$v/logs/_sessions.log")" 1

echo "2. a session outside a repo writes nothing at all"
v="$tmp/v2"; notrepo="$tmp/not-a-repo-xyz"; mkdir -p "$notrepo"
if git -C "$notrepo" rev-parse --git-dir >/dev/null 2>&1; then
  fail "precondition: \$TMPDIR is inside a git repo, cannot test the non-repo path"
else
  run "$v" "$notrepo"
  check "no trace entry"       "$(count 'not-a-repo-xyz' "$(traces_of "$v")")" 0
  check "no breadcrumb either" "$(count 'not-a-repo-xyz' "$v/logs/_sessions.log")" 0
  check "no vault dir created" "$([ -e "$v" ] && echo yes || echo no)" no
fi

echo "3. concurrent session ends do not splice each other's fields"
v="$tmp/v3"; n=20
for _ in $(seq "$n"); do run "$v" "$repo" & done
wait
t="$(traces_of "$v")"
check "all $n entries present" "$(grep -c '^## ' "$t")" "$n"
# every entry must carry exactly one of each field; an interleaved write lands a
# second transcript/ended line inside a neighbour's block
check "no entry has a spliced field" "$(awk '
  /^## /            { if (h++ && (c!=1 || e!=1 || r!=1)) bad++; c=0; e=0; r=0; next }
  /^- cwd: /        { c++ }
  /^- ended: /      { e++ }
  /^- transcript: / { r++ }
  END               { if (h && (c!=1 || e!=1 || r!=1)) bad++; print bad+0 }
' "$t")" 0

echo "4. the hook never commits the vault (vault-daily.sh owns that now)"
v="$tmp/v4"; mkdir -p "$v"
git -C "$v" init -q
git -C "$v" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init
run "$v" "$repo"
check "log files written"        "$(count '| myproject | ' "$v/logs/_sessions.log")" 1
check "but no commit made"       "$(git -C "$v" rev-list --count HEAD)" 1
check "logs left uncommitted"    "$([ -n "$(git -C "$v" status --porcelain)" ] && echo dirty || echo clean)" dirty

echo
if [ "$fails" -eq 0 ]; then echo "session-end.sh: all checks passed"; else echo "session-end.sh: $fails check(s) failed"; fi
exit "$fails"
