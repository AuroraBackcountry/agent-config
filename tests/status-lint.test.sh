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
check "on merge"       "$(count '## Now\n\n- reach guideops.app on merge\n' 'lifecycle')" 1
check "after the merge" "$(count '## Now\n\n- the phones take it after the merge\n' 'lifecycle')" 1
check "until merge"    "$(count '## Now\n\n- held until merge\n' 'lifecycle')" 1
check "once merged"    "$(count '## Now\n\n- live once merged\n' 'lifecycle')" 1
long="$(printf 'x%.0s' $(seq 310))"
check "long bullet"    "$(count "## Now\n\n- $long\n" 'over 300')" 1
check "Now over 20"    "$(count "## Now\n\n$(for i in $(seq 21); do printf -- '- a\n'; done)" 'over 20')" 1
check "over 300 lines" "$(count "$(for i in $(seq 305); do printf 'a\n'; done)" '300-line')" 1

echo "2. look-alikes pass"
check "banner quotes"  "$(lint '> Never "draft PR", "on branch X", "redeploy on merge".\n## Now\n\n- fine\n' | wc -l | tr -d ' ')" 0
check "entry numbers"  "$(lint '## Now\n\n- adjusting entries AJE#05–#14 come back\n' | wc -l | tr -d ' ')" 0
check "#general"       "$(lint '## Now\n\n- the #general channel\n' | wc -l | tr -d ' ')" 0
check "wrapped bullet" "$(lint '## Now\n\n- a short bullet\n  wrapped onto a second line\n' | wc -l | tr -d ' ')" 0
check "true states"    "$(lint '## Now\n\n- 14.4 waits for November; 27.9 is not live; 31 is in build; a merge IS the deploy\n' | wc -l | tr -d ' ')" 0
check "no STATUS.md"   "$(rm -f "$tmp/STATUS.md"; bash "$LINT" "$tmp"; echo $?)" 0

echo "3. the docs a Status docs: line names get the same checks"
mkdir -p "$tmp/docs"
side() { printf '%b' "$2" > "$tmp/docs/walks.md"; lint "$1"; }
check "side PR number" "$(side 'Status docs: `docs/walks.md`\n## Now\n' '# Walks\n\n- shipped (#440)\n' | grep -c '^docs/walks.md:3: a PR number')" 1
check "bullet form"    "$(side '- **Status docs:** docs/walks.md\n' '- live once merged\n' | grep -c '^docs/walks.md:1: branch')" 1
big="$(for i in $(seq 260); do printf -- '- %0100d\n' 0; done)"
check "side ceiling"   "$(side 'Status docs: docs/walks.md\n' "$big" | grep -c 'over the 25 KB ceiling')" 1
check "no Now checks on a side doc" "$(side 'Status docs: docs/walks.md\n' "## Now\n\n$(for i in $(seq 21); do printf -- '- a\n'; done)" | wc -l | tr -d ' ')" 0
check "outside the repo ignored" "$(printf -- '- #440\n' > "$tmp/x.md"; mkdir -p "$tmp/in"; printf 'Status docs: ../x.md, /etc/x.md\n' > "$tmp/in/STATUS.md"; bash "$LINT" "$tmp/in" | wc -l | tr -d ' ')" 0
check "named doc missing" "$(rm -f "$tmp/docs/walks.md"; printf 'Status docs: docs/walks.md\n' > "$tmp/STATUS.md"; bash "$LINT" "$tmp" | wc -l | tr -d ' ')" 0

echo "4. --diff <base> checks only the lines changed since base"
r="$tmp/repo"; mkdir -p "$r/docs"; git -C "$r" init -q
gc() { git -C "$r" -c user.name=t -c user.email=t@t commit -qam "$1"; }
printf 'Status docs: docs/walks.md\n## Now\n\n- old break (#100)\n- fine\n' > "$r/STATUS.md"
printf '# Walks\n\n- a walk\n' > "$r/docs/walks.md"
git -C "$r" add -A; gc base
dl() { bash "$LINT" --diff HEAD "$r"; }
check "untouched: silent"     "$(dl | wc -l | tr -d ' ')" 0
printf 'Status docs: docs/walks.md\n## Now\n\n- old break (#100)\n- fine, deploys on merge\n' > "$r/STATUS.md"
check "new break only"        "$(dl)" "STATUS.md:5: branch/PR lifecycle wording (write the state after the merge)"
check "exit 1 on a break"     "$(dl >/dev/null; echo $?)" 1
git -C "$r" checkout -q -- STATUS.md
printf '%s\n' "$big" > "$r/docs/walks.md"; git -C "$r" add -A; gc big
check "over ceiling, untouched: silent" "$(dl | wc -l | tr -d ' ')" 0
printf -- '- one more walk\n' >> "$r/docs/walks.md"
check "over ceiling, added to" "$(dl | grep -c '^docs/walks.md:1: .*25 KB')" 1
git -C "$r" checkout -q -- docs/walks.md
sed -i '' '$d' "$r/docs/walks.md" 2>/dev/null || sed -i '$d' "$r/docs/walks.md"
check "over ceiling, lines deleted: silent" "$(dl | wc -l | tr -d ' ')" 0
git -C "$r" checkout -q -- docs/walks.md
printf 'Status docs: docs/walks.md docs/new.md\n## Now\n\n- old break (#100)\n- fine\n' > "$r/STATUS.md"
printf -- '- old (#77) and new\n- latest: once merged\n' > "$r/docs/new.md"
check "a new doc: every line" "$(dl | grep -c '^docs/new.md:')" 2
check "bad base: exit 2"      "$(bash "$LINT" --diff nope "$r" >/dev/null 2>&1; echo $?)" 2

echo
if [ "$fails" -eq 0 ]; then echo "status-lint.sh: all checks passed"; else echo "status-lint.sh: $fails check(s) failed"; fi
exit "$fails"
