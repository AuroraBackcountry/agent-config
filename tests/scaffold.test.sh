#!/usr/bin/env bash
# One runnable check for scaffold.sh: it lays the repo-carried status lint (a real file equal to
# hooks/status-lint.sh, not a link) and its CI workflow, the template STATUS.md passes the lint, and
# a re-run adds nothing and keeps a repo's own files. Temp dirs only.
#
#   bash tests/scaffold.test.sh
set -uo pipefail

HOME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }

echo "1. a fresh repo gets the lint and its workflow"
bash "$HOME_DIR/scaffold.sh" "$tmp/r" >/dev/null
check "lint is a real file"  "$([ -f "$tmp/r/scripts/status-lint.sh" ] && [ ! -L "$tmp/r/scripts/status-lint.sh" ] && echo yes)" yes
check "lint equals the hook" "$(cmp -s "$tmp/r/scripts/status-lint.sh" "$HOME_DIR/hooks/status-lint.sh" && echo same)" same
check "workflow laid"        "$(grep -c 'scripts/status-lint.sh --diff' "$tmp/r/.github/workflows/status-lint.yml")" 1
check "no paths-ignore"      "$(grep -c '^[[:space:]]*paths-ignore:' "$tmp/r/.github/workflows/status-lint.yml")" 0
check "template STATUS passes" "$(bash "$tmp/r/scripts/status-lint.sh" "$tmp/r"; echo $?)" 0

echo "2. a re-run adds nothing and keeps the repo's own files"
printf 'mine\n' > "$tmp/r/scripts/status-lint.sh"
check "nothing to do" "$(bash "$HOME_DIR/scaffold.sh" "$tmp/r" | tail -n 1)" "nothing to do: project already matches the standard layout"
check "own file kept" "$(cat "$tmp/r/scripts/status-lint.sh")" mine

echo
if [ "$fails" -eq 0 ]; then echo "scaffold.sh: all checks passed"; else echo "scaffold.sh: $fails check(s) failed"; fi
exit "$fails"
