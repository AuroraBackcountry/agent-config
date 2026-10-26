#!/usr/bin/env bash
# One runnable check for hooks/session-start.sh: silent when healthy, one warning
# line per failure kind. sync.sh is stubbed; everything writes to a temp dir.
#
#   bash tests/session-start.test.sh
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/session-start.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }

printf 'exit 0\n' > "$tmp/sync-ok.sh"
printf 'exit 1\n' > "$tmp/sync-bad.sh"
run() { SESSION_START_SYNC="$1" SYNC_HEAL_LOG="$2" VAULT_DAILY_LOG="$3" SESSION_START_DIR="${4:-$tmp}" bash "$HOOK"; }

echo "1. healthy: no output"
echo "2026-10-15 17:00:07 pushed HEAD=716cd1d" > "$tmp/v1"
check "silent" "$(run "$tmp/sync-ok.sh" "$tmp/h1" "$tmp/v1")" ""

echo "2. a failed push is reported"
echo "2026-10-14 17:05:20 push-failed HEAD=7dd9bd2" > "$tmp/v2"
out="$(run "$tmp/sync-ok.sh" "$tmp/h2" "$tmp/v2")"
check "one warning" "$(printf '%s\n' "$out" | grep -c 'did not push')" 1

echo "3. a stale backup log is reported"
echo "2026-10-01 17:00:07 pushed HEAD=abc1234" > "$tmp/v3"; touch -t 202610010000 "$tmp/v3"
check "stale warning" "$(run "$tmp/sync-ok.sh" "$tmp/h3" "$tmp/v3" | grep -c 'over 2 days')" 1

echo "4. a failed self-heal is logged and reported"
echo "2026-10-15 17:00:07 pushed HEAD=716cd1d" > "$tmp/v4"
out="$(run "$tmp/sync-bad.sh" "$tmp/h4" "$tmp/v4")"
check "heal failure logged"   "$(grep -c 'self-heal failed' "$tmp/h4")" 1
check "heal failure reported" "$(printf '%s\n' "$out" | grep -c 'self-heal failed in the last 7 days')" 1

echo "5. a repo whose memory files break the rules gets one warning; a clean one gets none"
repo="$tmp/repo"; mkdir -p "$repo"; git -C "$repo" init -q
printf '# STATUS\n\n## Now\n\n- **Live:** the latest is `7a6b476c` (#440).\n' > "$repo/STATUS.md"
echo "2026-10-15 17:00:07 pushed HEAD=716cd1d" > "$tmp/v5"
out="$(run "$tmp/sync-ok.sh" "$tmp/h5" "$tmp/v5" "$repo")"
check "one STATUS warning" "$(printf '%s\n' "$out" | grep -c 'break the rules in 3 place')" 1
printf '# STATUS\n\n## Now\n\n- **Live:** phones take main'"'"'s over-the-air updates.\n' > "$repo/STATUS.md"
check "clean STATUS is silent" "$(run "$tmp/sync-ok.sh" "$tmp/h5" "$tmp/v5" "$repo")" ""
m="$tmp/projects/$(git -C "$repo" rev-parse --show-toplevel | sed 's/[^A-Za-z0-9]/-/g')/memory"; mkdir -p "$m"
head -c 90000 /dev/zero | tr '\0' a > "$m/traps.md"; printf -- '- [Traps](traps.md)\n' > "$m/MEMORY.md"
check "big trap files are silent" "$(CLAUDE_PROJECTS_DIR="$tmp/projects" run "$tmp/sync-ok.sh" "$tmp/h5" "$tmp/v5" "$repo")" ""

echo
if [ "$fails" -eq 0 ]; then echo "session-start.sh: all checks passed"; else echo "session-start.sh: $fails check(s) failed"; fi
exit "$fails"
