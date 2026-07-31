#!/bin/bash
# SessionStart hook (cloud only): pull the personal agent-config into an
# ephemeral VM so cloud sessions get the same rules, skills, and slash commands
# as a laptop session. Local machines exit immediately — install.sh owns them.
#
# Setup: in your Claude Code environment settings, set AGENTS_REPO to your
# agent-config fork's clone URL (and make sure the environment can reach it —
# public, or added to the environment's repositories). Without AGENTS_REPO the
# hook is a silent no-op; the session just runs without the personal layer.
#
# The vault is deliberately NOT synced: it stays on your own machine
# (repo-local/ holds .env secrets). Cloud sessions run without it.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

if [ ! -e "$HOME/.agents" ]; then
  if [ -z "${AGENTS_REPO:-}" ]; then
    echo "AGENTS_REPO not set; running without personal agent-config" >&2
    exit 0
  fi
  if ! git clone --depth 1 "$AGENTS_REPO" "$HOME/.agents"; then
    echo "could not clone $AGENTS_REPO; running without personal agent-config" >&2
    exit 0
  fi
fi

bash "$HOME/.agents/cloud-setup.sh"
