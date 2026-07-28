#!/usr/bin/env bash
# scaffold.sh: lay the standard project skeleton into a target directory.
# Never overwrites existing files. Safe to run repeatedly.
set -euo pipefail

AGENTS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$AGENTS_HOME/templates/project"
TARGET="${1:-$PWD}"

if [ ! -d "$TEMPLATE" ]; then
  echo "error: template not found at $TEMPLATE" >&2
  exit 1
fi

added=0
while IFS= read -r -d '' src; do
  rel="${src#"$TEMPLATE"/}"
  dest="$TARGET/$rel"
  if [ -e "$dest" ]; then
    continue
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "added  $rel"
  added=$((added + 1))
done < <(find "$TEMPLATE" -type f -print0)

if [ "$added" -eq 0 ]; then
  echo "nothing to do: project already matches the standard layout"
else
  echo "scaffolded $added file(s) into $TARGET"
fi

# Install the graphify post-commit hook. The hook line calls the central
# script so future improvements propagate without re-running scaffold.
# rev-parse --git-path resolves worktrees (shared hooks dir) and core.hooksPath
# (husky-style repos) — a hardcoded .git/hooks path silently misses both.
if hooksdir="$(git -C "$TARGET" rev-parse --path-format=absolute --git-path hooks 2>/dev/null)"; then
  mkdir -p "$hooksdir"
  hook="$hooksdir/post-commit"
  line="bash \"$AGENTS_HOME\"/hooks/graphify-post-commit.sh"
  if [ -f "$hook" ]; then
    if ! grep -q graphify-post-commit.sh "$hook"; then
      # ensure the existing hook ends with a newline or the line glues onto it
      [ -n "$(tail -c1 "$hook")" ] && echo >> "$hook"
      printf '%s\n' "$line" >> "$hook"
      echo "added  graphify line to existing post-commit hook ($hook)"
    fi
  else
    printf '#!/usr/bin/env bash\n%s\n' "$line" > "$hook"
    echo "added  post-commit hook (graphify) at $hook"
  fi
  chmod +x "$hook"
else
  echo "note: graphify post-commit hook not installed ($TARGET is not a git repo, or git <2.31)"
fi
