---
description: Load recent context for this project from the local Obsidian vault
---
Rehydrate context for the current project from my vault (default ~/Vault, or $VAULT_DIR).

1. Identify the project with the global project-key rule (defined once, in the global
   rules' "Memory and source of truth" section -- not restated here).
2. If the repo has STATUS.md, read its current state / known gaps / next sections first --
   it is the single source of build truth and outranks anything in the logs.
3. Read the most recent 1-3 logs in ~/Vault/logs that match this project, plus the
   LAST ~20 entries of ~/Vault/decisions/<project>.md (tail it -- the file is
   append-only and grows forever; only recent decisions are load-bearing, so dig
   older only when something points there) and ~/Vault/projects/<project>/README.md
   if it exists. If no per-project log exists, check the latest matching entries in
   ~/Vault/logs/_traces-<YYYY-MM>.md (the safety net for sessions that skipped /save).
4. Summarize in 5-8 lines: where we left off, open threads, and decisions still in force.
5. Do not start work yet. Ask me what to pick up.
