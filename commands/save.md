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
3. **STATUS.md** -- the full rule lives here; global rules carry a one-line summary.
   Repos I own only: in a guest repo, skip (state lives in
   ~/Vault/projects/<project>/repo-local/, never in the MOC, which stays an index).
   - **What it holds:** state, not lifecycle -- present-tense facts true right now. Never
     `draft PR` / `on branch X` / `redeploy on merge`, a PR number, a build/deploy/update id,
     or "the latest X is Y" (write "phones take main's OTA updates"; which one is read from
     its source: `gh`, the EAS dashboard). It is the ONE home of build state: the vault MOC
     and auto-memory point to it, never copy it, and never record "STATUS #N merged".
   - **Where it lands:** the edit rides the PR it describes, written as the state after
     merge. On a working branch not yet merged: first apply and delete every item in
     ~/Vault/projects/<project>/status-queue.md, then edit and commit STATUS there. On main
     in a repo that works through PRs, or on a merged branch: don't touch STATUS and never
     create a branch or PR for it -- append the change to status-queue.md as one dated
     bullet. Repos that commit straight to main commit it there.
   - **Shape:** the Now block first (under 20 lines, one line per bullet; when something
     lands a line is replaced, never added), then current state and known gaps, present
     tense, edited in place; a shipped item or closed gap is deleted (git holds it).
     Ceiling: over 300 lines or 25 KB, compact BEFORE writing -- delete shipped items and
     closed gaps, strip embedded dates -- until under. Report the before/after lines and
     size. Dated history goes in CHANGELOG.md if the repo keeps one, never in STATUS.md.
   - **Check:** before committing, run `bash ~/.agents/hooks/status-lint.sh <repo>` and fix
     every line it prints (ids, PR numbers, "latest X", lifecycle wording, size, Now length).
4. Create or append a dated log at ~/Vault/logs/<YYYY-MM-DD>-<project>.md: one block per
   session, always this shape, because `/recall` reads only the last blocks' decisions and
   open threads:
   ```
   ## Session: <topic>
   ### What we worked on and finished
   ### Key decisions and why
   ### Open threads / next steps
   ```
   Links to changed files or PRs go under "What we worked on". Open threads are the next
   session's briefing: concrete, one line each.
5. For any architectural or long-lived decision, also append a one-line entry to
   ~/Vault/decisions/<project>.md (date, decision, rationale). Use [[wikilinks]] to
   connect related notes.
6. Refresh ~/Vault/projects/<project>/README.md only as an index: pointers to STATUS.md /
   AGENTS.md and a one-line "Next", never a copy of current build state (that lives in
   STATUS.md and goes stale here). "Next" never names a PR, an id, or a STATUS edit.
7. The SessionEnd trace (logs/_traces-*.md) already records what changed mechanically
   (branch, diffs, transcript). This log's value is what no hook can write: decisions,
   why, and open threads. Don't restate diffs.
8. Keep it terse. Create any missing folders. Confirm the exact paths you wrote.
