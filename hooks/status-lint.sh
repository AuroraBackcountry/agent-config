#!/usr/bin/env bash
# status-lint.sh [--diff <base>] <repo-dir>: check a repo's status docs against the STATUS rule
# (/save step 3). The docs are STATUS.md plus each .md path its `Status docs:` line names (a ledger,
# a walk list): every doc gets the wording checks and the 300-line / 25 KB ceiling; STATUS.md also
# gets the Now-block checks. Prints one line per break ("<doc>:<line>: <reason>") and exits 1 if any;
# silent, exit 0 when clean or when the repo has no STATUS.md; exit 2 when --diff cannot read git.
# --diff <base>: check only the lines changed between <base> and the working tree, so an old break
# never fires again; the ceiling fires only when the change adds lines to a doc over it.
# Run by hooks/session-start.sh (warns the session), hooks/commit-lint.sh (before a commit), CI in
# scaffolded repos (scripts/status-lint.sh is a copy of this file), /save and memory-checkpoint.
# Checked by tests/status-lint.test.sh.
# shortcut: pattern checks only. An id written without backticks, or a PR named in words
# ("PR four-forty"), gets through; a backticked 7-12 char hex word that is not an id is flagged.
# Blockquote lines and quoted text are skipped for the wording checks (the banner quotes them).

base=""
if [ "${1:-}" = "--diff" ]; then base="${2:-}"; shift 2 || exit 2; fi
repo="${1:-$PWD}"
[ -f "$repo/STATUS.md" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

python3 -I - "$repo" "$base" <<'PY'
import os, re, subprocess, sys
repo, base = sys.argv[1], sys.argv[2]
out = []

checks = [
    (re.compile(r"(?:^|(?<=[\s(]))#\d{2,5}\b"), "a PR number (git holds merges)"),
    (re.compile(r"`(?=[0-9a-f]*\d)(?=[0-9a-f]*[a-f])[0-9a-f]{7,12}`"), "a build, update or commit id (read it from its source)"),
    (re.compile(r"\bthe latest (is|update|build|ota|apk|version)\b", re.I), '"the latest X is" (goes stale at the next publish)'),
    (re.compile(r"\b(draft PR\b|on branch \S|will merge\b|merged as\b|(on|after|until) (the )?merge\b|once merged\b)", re.I),
     "branch/PR lifecycle wording (write the state after the merge)"),
]

def changed(rel):
    """New-side line numbers changed since base, every line for a doc base lacks; None = all lines."""
    if not base:
        return None
    git = lambda *a: subprocess.run(["git", "-C", repo, *a], capture_output=True, text=True)
    if git("cat-file", "-e", f"{base}:{rel}").returncode != 0:
        if git("rev-parse", "--verify", "-q", f"{base}^{{commit}}").returncode != 0:
            print(f"status-lint: cannot read base {base!r} in {repo}", file=sys.stderr)
            sys.exit(2)
        return None  # a doc new since base: all of it is the change
    d = git("diff", "-U0", "--no-color", base, "--", rel)
    if d.returncode != 0:
        print(f"status-lint: git diff failed in {repo}", file=sys.stderr)
        sys.exit(2)
    lines = set()
    for m in re.finditer(r"^@@ -\S+ \+(\d+)(?:,(\d+))? @@", d.stdout, re.M):
        start, n = int(m.group(1)), int(m.group(2) or 1)
        lines.update(range(start, start + n))
    return lines

def lint(rel, now):
    path = os.path.join(repo, rel)
    if not os.path.isfile(path):
        return
    text = open(path, encoding="utf-8", errors="replace").read()
    lines = text.split("\n")
    only = changed(rel)
    if only is not None and not only:
        return  # untouched, or lines deleted only: nothing new to check, the ceiling included
    want = lambda n: only is None or n in only
    hit = lambda n, why: out.append(f"{rel}:{n}: {why}")

    for i, line in enumerate(lines, 1):
        if not want(i) or line.lstrip().startswith(">"):
            continue  # the rule banner quotes the banned words on purpose
        for rx, why in checks:
            probe = line if "id" in why else re.sub(r'"[^"]*"|`[^`]*`', "", line)
            if rx.search(probe):
                hit(i, why)

    nbytes = len(text.encode("utf-8"))
    if len(lines) > 300: hit(len(lines), f"{len(lines)} lines, over the 300-line ceiling")
    if nbytes > 25 * 1024: hit(1, f"{nbytes // 1024} KB, over the 25 KB ceiling")

    if not now:
        return
    start = next((i for i, l in enumerate(lines) if re.match(r"##\s+Now\b", l)), None)
    if start is None:
        return
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")), len(lines))
    block = lines[start + 1:end]
    body = [l for l in block if l.strip()]
    if len(body) > 20 and any(want(n) for n in range(start + 2, end + 1)):
        hit(start + 1, f"the Now block has {len(body)} lines, over 20")
    bullets = []  # [first line, last line, joined text]; a hard-wrapped bullet is still one bullet
    for j, l in enumerate(block, start + 2):
        if re.match(r"\s*[-*] ", l): bullets.append([j, j, l.strip()])
        elif bullets and l.startswith("  ") and l.strip(): bullets[-1][1] = j; bullets[-1][2] += " " + l.strip()
    for a, b, t in bullets:
        if len(t) > 300 and any(want(n) for n in range(a, b + 1)):
            hit(a, f"a Now bullet of {len(t)} characters, over 300 (one short line each)")

status = open(os.path.join(repo, "STATUS.md"), encoding="utf-8", errors="replace").read()
docs = []
for m in re.finditer(r"^\s*(?:[-*]\s+)?\**Status docs:\**(.*)$", status, re.M):
    for p in re.findall(r"[\w./-]+\.md\b", m.group(1)):
        if p != "STATUS.md" and not p.startswith("/") and ".." not in p.split("/") and p not in docs:
            docs.append(p)  # repo-relative only: a PR's text never points the lint outside the repo

lint("STATUS.md", True)
for d in docs:
    lint(d, False)
print("\n".join(out)) if out else None
sys.exit(1 if out else 0)
PY
