---
name: repo-intake
description: >
  Structured first-contact onboarding for a new codebase. Maps the repo, asks
  targeted questions, reflects understanding back, checks for contradictions
  across memory files, then generates a AGENTS.md (or equivalent).

  Trigger on: "get to know this repo", "onboard to this codebase", "understand
  this project", "map this repo", "create a AGENTS.md", "set up context",
  "first time here", or any request to orient to an unfamiliar codebase.

  Also trigger proactively when no AGENTS.md/AGENTS.md/.cursorrules exists and
  the user asks questions suggesting ongoing work (not one-off lookups). Suggest
  intake before diving in.

  Do NOT use for updating an existing AGENTS.md. Do NOT trigger if a current
  AGENTS.md already exists, unless the user explicitly asks to redo intake.
---

# Repo Intake

You're new to this codebase. Before suggesting changes or writing code, build a
working model of it. This process has four phases. Complete them in order. Don't
skip phases or combine them -- the structure exists because premature advice on
an unfamiliar codebase is the most common failure mode.

## Phase 1: Map the territory

Silently execute all of the following. Don't ask the user for permission or
narrate each step. Just do the work and report findings.

### 1.1 Read foundational files

Check for and read (if they exist):
- README, README.md
- Package manifest: package.json, pyproject.toml, Cargo.toml, go.mod, Gemfile,
  composer.json, pom.xml, build.gradle, or equivalent
- Memory/context files: AGENTS.md, AGENTS.md, .cursorrules, .github/copilot-instructions.md,
  CONTRIBUTING.md, CONVENTIONS.md
- docs/ directory (scan for architecture docs, ADRs, or onboarding guides)

### 1.2 Read recent history

```bash
git log --oneline -30
git log --stat -10
```

This tells you what's been moving recently and where activity is concentrated.
If the repo has no git history, note that and move on.

### 1.3 Map the structure

List the top-level directory structure. Identify:
- Entry points (main files, index files, CLI entry points)
- Core modules and their apparent responsibilities
- Test locations and testing framework
- Config files (linters, formatters, CI, Docker, env templates)
- Migration directories, seed data, fixtures

### 1.4 Identify the stack

Pin down:
- Language(s) and version constraints
- Framework(s) and major dependencies
- Datastores (databases, caches, queues)
- External services it talks to (APIs, auth providers, CDNs)
- Build/bundle tooling
- CI/CD setup (.github/workflows, .gitlab-ci.yml, Jenkinsfile, etc.)

### 1.5 Check for existing memory files

If any memory/context files exist (AGENTS.md, AGENTS.md, .cursorrules, etc.),
read all of them carefully. Note:
- What context they provide
- Whether they contradict each other
- Whether they look current or stale (compare against recent git activity)
- What conventions or constraints they declare

You'll flag contradictions in Phase 3.

### Phase 1 output

Present a concise summary of what you found. Structure it as:
- **Project:** one-line description of what this appears to be
- **Stack:** language, framework, key deps, datastores
- **Structure:** the major directories and what lives in each
- **Recent activity:** where commits have been concentrated
- **Existing context files:** list what exists, note if anything looks stale or contradictory
- **Gaps:** what you couldn't determine from the code alone

Keep this tight. No filler. The user already knows their own repo -- they're
checking whether you understood it correctly.

---

## Phase 2: Ask targeted questions

Based on your Phase 1 findings, ask 3-7 questions about things you genuinely
cannot infer from the code. The questions should be specific and grounded in
what you observed.

**Good questions reference what you saw:**
- "I see a `legacy/` directory that hasn't been touched in 6 months. Is that
  intentionally frozen, or just neglected?"
- "The CI runs tests but I don't see a deployment step. Where does this get
  deployed, and how?"
- "There are two auth patterns -- JWT in `api/` and session-based in `web/`.
  Is that intentional or mid-migration?"

**Bad questions are generic:**
- "What are your goals for this project?"
- "What coding style do you prefer?"
- "Can you tell me about the architecture?"

These are bad because either the code already answers them, or they're too vague
to produce useful answers.

**Always include these two unless the code already answers them:**
1. What's the one-sentence purpose of this project, and who uses it?
2. What's currently broken, annoying, or on your mind that brought you here today?

**If existing memory files were found, ask about contradictions:**
- "AGENTS.md says X but AGENTS.md says Y -- which is current?"
- ".cursorrules specifies tabs but the formatter config uses spaces. Which wins?"

Wait for the user to answer before proceeding. Do not guess at answers or
proceed with assumptions.

---

## Phase 3: Reflect back

After the user answers, synthesize everything into a summary. Present it as a
bulleted list covering:

- **What this codebase does** (in the user's terms, not just technical description)
- **Architecture in broad strokes** (how the pieces connect)
- **Conventions and constraints** (the rules, explicit or implicit)
- **Current state** (what's working, what's rough, where effort is focused)
- **Things you'd flag** (where you'd push back or suggest alternatives if asked
  to make changes -- be specific, not vague "could be improved" statements)

If existing memory files had contradictions, call them out explicitly here so
the user can resolve them before they get baked into the new file.

End with: **"Is this accurate? Correct anything that's wrong before I write
the context file."**

Do not proceed until the user confirms or corrects.

---

## Phase 4: Write the context file

### Choose the format

- If the user specified a format (AGENTS.md, AGENTS.md, etc.), use that.
- If existing memory files are present and the user wants to consolidate, write
  AGENTS.md and note which files it supersedes (don't delete them -- the user will).
- Default to AGENTS.md if no preference is stated.

### File structure

Use this structure, but skip sections that would just restate the README or
other existing docs. The file earns its keep by capturing context that ISN'T
already written down elsewhere.

```markdown
# [Project name] -- Context for Codex

## What this is
One paragraph: what the project does, who uses it, why it exists.

## Stack and architecture
Language, framework, key dependencies, datastores, external services.
3-5 bullets on how the pieces fit together.

## Repo layout
Top-level directories and what lives in each. Entry points. Where tests
live. Where config lives. Only include this if the structure isn't obvious
from directory names.

## Conventions
Patterns that matter: naming, file organization, error handling, logging,
commit style. Focus on things that aren't enforced by linters but the user
cares about. Include the "we always do X this way" rules.

## Constraints and gotchas
Legacy code that's off-limits. Files that look wrong but are intentional.
External dependencies that are flaky. Decisions that have context behind
them that isn't obvious.

## Development workflow
- How to run locally
- How to run tests
- How to deploy (or where that's documented)
- Linter/formatter commands

## Current focus
What the user is working on or thinking about right now. Keep this vague
enough to stay true for weeks, not days.

## How to work in this repo
- Fix what's asked. If you see a bigger structural issue that the fix
  touches, name it briefly and ask before refactoring.
- If a change conflicts with patterns elsewhere in the repo, flag it
  before writing code.
- Follow existing patterns. If three files do X one way, do X that way.
- Read before guessing. If uncertain whether a file/function exists or
  behaves a certain way, read it.
```

### After writing

1. Show the user the full file content.
2. Ask them to correct anything that's off.
3. Apply corrections.
4. Write the file to the repo root.

If contradictions existed between other memory files, remind the user which
files conflict and suggest they reconcile or remove the stale ones. Don't
delete or modify other memory files yourself.

---

## Edge cases

**Monorepo:** If the repo has multiple distinct projects (e.g., `packages/`,
`apps/`, `services/`), ask the user whether they want one top-level AGENTS.md
or per-project files. For a top-level file, keep architecture broad and note
which sub-projects have their own conventions.

**Empty or near-empty repo:** If there's almost nothing to map (< 5 files, no
meaningful structure), skip Phase 1 and go straight to Phase 2. The questions
become more important here because the code can't tell you much.

**User says "just make the file":** If they want to skip the interactive phases,
do Phase 1 silently, write the best AGENTS.md you can from code alone, show it
to them, and let them correct it. Flag clearly that sections are based on
inference and may be wrong.

**User already has a thorough AGENTS.md:** Don't trigger. This skill is for
first contact only. If the user explicitly asks to redo intake with an existing
file, rename the old one to AGENTS.md.bak before writing the new one.
