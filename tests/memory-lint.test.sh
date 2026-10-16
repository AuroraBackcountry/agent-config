#!/usr/bin/env bash
# One runnable check for hooks/memory-lint.sh: each mechanical check fires, a clean repo is
# silent, and a guest repo's CLAUDE.md/AGENTS.md are not mine to flag. Temp dirs only.
#
#   bash tests/memory-lint.test.sh
set -uo pipefail

LINT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/hooks/memory-lint.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fails=0
ok()    { printf '  ok   %s\n' "$1"; }
fail()  { printf '  FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { [ "$2" = "$3" ] && ok "$1" || fail "$1 — got '$2', want '$3'"; }
mkrepo() { mkdir -p "$1"; git -C "$1" init -q; [ -n "${2:-}" ] && git -C "$1" remote add origin "$2"; true; }
lint() { VAULT_DIR="$tmp/vault" CLAUDE_PROJECTS_DIR="$tmp/projects" bash "$LINT" "$1"; }

echo "1. a clean owned repo is silent"
r="$tmp/clean"; mkrepo "$r" "https://github.com/AuroraBackcountry/clean.git"
printf '# A\n' > "$r/AGENTS.md"; printf '@AGENTS.md\n' > "$r/CLAUDE.md"
check "silent" "$(lint "$r")" ""

echo "2. each check fires"
r="$tmp/dupe"; mkrepo "$r" "git@github.com:Aurora-Backcountry/dupe.git"
printf '# A\nsame\n' > "$r/AGENTS.md"; cp "$r/AGENTS.md" "$r/CLAUDE.md"
check "CLAUDE.md copy"  "$(lint "$r" | grep -c 'full copy')" 1
r="$tmp/big"; mkrepo "$r"
for i in $(seq 305); do echo "line $i"; done > "$r/AGENTS.md"
check "AGENTS.md size"  "$(lint "$r" | grep -c 'over 300 lines')" 1
r="$tmp/mocked"; mkrepo "$r"
mkdir -p "$tmp/vault/projects/mocked"; printf '# mocked\n\nNext: ship (#228)\n' > "$tmp/vault/projects/mocked/README.md"
check "MOC PR number"   "$(lint "$r" | grep -c 'vault MOC:3')" 1
r="$tmp/merges"; mkrepo "$r"
# encode the path git reports (macOS temp dirs resolve /var -> /private/var)
m="$tmp/projects/$(git -C "$r" rev-parse --show-toplevel | sed 's/[^A-Za-z0-9]/-/g')/memory"; mkdir -p "$m"
printf -- '- STATUS #436 merged\n' > "$m/current-phase.md"
check "memory merge"    "$(lint "$r" | grep -c 'STATUS-only PR')" 1
r="$tmp/stat"; mkrepo "$r"; printf '## Now\n\n- on `7a6b476c`\n' > "$r/STATUS.md"
check "STATUS rule"     "$(lint "$r" | grep -c 'commit id')" 1

echo "3. a guest repo's duplicate files are not flagged"
r="$tmp/guest"; mkrepo "$r" "https://github.com/someone-else/tool.git"
printf '# A\nsame\n' > "$r/AGENTS.md"; cp "$r/AGENTS.md" "$r/CLAUDE.md"
check "guest silent"    "$(lint "$r")" ""

echo
if [ "$fails" -eq 0 ]; then echo "memory-lint.sh: all checks passed"; else echo "memory-lint.sh: $fails check(s) failed"; fi
exit "$fails"
