#!/bin/bash
# SessionStart hook for THIS repo: in a cloud session (Claude Code on the web),
# wire the rules/skills/commands into the ephemeral VM. Local machines are
# untouched — there install.sh already did the wiring, properly.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

exec bash "$CLAUDE_PROJECT_DIR/cloud-setup.sh"
