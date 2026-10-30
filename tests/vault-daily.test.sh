#!/usr/bin/env bash
# One runnable check for hooks/vault-daily.sh — the pure-logic paths: every
# exit writes a status line, the commit-failure branch is reported, the
# secrets gates refuse tracked env files (at any depth) and key-shaped text (whatever the
# file is named), a quiet day commits nothing,
# and the push reports pushed to a reachable remote and push-failed (after its retry) to a dead one.
# shortcut: the remotes are local paths, so a network that comes back between tries is not
# exercised; upgrade if the retry ever needs more than one late try.
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

echo "6. a key pasted into a note is refused, and nothing is committed"
v="$tmp/v6"; log="$tmp/log6"; mkvault "$v"
echo "token ghp_$(printf 'a%.0s' $(seq 36))" > "$v/note.md"
run "$v" "$log"
check "refused names the file" "$(grep -c 'refused-secrets.*note.md' "$log")" 1
check "nothing committed"      "$(git -C "$v" rev-list --count HEAD)" 1
check "nothing left staged"    "$(git -C "$v" diff --cached --name-only | wc -l | tr -d ' ')" 0

echo "7. ordinary text with a short hex id still commits"
v="$tmp/v7"; log="$tmp/log7"; mkvault "$v"
echo "update 7a6b476c shipped; see sk-learn docs" > "$v/note.md"
run "$v" "$log"
check "commit landed"          "$(git -C "$v" rev-list --count HEAD)" 2

echo "8. a reachable remote gets the snapshot"
v="$tmp/v8"; log="$tmp/log8"; mkvault "$v"; git init -q --bare "$tmp/r8.git"
git -C "$v" remote add origin "$tmp/r8.git"; echo hi > "$v/note.md"
run "$v" "$log"
check "status pushed"          "$(grep -c ' pushed ' "$log")" 1
check "remote has it"          "$(git -C "$tmp/r8.git" rev-parse HEAD)" "$(git -C "$v" rev-parse HEAD)"

echo "9. a dead remote is retried, then reported"
v="$tmp/v9"; log="$tmp/log9"; mkvault "$v"
git -C "$v" remote add origin "$tmp/missing.git"; echo hi > "$v/note.md"
start=$SECONDS; VAULT_DAILY_RETRY_WAIT=2 run "$v" "$log"
check "status push-failed"     "$(grep -c ' push-failed ' "$log")" 1
check "waited before retry"    "$([ $((SECONDS - start)) -ge 2 ] && echo yes)" yes

echo "10. a key in a note with a non-ASCII name is still refused (git quotes such a name)"
v="$tmp/v10"; log="$tmp/log10"; mkvault "$v"
echo "token ghp_$(printf 'a%.0s' $(seq 36))" > "$v/Café.md"
run "$v" "$log"
check "refused"                "$(grep -c 'refused-secrets' "$log")" 1
check "nothing committed"      "$(git -C "$v" rev-list --count HEAD)" 1

echo "11. a tracked env file below the root trips the secrets gate"
v="$tmp/v11"; log="$tmp/log11"; mkvault "$v"
mkdir -p "$v/projects/foo"; echo "KEY=x" > "$v/projects/foo/.env.local"; git -C "$v" add -f projects/foo/.env.local
echo hi > "$v/note.md"
run "$v" "$log"
check "refused"                "$(grep -c 'refused-secrets' "$log")" 1
check "nothing committed"      "$(git -C "$v" rev-list --count HEAD)" 1

echo
if [ "$fails" -eq 0 ]; then echo "vault-daily.sh: all checks passed"; else echo "vault-daily.sh: $fails check(s) failed"; fi
exit "$fails"
