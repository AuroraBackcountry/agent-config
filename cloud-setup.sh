#!/usr/bin/env bash
# cloud-setup.sh: wire agent-config into an ephemeral cloud session (Claude Code
# on the web). A trimmed, headless install.sh: bake the rules, link skills and
# commands, seed the machine-wide git ignore. Idempotent and non-interactive.
#
# Deliberately NOT here: everything vault-bound. The vault holds secrets
# (repo-local/ carries .env files) and never leaves your own machine, so cloud
# sessions run without the Knowledge layer — /save and /recall write to an
# ephemeral ~/Vault that dies with the VM. The SessionEnd breadcrumb hook is
# skipped for the same reason: there is no durable vault to write to.
set -euo pipefail

AGENTS_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ~/.agents: /scaffold and the skills expect this path.
if [ ! -e "$HOME/.agents" ]; then
  ln -s "$AGENTS_HOME" "$HOME/.agents"
  echo "linked ~/.agents -> $AGENTS_HOME"
fi

mkdir -p "$HOME/.claude/commands"

# Skills: on a laptop ~/.claude/skills is ours to own (install.sh symlinks the
# whole folder), but a cloud VM's harness may own that directory already —
# never replace it, link each skill into it instead.
skills_dest="$HOME/.claude/skills"
if [ ! -e "$skills_dest" ]; then
  ln -s "$AGENTS_HOME/skills" "$skills_dest"
  echo "linked ~/.claude/skills -> $AGENTS_HOME/skills"
elif [ -d "$skills_dest" ] && [ ! -L "$skills_dest" ]; then
  for sk in "$AGENTS_HOME"/skills/*/; do
    name="$(basename "$sk")"
    if [ ! -e "$skills_dest/$name" ]; then
      ln -s "${sk%/}" "$skills_dest/$name"
      echo "linked skill $name"
    fi
  done
fi

# Slash commands: per-file links, same as install.sh.
for cmd in "$AGENTS_HOME"/commands/*.md; do
  [ -e "$cmd" ] || continue
  dest="$HOME/.claude/commands/$(basename "$cmd")"
  if [ ! -e "$dest" ]; then
    ln -s "$cmd" "$dest"
    echo "linked command /$(basename "${cmd%.md}")"
  fi
done

# Machine-wide git ignore: same list install.sh seeds. Matters in the cloud for
# guest repos — without it a /graphify run would dirty someone else's git status.
gitignore_global="$(git config --get core.excludesfile 2>/dev/null || true)"
gitignore_global="${gitignore_global:-${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore}"
gitignore_global="${gitignore_global/#\~/$HOME}"
mkdir -p "$(dirname "$gitignore_global")"
touch "$gitignore_global"
[ -s "$gitignore_global" ] && [ -n "$(tail -c1 "$gitignore_global")" ] && echo >> "$gitignore_global"
while IFS= read -r pat; do
  if ! grep -qxF "$pat" "$gitignore_global"; then
    printf '%s\n' "$pat" >> "$gitignore_global"
    echo "global git ignore += $pat"
  fi
done <<'EOF'
**/.claude/settings.local.json
CLAUDE.local.md
AGENTS.override.md
graphify-out/
EOF

# Bake the global rules. sync.sh is safe headless: it never overwrites an
# unmarked (human-authored) destination when stdin is not a tty.
bash "$AGENTS_HOME/sync.sh"

echo "cloud setup done"
