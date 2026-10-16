---
description: Load recent context for this project from the local Obsidian vault
---
Rehydrate context for the current project from my vault (default ~/Vault, or $VAULT_DIR).

1. Identify the project with the global project-key rule (defined once, in the global
   rules' "Memory and source of truth" section -- not restated here).
2. If the repo has STATUS.md, read its Now block (top of file) first -- it is the briefing
   and outranks anything in the logs. Open the other sections only when the task needs them;
   reading STATUS whole is how a session drifts onto old threads. If
   ~/Vault/projects/<project>/status-queue.md has items, list them: they are STATUS edits
   waiting for the next working branch (/save step 3 applies them).
3. Read only what briefs the next step, not whole files:
   - **Logs:** the newest ~/Vault/logs/<date>-<project>.md only. List its session blocks
     (`grep -n '^## ' <file>`), take the last three, and read only their "Key decisions"
     and "Open threads" parts (the whole block if it has no such headings). Open an older
     log only when the Now block, the user or an open thread points there.
   - **Decisions:** the LAST 10 entries of ~/Vault/decisions/<project>.md (`tail`; the file
     is append-only, so dig older only when something points there).
   - **MOC:** ~/Vault/projects/<project>/README.md if it exists (an index; it is short).
   - **No per-project log?** Check the latest matching entries in
     ~/Vault/logs/_traces-<YYYY-MM>.md (the safety net for REPO sessions that skipped
     /save; non-repo sessions leave no automatic record -- /save is their only memory).
4. Summarize in 5-8 lines: where we left off, open threads, and decisions still in force.
5. Do not start work yet. Ask me what to pick up.
