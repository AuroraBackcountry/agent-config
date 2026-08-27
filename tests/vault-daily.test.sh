#!/usr/bin/env bash
# One runnable check for hooks/vault-daily.sh — the pure-logic paths: every
# exit writes a status line, the commit-failure branch is reported, the
# secrets gate refuses tracked env files, and a quiet day commits nothing.
# ponytail: the push path is deliberately untested — a real check needs a
# remote, and standing up a fake one is fixture machinery this script doesn't
# earn. All fixtures here are temp dirs with no remote (status: no-remote).
#
#   bash tests/vault-daily.test.sh
set -uo pipefail

HOOK="${VAULT_DAILY_HOOK:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/vault-daily.sh}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }

run() { VAULT_DIR="$1" VAULT_DAILY_LOG="$2" bash "$HOOK"; }
mkvault() { mkdir -p "$1"; git -C "$1" init -q; git -C "$1" -c user.email=t@example.com -c user.name=t commit -q --allow-empty -m init; }

echo "1. a missing vault still leaves a status line"
log="$tmp/log1"; run "$tmp/nope" "$log"
check "exit and log line"   "$(grep -c 'no-vault' "$log")" 1

echo "2. a change is committed and reported (no remote)"
v="$tmp/v2"; log="$tmp/log2"; mkvault "$v"; echo hi > "$v/note.md"
run "$v" "$log"
check "commit landed"       "$(git -C "$v" rev-list --count HEAD)" 2
check "status no-remote"    "$(grep -c ' no-remote ' "$log")" 1

echo "3. a failed commit is reported, not logged as success"
v="$tmp/v3"; log="$tmp/log3"; mkvault "$v"; echo hi > "$v/note.md"
printf '#!/bin/sh\nexit 1\n' > "$v/.git/hooks/pre-commit"; chmod +x "$v/.git/hooks/pre-commit"
run "$v" "$log"
check "no commit made"      "$(git -C "$v" rev-list --count HEAD)" 1
check "commit-FAILED noted" "$(grep -c 'commit-FAILED' "$log")" 1

echo "4. a tracked env file trips the secrets gate before anything else"
v="$tmp/v4"; log="$tmp/log4"; mkvault "$v"
echo "KEY=x" > "$v/api.env"; git -C "$v" add -f api.env
echo hi > "$v/note.md"
run "$v" "$log"
check "refused"             "$(grep -c 'refused-secrets' "$log")" 1
check "nothing committed"   "$(git -C "$v" rev-list --count HEAD)" 1

echo "5. a quiet day commits nothing but still logs"
v="$tmp/v5"; log="$tmp/log5"; mkvault "$v"
run "$v" "$log"
check "no empty commit"     "$(git -C "$v" rev-list --count HEAD)" 1
check "still one log line"  "$(wc -l < "$log" | tr -d ' ')" 1

echo
if [ "$fails" -eq 0 ]; then echo "vault-daily.sh: all checks passed"; else echo "vault-daily.sh: $fails check(s) failed"; fi
exit "$fails"
