---
name: context-file-update
description: >
  Re-evaluate and overwrite an existing AGENTS.md (or equivalent context file)
  to reflect the current state of the codebase. Re-reads the repo, compares
  against what the file says, and writes a fresh version.

  Trigger on: "update the AGENTS.md", "refresh the AGENTS.md", "AGENTS.md is
  stale", "rewrite the context file", "update the AGENTS.md", or any explicit
  request to bring a repo context file up to date.

  Do NOT trigger proactively. Do NOT trigger on first-contact onboarding --
  that's handled by the repo-intake skill. Only trigger when the user explicitly
  asks to update an existing file.

  Do NOT trigger if no AGENTS.md or equivalent exists. In that case, suggest
  running the repo-intake skill instead.
---

# AGENTS.md Update

The user has an existing AGENTS.md (or AGENTS.md, .cursorrules, etc.) and wants
it refreshed to match the current state of the repo. Your job is to re-read
the codebase, identify what's changed or drifted, and write a complete
replacement file.

## Step 1: Read the current file

Read the existing context file. Note its structure, sections, and conventions.
You'll preserve the file's overall shape unless the structure itself is the
problem.

Also check for other memory files (AGENTS.md, AGENTS.md, .cursorrules,
.github/copilot-instructions.md). If multiple exist, read all of them and
flag contradictions -- the user may want to consolidate.

Note the repo's WIDER context surface for Step 6: a context-map section in the
file (often "Keeping context current" / "context map"), sibling authoritative
docs (a MASTER_PLAN / ROADMAP, an ARCHITECTURE / ADR, `docs/`), and the
assistant's project memory files. If the file declares a context map, that list
is authoritative for what a context review must touch.

## Step 2: Re-map the repo

This is a lighter version of initial intake. You already have a context file
telling you what the repo looked like last time. Focus on what's different.

```bash
git log --oneline -30
git log --stat -10
```

Scan the top-level directory structure. Compare against what the context file
describes:

- **New directories or modules** the file doesn't mention
- **Removed or renamed things** the file still references
- **Dependency changes** (new packages added, major version bumps, removed deps)
- **New config files** (added CI, Docker, linter configs)
- **Stack changes** (new database, new external service, framework migration)

Read any files that look like they've changed significantly. Don't re-read
everything -- use the git log to guide where to look.

## Step 3: Ask one round of questions

Ask the user 1-3 questions, focused only on things that have changed and
that you can't infer from the code. Common good questions:

- "I see you added X. Is that replacing Y or running alongside it?"
- "The current focus section mentions [old thing]. What are you working on now?"
- "There's a new `infra/` directory. Should the deployment workflow section
  be rewritten?"

If the changes are obvious and well-documented in commits, you may not need
to ask anything. In that case, say so and proceed.

Do NOT re-ask foundational questions that the existing file already answers
(project purpose, who uses it, core architecture) unless the code suggests
those answers have changed.

Wait for the user to respond before proceeding.

## Step 4: Write the new file

Write the complete replacement file. Follow these rules:

**Preserve the existing structure.** If the old file used specific section
headings or ordering, keep that structure unless the user asked for changes
or the structure no longer fits. Consistency across updates matters -- the
user has muscle memory for where things are in the file.

**Carry forward anything still true.** Don't drop valid content just because
you didn't independently rediscover it in Step 2. If the old file says "error
handling uses Result types, never throw" and nothing in the code contradicts
that, keep it.

**Update what's changed.** Replace stale content with current information.
Don't hedge with "previously X, now Y" narration -- just state the current
truth.

**Keep it tight.** Same principle as initial intake: the file earns its keep
by capturing context that isn't in the code. If something is now obvious from
the code (e.g., a README was added that covers setup), remove it from the
context file.

**Current focus section.** Replace this entirely based on the user's answer
in Step 3. If they didn't mention a new focus, ask before carrying the old
one forward -- it's the section most likely to be stale.

## Step 5: Present and write

1. Show the user the full new file content.
2. Ask: "Anything to correct before I write this?"
3. Apply corrections if any.
4. Overwrite the existing file.

If multiple memory files exist and they flagged contradictions in Step 1,
remind the user which files conflict and suggest reconciling them.

## Step 6: Sync the rest of the context surface

A context file rarely lives alone. A "context review" keeps ALL of the project's
context surfaces consistent, not just the one file -- so in the same pass, re-check
and refresh the siblings whose status/focus drifts together:

- **A context map.** If the context file declares the full set of context files
  (e.g. a "Keeping context current" / "context map" section), treat that list as
  authoritative and update every file in it.
- **Plan / roadmap docs** (MASTER_PLAN, ROADMAP, PROJECT_PLAN): build-status, phase,
  and "current focus" lines drift fastest -- sync them (and any status banner).
- **Architecture / ADR docs** (ARCHITECTURE.md, docs/adr/*): the roadmap/status
  section and any "as-built" markers.
- **Project memory** (the assistant's memory files): the project-state / current-phase
  / user-preference notes, plus the one-line index entry for each.

For each: update it only where it describes a state the code has moved past (a phase
shipped, a PR merged, a feature now built). Do NOT rewrite docs that only describe
intent/design (locked specs) -- touch only their build-status / as-built markers.
List for the user which sibling files you synced.

## Edge cases

**File doesn't exist.** Don't trigger this skill. Tell the user no context
file was found and suggest running repo-intake instead.

**Repo has barely changed.** If the git log shows minimal activity and the
file looks current, say so. Ask if there's something specific they want
updated. Don't rewrite a file just to rewrite it.

**Major architectural shift.** If the repo has fundamentally changed (new
framework, rewrite in progress, monorepo split), the existing structure
may not fit. In that case, tell the user the file needs a more thorough
rewrite and offer to run a fresh intake-style process rather than a
surface-level update.

**User says "just update it."** If they want to skip questions, re-map
silently, write the best file you can, and show it for correction. Flag
sections where you guessed.
