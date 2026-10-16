#!/usr/bin/env bash
# One runnable check for hooks/status-lint.sh: each break kind is caught, and the known
# look-alikes (the rule banner, quoted words, accounting entry numbers, hard-wrapped
# bullets) are not. Everything writes to a temp dir.
#
#   bash tests/status-lint.test.sh
set -uo pipefail

LINT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/status-lint.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }
lint()  { printf '%b' "$1" > "$tmp/STATUS.md"; bash "$LINT" "$tmp"; }
count() { lint "$1" | grep -c "$2"; }

echo "1. each break kind is caught"
check "PR number"      "$(count '## Now\n\n- shipped (#440)\n' 'PR number')" 1
check "id"             "$(count '## Now\n\n- on `7a6b476c`\n' 'commit id')" 1
check "latest"         "$(count '## Now\n\n- the latest update is out\n' 'the latest')" 1
check "lifecycle"      "$(count '## Now\n\n- waiting on branch fix-x\n' 'lifecycle')" 1
long="$(printf 'x%.0s' $(seq 310))"
check "long bullet"    "$(count "## Now\n\n- $long\n" 'over 300')" 1
check "Now over 20"    "$(count "## Now\n\n$(for i in $(seq 21); do printf -- '- a\n'; done)" 'over 20')" 1
check "over 300 lines" "$(count "$(for i in $(seq 305); do printf 'a\n'; done)" '300-line')" 1

echo "2. look-alikes pass"
check "banner quotes"  "$(lint '> Never "draft PR", "on branch X", "redeploy on merge".\n## Now\n\n- fine\n' | wc -l | tr -d ' ')" 0
check "entry numbers"  "$(lint '## Now\n\n- adjusting entries AJE#05–#14 come back\n' | wc -l | tr -d ' ')" 0
check "#general"       "$(lint '## Now\n\n- the #general channel\n' | wc -l | tr -d ' ')" 0
check "wrapped bullet" "$(lint '## Now\n\n- a short bullet\n  wrapped onto a second line\n' | wc -l | tr -d ' ')" 0
check "no STATUS.md"   "$(rm -f "$tmp/STATUS.md"; bash "$LINT" "$tmp"; echo $?)" 0

echo
if [ "$fails" -eq 0 ]; then echo "status-lint.sh: all checks passed"; else echo "status-lint.sh: $fails check(s) failed"; fi
exit "$fails"
