#!/usr/bin/env bash
# One runnable check for hooks/commit-lint.sh: it reports a new break in the status-doc lines a
# `git commit` changes (plain, -C, -a, add-then-commit), stays silent otherwise, skips guest repos,
# and fails open: every broken input or failing part gives exit 0 and no output. Temp dirs only.
#
#   bash tests/commit-lint.test.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/commit-lint.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }
# payload <command> <cwd>: the JSON Claude Code sends a PreToolUse(Bash) hook
payload() { python3 -c 'import json,sys; print(json.dumps({"hook_event_name": "PreToolUse", "tool_name": "Bash", "cwd": sys.argv[2], "tool_input": {"command": sys.argv[1]}}))' "$1" "$2"; }
run()   { payload "$1" "$2" | bash "$HOOK"; }
ctx()   { run "$1" "$2" | python3 -c 'import json,sys; print(json.load(sys.stdin)["hookSpecificOutput"]["additionalContext"])' 2>/dev/null; }
silent() { local out rc; out="$(bash "$HOOK" 2>&1 <<<"$1")"; rc=$?; check "$2" "$rc:$out" "0:"; }

r="$tmp/repo"; mkdir -p "$r"; git -C "$r" init -q
printf '## Now\n\n- old break (#100)\n- fine\n' > "$r/STATUS.md"
git -C "$r" add -A; git -C "$r" -c user.name=t -c user.email=t@t commit -qm base
printf '## Now\n\n- old break (#100)\n- fine, live on merge\n' > "$r/STATUS.md"

echo "1. a commit that adds a break is reported, as valid JSON for Claude"
check "git commit"          "$(ctx 'git commit -m x' "$r" | grep -c 'STATUS.md:4: branch')" 1
check "git -C dir commit"   "$(ctx "git -C \"$r\" commit -m x" "$tmp" | grep -c 'STATUS.md:4')" 1
check "add, then commit -a" "$(ctx 'git add -A && git commit -a -m "fix: x"' "$r" | grep -c 'STATUS.md:4')" 1
check "git -c k=v commit"   "$(ctx 'git -c user.name=t commit -m x' "$r" | grep -c 'STATUS.md:4')" 1
check "old break not named" "$(ctx 'git commit -m x' "$r" | grep -c 'STATUS.md:3')" 0

echo "2. silent when there is nothing to say"
check "not a commit"     "$(run 'git status' "$r")" ""
check "commit in a word" "$(run 'echo recommit' "$r")" ""
check "no change"        "$(git -C "$r" checkout -q -- STATUS.md; run 'git commit -m x' "$r")" ""
check "clean change"     "$(printf '## Now\n\n- old break (#100)\n- fine and live\n' > "$r/STATUS.md"; run 'git commit -m x' "$r")" ""
g="$tmp/guest"; cp -R "$r" "$g"; git -C "$g" remote add origin https://github.com/someone-else/tool.git
printf -- '- live once merged\n' >> "$g/STATUS.md"
check "guest repo"       "$(run 'git commit -m x' "$g")" ""

echo "3. fails open: exit 0, no output"
printf -- '- live once merged\n' >> "$r/STATUS.md"  # a real break, so only the fault keeps it quiet
silent '{not json, commit'                                   "malformed JSON"
silent ''                                                    "empty input"
silent '{"tool_input": {"command": 7}, "commit": 1}'         "command not a string"
silent "$(payload 'git commit -m x' "$tmp/nowhere")"         "cwd not a repo"
silent "$(payload 'git -C /nope commit -m x' "$r")"          "-C not a repo"
printf 'echo half-written; exit 3\n' > "$tmp/broken-lint.sh"
out="$(payload 'git commit -m x' "$r" | COMMIT_LINT_STATUS="$tmp/broken-lint.sh" bash "$HOOK" 2>&1; echo "rc=$?")"
check "status-lint crashes"  "$out" "rc=0"
printf 'echo "{"; exit 1\n' > "$tmp/garbage-lint.sh"
out="$(payload 'git commit -m x' "$r" | COMMIT_LINT_STATUS="$tmp/garbage-lint.sh" bash "$HOOK" | python3 -c 'import json,sys; json.load(sys.stdin); print("json")' 2>&1)"
check "lint output is quoted, never raw" "$out" "json"
mkdir -p "$tmp/bin"; for t in bash cat git dirname sed; do ln -sf "$(command -v "$t")" "$tmp/bin/$t"; done
out="$(payload 'git commit -m x' "$r" | PATH="$tmp/bin" "$tmp/bin/bash" "$HOOK" 2>&1; echo "rc=$?")"
check "no python3"           "$out" "rc=0"
check "the real lint still reports" "$(ctx 'git commit -m x' "$r" | grep -c 'STATUS.md:5')" 1

echo
if [ "$fails" -eq 0 ]; then echo "commit-lint.sh: all checks passed"; else echo "commit-lint.sh: $fails check(s) failed"; fi
exit "$fails"
