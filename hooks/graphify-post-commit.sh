#!/usr/bin/env bash
# graphify-post-commit.sh: background AST-only code-graph refresh after each commit.
# Lives centrally; repos call it from .git/hooks/post-commit (or .husky/post-commit)
# so improvements here propagate without re-install. Never blocks or fails a
# commit: every path exits 0. Zero LLM tokens (graphify update is pure AST).

# Only opted-in repos auto-update: an existing graph is the opt-in signal.
top="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -f "$top/graphify-out/graph.json" ] || exit 0

# A tracked graph is the team's committed artifact — never rebuild over it.
git -C "$top" ls-files --error-unmatch graphify-out/graph.json >/dev/null 2>&1 && exit 0

# graphify must be on PATH.
command -v graphify >/dev/null 2>&1 || exit 0

# Skip mid-rebase/merge/cherry-pick; the finishing commit will fire us instead.
gitdir="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
for f in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD; do
  [ -e "$gitdir/$f" ] && exit 0
done

# Dedup: one graphify at a time, machine-wide.
# ponytail: no timeout wrapper (macOS ships no coreutils timeout); this pgrep
# guard prevents pileup instead. Ceiling: a hung run blocks future refreshes
# until killed. Upgrade path: brew coreutils + gtimeout around the launch.
pgrep -qf graphify && exit 0

# CPU guard: skip when 1-min load average exceeds half the logical cores.
# ponytail: darwin-only sysctl; add a Linux /proc/loadavg branch if ever needed.
load1="$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')"
cores="$(sysctl -n hw.logicalcpu 2>/dev/null)"
{ [ -n "$load1" ] && [ -n "$cores" ]; } || exit 0
awk -v l="$load1" -v c="$cores" 'BEGIN { exit (l <= c / 2) ? 0 : 1 }' || exit 0

# Launch detached. AST-only; doc/paper/image changes still need a manual
# /graphify --update (the AST pass skips them by design).
mkdir -p "$HOME/.cache" 2>/dev/null || exit 0
log="$HOME/.cache/graphify-rebuild.log"
printf '=== %s %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$top" >> "$log" 2>/dev/null || exit 0
cd "$top" || exit 0
nohup graphify update . >> "$log" 2>&1 < /dev/null &
disown
exit 0
