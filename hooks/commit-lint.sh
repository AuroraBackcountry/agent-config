#!/usr/bin/env bash
# commit-lint.sh: PreToolUse(Bash) hook at user level, wired by install.sh. Before a Bash call that runs
# `git commit` (also `git -C <dir> commit`, `-a`, paths), it runs `status-lint.sh --diff HEAD` on that
# repo and hands Claude the STATUS-rule breaks in the status-doc lines the commit changes. The lint
# used to run only after the fact (session start, /save), so a break merged before anything saw it.
# Contract: never blocks, never fails the caller. Any error = exit 0 and no output; silent unless a
# changed line breaks the rule; guest repos are skipped (hooks/owned.sh). Output is JSON
# additionalContext: Claude never sees stderr or plain stdout of a PreToolUse hook that exits 0.
# Checked by tests/commit-lint.test.sh.
# shortcut: the repo comes from `git -C` or the session folder, never a `cd <dir> &&` in the command,
# and it checks every status-doc change since HEAD, not only the paths `git commit <path>` names
# (staged and unstaged, so `git add X && git commit` is covered). Print only, so extra lines at worst.

main() {
  local here payload dir repo out rc
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || return 0
  payload="$(cat)" || return 0
  case "$payload" in *commit*) ;; *) return 0 ;; esac  # most Bash calls stop here, before python starts
  command -v python3 >/dev/null 2>&1 || return 0

  dir="$(HOOK_PAYLOAD="$payload" FALLBACK_CWD="$PWD" python3 -I - <<'PY'
import json, os, re
p = json.loads(os.environ["HOOK_PAYLOAD"])
cmd = (p.get("tool_input") or {}).get("command") or ""
m = re.search(r"(?:^|[\s;&|(])git((?:\s+(?:-[Cc]\s+(?:\"[^\"]*\"|'[^']*'|\S+)|--?[\w-]+(?:=\S+)?))*)\s+commit\b", cmd)
if m:
    d = p.get("cwd") or os.environ["FALLBACK_CWD"]
    for a, b, c in re.findall(r"-C\s+(?:\"([^\"]*)\"|'([^']*)'|(\S+))", m.group(1)):
        d = os.path.join(d, os.path.expanduser(a or b or c))  # each -C is relative to the last, as in git
    print(d)
PY
)" || return 0
  [ -n "$dir" ] || return 0
  repo="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || return 0
  bash "$here/owned.sh" "$repo" || return 0

  out="$(bash "${COMMIT_LINT_STATUS:-$here/status-lint.sh}" --diff HEAD "$repo" 2>/dev/null)"; rc=$?
  [ "$rc" -eq 1 ] && [ -n "$out" ] || return 0
  OUT="$out" REPO="$repo" python3 -I -c '
import json, os
msg = ("Status-rule breaks in the lines this commit changes (" + os.environ["REPO"] + "):\n" + os.environ["OUT"] +
       "\nFix them in a follow-up commit on this branch (rule: /save step 3), before the PR merges.")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg}}))'
}

main 2>/dev/null || true
exit 0
