#!/usr/bin/env bash
# owned.sh <repo-dir>: exit 0 when I own the repo, 1 for a guest repo (someone else's; I branch and PR).
# Owned = origin's owner is in OWNED_GH_OWNERS, or no origin. The one guest-repo test every hook uses
# (memory-lint.sh, commit-lint.sh). Not "a vault repo-local/ exists": aurora-backcountry keeps one and is mine.
# shortcut: a fixed owner list; a new org must be added here.

owners="${OWNED_GH_OWNERS:-AuroraBackcountry Aurora-Backcountry}"
origin="$(git -C "${1:-$PWD}" remote get-url origin 2>/dev/null)"
[ -z "$origin" ] && exit 0
owner="$(printf '%s' "$origin" | sed -E 's#^(https://[^/]+/|git@[^:]+:)([^/]+)/.*#\2#')"
[[ " $owners " == *" $owner "* ]]
