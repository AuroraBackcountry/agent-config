#!/usr/bin/env bash
# status-lint.sh <repo-dir>: check a repo's STATUS.md against the STATUS rule (/save step 3).
# Prints one line per break ("STATUS.md:<line>: <reason>") and exits 1 if any; silent, exit 0
# when clean or when the repo has no STATUS.md. Run by hooks/session-start.sh (warns the
# session), /save and memory-checkpoint (fix before writing). Checked by tests/status-lint.test.sh.
# shortcut: pattern checks only. An id written without backticks, or a PR named in words
# ("PR four-forty"), gets through; a backticked 7-12 char hex word that is not an id is flagged.
# Blockquote lines and quoted text are skipped for the wording checks (the banner quotes them).

repo="${1:-$PWD}"
f="$repo/STATUS.md"
[ -f "$f" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 -I - "$f" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, encoding="utf-8", errors="replace").read()
lines = text.split("\n")
out = []
def hit(n, why): out.append(f"STATUS.md:{n}: {why}")

checks = [
    (re.compile(r"(?:^|(?<=[\s(]))#\d{2,5}\b"), "a PR number (git holds merges)"),
    (re.compile(r"`(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,12}`"), "a build, update or commit id (read it from its source)"),
    (re.compile(r"\bthe latest (is|update|build|ota|apk|version)\b", re.I), '"the latest X is" (goes stale at the next publish)'),
    (re.compile(r"\b(draft PR\b|on branch \S|redeploy on merge\b|will merge\b|merged as\b)", re.I), "branch/PR lifecycle wording"),
]
for i, line in enumerate(lines, 1):
    if line.lstrip().startswith(">"):
        continue  # the rule banner quotes the banned words on purpose
    for rx, why in checks:
        probe = line if "id" in why else re.sub(r'"[^"]*"|`[^`]*`', "", line)
        if rx.search(probe):
            hit(i, why)

nbytes = len(text.encode("utf-8"))
if len(lines) > 300: hit(len(lines), f"{len(lines)} lines, over the 300-line ceiling")
if nbytes > 25 * 1024: hit(1, f"{nbytes // 1024} KB, over the 25 KB ceiling")

start = next((i for i, l in enumerate(lines) if re.match(r"##\s+Now\b", l)), None)
if start is not None:
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    block = lines[start + 1:end]
    body = [l for l in block if l.strip()]
    if len(body) > 20: hit(start + 1, f"the Now block has {len(body)} lines, over 20")
    bullets = []  # (first line number, joined text); a hard-wrapped bullet is still one bullet
    for j, l in enumerate(block, start + 2):
        if re.match(r"\s*[-*] ", l): bullets.append([j, l.strip()])
        elif bullets and l.startswith("  ") and l.strip(): bullets[-1][1] += " " + l.strip()
    for j, b in bullets:
        if len(b) > 300: hit(j, f"a Now bullet of {len(b)} characters, over 300 (one short line each)")

print("\n".join(out)) if out else None
sys.exit(1 if out else 0)
PY
