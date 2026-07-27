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
if [ -d "$TARGET/.git" ]; then
  hook="$TARGET/.git/hooks/post-commit"
  line='bash "$HOME"/.agents/hooks/graphify-post-commit.sh'
  if [ -f "$hook" ]; then
    if ! grep -q graphify-post-commit.sh "$hook"; then
      printf '%s\n' "$line" >> "$hook"
      echo "added  graphify line to existing post-commit hook"
    fi
  else
    printf '#!/usr/bin/env bash\n%s\n' "$line" > "$hook"
    echo "added  .git/hooks/post-commit (graphify)"
  fi
  chmod +x "$hook"
fi
