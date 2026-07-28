#!/usr/bin/env bash
# session-end.sh: append a breadcrumb + a rich trace when a Claude Code session ends.
# Breadcrumb: one line in logs/_sessions.log (unchanged format).
# Trace: markdown entry in logs/_traces-YYYY-MM.md — append-only frozen history (past
# tense) with branch, reason, change summary, transcript path, and the first prompt,
# so a session forgotten by /save still leaves a searchable record.
# Pure shell; python3 is enhancement-only (JSON parsing). Best-effort, always exits 0.
# Claude Code passes JSON on stdin (transcript_path, session_id, reason, cwd).
# If the vault is a git repo, snapshots it after writing — versioned Knowledge layer.

vault="${VAULT_DIR:-$HOME/Vault}"
logdir="$vault/logs"
mkdir -p "$logdir" 2>/dev/null || exit 0

stdin_json=""
[ ! -t 0 ] && stdin_json="$(cat 2>/dev/null || true)"

transcript_path=""
reason=""
json_cwd=""
if [ -n "$stdin_json" ] && command -v python3 >/dev/null 2>&1; then
  transcript_path="$(printf '%s' "$stdin_json" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null || true)"
  reason="$(printf '%s' "$stdin_json" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("reason",""))' 2>/dev/null || true)"
  json_cwd="$(printf '%s' "$stdin_json" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null || true)"
fi

ts="$(date '+%Y-%m-%d %H:%M:%S')"
# the session's own cwd when the JSON carries it; the hook's $PWD otherwise
cwd="${json_cwd:-$PWD}"
project="$(basename "$cwd")"
branch="$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-')"

printf '%s | %s | branch=%s | %s\n' "$ts" "$project" "$branch" "$cwd" \
  >> "$logdir/_sessions.log" 2>/dev/null || true

# --- rich trace (everything below is best-effort) ---

first_prompt=""
# transcript_path non-empty implies python3 exists (it was parsed by python3 above)
if [ -n "$transcript_path" ] && [ -r "$transcript_path" ]; then
  first_prompt="$(python3 - "$transcript_path" <<'PY' 2>/dev/null || true
import json, sys
for i, line in enumerate(open(sys.argv[1], errors="replace")):
    if i >= 50:  # ponytail: scan only the first 50 lines; the first prompt is always early
        break
    try:
        d = json.loads(line)
    except Exception:
        continue
    m = d.get("message") or {}
    if d.get("type") == "user" or m.get("role") == "user":
        c = m.get("content", "")
        if isinstance(c, list):
            c = " ".join(b.get("text", "") for b in c if isinstance(b, dict))
        text = " ".join(str(c).split())
        if text:
            print(text[:200])
            break
PY
)"
fi

diffstat="$(git -C "$cwd" diff --stat HEAD 2>/dev/null | tail -1 || true)"
status_lines="$(git -C "$cwd" status --porcelain 2>/dev/null | head -5 || true)"

{
  printf '\n## %s — %s (branch %s)\n' "$ts" "$project" "$branch"
  printf -- '- cwd: %s\n' "$cwd"
  [ -n "$reason" ] && printf -- '- ended: %s\n' "$reason"
  [ -n "$diffstat" ] && printf -- '- changed: %s\n' "$diffstat"
  if [ -n "$status_lines" ]; then
    printf -- '- worktree was:\n'
    printf '%s\n' "$status_lines" | sed 's/^/  - /'
  fi
  [ -n "$transcript_path" ] && printf -- '- transcript: %s\n' "$transcript_path"
  [ -n "$first_prompt" ] && printf -- '- first prompt: %s\n' "$first_prompt"
} >> "$logdir/_traces-$(date +%Y-%m).md" 2>/dev/null || true

# --- vault snapshot: the Knowledge layer's only history lives here ---
if [ -d "$vault/.git" ]; then
  git -C "$vault" add -A >/dev/null 2>&1 &&
    git -C "$vault" commit -qm "session $ts ($project)" >/dev/null 2>&1 || true
fi

exit 0
