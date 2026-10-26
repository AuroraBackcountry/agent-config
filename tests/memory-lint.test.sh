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
lint() { VAULT_DIR="$tmp/vault" CLAUDE_PROJECTS_DIR="$tmp/projects" bash "$LINT" "$1" 2>/dev/null; }
info() { VAULT_DIR="$tmp/vault" CLAUDE_PROJECTS_DIR="$tmp/projects" bash "$LINT" "$1" 2>&1 >/dev/null; }

echo "1. a clean owned repo is silent"
r="$tmp/clean"; mkrepo "$r" "https://github.com/AuroraBackcountry/clean.git"
printf '# A\n' > "$r/AGENTS.md"; printf '@AGENTS.md\n' > "$r/CLAUDE.md"
check "silent" "$(lint "$r")" ""

echo "2. each check fires"
r="$tmp/dupe"; mkrepo "$r" "git@github.com:Aurora-Backcountry/dupe.git"
printf '# A\nsame\n' > "$r/AGENTS.md"; cp "$r/AGENTS.md" "$r/CLAUDE.md"
check "CLAUDE.md copy"  "$(lint "$r" | grep -c 'full copy')" 1
r="$tmp/sshurl"; mkrepo "$r" "ssh://git@github.com:22/AuroraBackcountry/sshurl.git"
printf '# A\nsame\n' > "$r/AGENTS.md"; cp "$r/AGENTS.md" "$r/CLAUDE.md"
check "ssh:// origin is owned" "$(lint "$r" | grep -c 'full copy')" 1
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
memdir() { local d; d="$tmp/projects/$(git -C "$1" rev-parse --show-toplevel | sed 's/[^A-Za-z0-9]/-/g')/memory"; mkdir -p "$d"; printf '%s' "$d"; }
r="$tmp/fat"; mkrepo "$r"; m="$(memdir "$r")"
head -c 40000 /dev/zero | tr '\0' a > "$m/a.md"; head -c 30000 /dev/zero | tr '\0' b > "$m/b.md"
printf -- '- [A](a.md) — a trap\n' > "$m/MEMORY.md"
check "big trap files pass"    "$(lint "$r")" ""
check "big trap files exit 0"  "$(lint "$r" >/dev/null; echo $?)" 0
check "folder total is info"   "$(info "$r" | grep -c '^memory/: 68 KB in all')" 1
for i in $(seq 200); do echo "- line $i"; done > "$m/MEMORY.md"
check "MEMORY.md at 200 lines" "$(lint "$r")" ""
echo "- line 201" >> "$m/MEMORY.md"
check "MEMORY.md over 200 lines" "$(lint "$r" | grep -c '^memory/MEMORY.md: 201 lines')" 1
head -c 25001 /dev/zero | tr '\0' c > "$m/MEMORY.md"
check "MEMORY.md over 25 KB"   "$(lint "$r" | grep -c '^memory/MEMORY.md: 0 lines, 26 KB')" 1
r="$tmp/twice"; mkrepo "$r"; m="$(memdir "$r")"
printf -- '- **`preview_start` serves the MAIN checkout (2026-09-25).** text\n' > "$m/traps-browser.md"
printf -- '- **Preview_start serves the main checkout!** copy\n- **Why:** short\n' > "$m/traps-agents.md"
printf -- '- **Why:** short\n' > "$m/feedback.md"
check "one trap twice"  "$(lint "$r" | grep -c 'one trap in two files: "preview start serves the main checkout"')" 1
rm "$m/traps-agents.md"; printf -- '- **Why:** short\n' >> "$m/traps-browser.md"
check "short headline twice is fine" "$(lint "$r")" ""
here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
r="$tmp/ci"; mkrepo "$r"; mkdir -p "$r/scripts"; printf '# old copy\n' > "$r/scripts/status-lint.sh"
check "stale CI copy"   "$(lint "$r" | grep -c 'scripts/status-lint.sh: differs')" 1
cp "$here/hooks/status-lint.sh" "$r/scripts/status-lint.sh"
check "current CI copy" "$(lint "$r")" ""

echo "3. a guest repo's duplicate files are not flagged"
r="$tmp/guest"; mkrepo "$r" "https://github.com/someone-else/tool.git"
printf '# A\nsame\n' > "$r/AGENTS.md"; cp "$r/AGENTS.md" "$r/CLAUDE.md"
mkdir -p "$r/scripts"; printf '# their own lint\n' > "$r/scripts/status-lint.sh"
check "guest silent"    "$(lint "$r")" ""

echo
if [ "$fails" -eq 0 ]; then echo "memory-lint.sh: all checks passed"; else echo "memory-lint.sh: $fails check(s) failed"; fi
exit "$fails"
