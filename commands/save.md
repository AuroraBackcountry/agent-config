---
description: Save a session log and any decisions to the local Obsidian vault
---
Write a concise session record to my vault (default ~/Vault, or $VAULT_DIR if set).

1. Determine the project name from the current git repo or folder name.
2. Create or append a dated log at ~/Vault/logs/<YYYY-MM-DD>-<project>.md with:
   - What we worked on and finished
   - Key decisions and why
   - Open threads / next steps
   - Links to changed files or PRs, if any
3. For any architectural or long-lived decision, also append a one-line entry to
   ~/Vault/decisions/<project>.md (date, decision, rationale). Use [[wikilinks]] to
   connect related notes.
4. Refresh ~/Vault/projects/<project>/README.md only as an index: pointers to STATUS.md /
   AGENTS.md and a one-line "Next", never a copy of current build state (that lives in
   STATUS.md and goes stale here).
5. Keep it terse. Create any missing folders. Confirm the exact paths you wrote.
