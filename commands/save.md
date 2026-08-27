---
description: End a session - take stock against git once, update STATUS.md, and write the session log and decisions to the vault
---
The session-end entry point: one take-stock, both surfaces (STATUS.md = state,
vault = history). Mid-session capture before /compact and memory-file repair are
memory-checkpoint's job, not this command's.

1. Determine the project name with the global project-key rule (defined once, in the
   global rules' "Memory and source of truth" section -- not restated here).
2. Take stock once against reality: `git status`, `git diff --stat`, `git log --oneline -15`.
   Never record a claim you didn't verify.
3. Update the repo's STATUS.md (repos I own only -- in a guest repo, skip: state lives in
   ~/Vault/projects/<repo>/repo-local/, never in the MOC, which stays an index): current
   state, known gaps, next concrete step, present tense, edited in place, matching the
   file's structure. Dated history goes in CHANGELOG.md if the repo
   keeps one, never in STATUS.md.
4. Create or append a dated log at ~/Vault/logs/<YYYY-MM-DD>-<project>.md with:
   - What we worked on and finished
   - Key decisions and why
   - Open threads / next steps
   - Links to changed files or PRs, if any
5. For any architectural or long-lived decision, also append a one-line entry to
   ~/Vault/decisions/<project>.md (date, decision, rationale). Use [[wikilinks]] to
   connect related notes.
6. Refresh ~/Vault/projects/<project>/README.md only as an index: pointers to STATUS.md /
   AGENTS.md and a one-line "Next", never a copy of current build state (that lives in
   STATUS.md and goes stale here).
7. The SessionEnd trace (logs/_traces-*.md) already records what changed mechanically
   (branch, diffs, transcript). This log's value is what no hook can write: decisions,
   why, and open threads. Don't restate diffs.
8. Keep it terse. Create any missing folders. Confirm the exact paths you wrote.
