---
name: repo-intake
description: >
  Get a repo ready to work in, doing the right thing based on what's already there.
  For an unfamiliar repo: asks what you're here to do, maps the code (building a
  Graphify graph), writes the canonical AGENTS.md, records it in your Obsidian vault,
  and proposes a first task. For a repo that's already documented but not yet wired
  into your memory layer (a real AGENTS.md/MASTER_PLAN but no vault space or code
  graph): it just wires those in and leaves the existing docs alone.

  Use whenever you pick up a codebase and want it set up: "get me set up on this repo",
  "onboard me", "I cloned/forked this", "map this repo", "set up context here", "wire
  this into the vault", "create the AGENTS.md". Also trigger proactively when a repo
  has no AGENTS.md/CLAUDE.md/.cursorrules and you start real work.

  NOT for refreshing already-current memory (that's memory-checkpoint) or greenfield
  scaffolding (that's /scaffold). If a repo is already documented AND wired, nothing to do.
---

# Repo Intake

You've just picked up a codebase -- handed to you, forked, or cloned -- and you need
to go from zero to productively working in it. This skill takes you there in one pass:
understand the repo, write it down where every tool will see it, record it in the
vault, and line up a first task. Work the phases in order. The discipline is what
prevents premature, wrong-headed advice on code you don't yet understand.

**How context and memory are organized here.**
- The repo's canonical context file is `AGENTS.md` at the root. `CLAUDE.md` is a
  one-line `@AGENTS.md` import, and Codex and Cursor read `AGENTS.md` too. One real
  file, not three.
- The user's *global* rules (how they work, their style) live in `~/.agents/AGENTS.md`
  and load every session, so this repo's `AGENTS.md` captures only what's true about
  THIS codebase and never restates the global rules.
- Durable project memory lives in the Obsidian vault at `~/Vault/projects/<repo>/`
  (`VAULT_DIR` overrides `~/Vault`).
- Tools to lean on: the Graphify code graph (`/graphify`) and the obsidian skills for
  vault notes. If either isn't installed, degrade gracefully -- say so and continue.

## Phase 0: Locate the code

This skill often runs from a bare trigger -- the user may say almost nothing, just invoke
it while sitting in a repo, or drop a repo URL into an empty folder. Don't wait for a
detailed brief; work out the situation yourself.

- **Inside a populated git repo** (files present, `git rev-parse` succeeds): that's the
  target. Continue.
- **Empty or near-empty folder plus a repo URL** (pasted now or earlier in the conversation):
  clone it, then continue.
  ```bash
  git clone <url> .      # into the empty folder; use a subfolder if it isn't empty
  ```
- **Empty folder, no URL:** ask for the repo URL or a local path -- one question, then continue.
- **A local path was given:** treat that as the target and continue.

With the code in place, pick the mode below.

## Which mode: onboard, wire, or nothing

Check what memory already exists, then route:
- **No real context file** (no AGENTS.md/CLAUDE.md/.cursorrules, or only a `/scaffold` stub) ->
  **full onboard**: do Phases 1-7 below.
- **A real, filled-in context file already** (AGENTS.md, CLAUDE.md, a MASTER_PLAN/STATUS system)
  but **not wired into the memory layer** (no `~/Vault/projects/<repo>/`, or no `graphify-out/`) ->
  **wire-only**: skip the onboarding phases and jump to "Wire an already-documented repo" near the
  end. Do NOT re-onboard or rewrite the existing docs; they're the source of truth and probably
  better than anything you'd write.
- **Already documented AND wired** (context file + vault space + graph): nothing to onboard. If the
  memory looks stale, hand off to `memory-checkpoint`; otherwise just say it's set.

## Phase 1: Capture intent (ask first)

Before mapping anything, get the "why." Ask one or two short questions and wait:
- "What is this repo, and how did it come to you -- handed off, forked, cloned?"
- "What are you trying to do here -- a feature, a fix, a review, or just understand it?"

This frames the whole intake: an "add a feature" intent reads a repo differently than a
"review it for security" intent. Keep it to a couple of questions, don't interrogate. If
the user already stated their goal, reflect it back in one line and go straight to Phase 2.

## Phase 2: Map the territory and build the code graph

Silently do the following. Don't ask permission or narrate each step -- do the work and
report findings.

### 2.1 Build the code graph
If Graphify is available, build it first. It gives you structure cheaply and steers the
rest of the read:
```bash
/graphify .
```
That writes `graphify-out/` (gitignored): `graph.json`, `GRAPH_REPORT.md`, `graph.html`.
Read `graphify-out/GRAPH_REPORT.md` for the structural overview, and use
`graphify query "..."` or `graphify explain "..."` to trace specific connections instead
of opening every file. If Graphify isn't installed, skip this, map by reading, and note
that the graph would have helped.

### 2.2 Read foundational files
- README(s); package manifest (package.json, pyproject.toml, Cargo.toml, go.mod, etc.)
- Existing memory/context files: AGENTS.md, CLAUDE.md, .cursorrules,
  .github/copilot-instructions.md, CONTRIBUTING.md, CONVENTIONS.md
- docs/ (architecture, ADRs, onboarding guides)

### 2.3 Recent history, structure, and stack
```bash
git log --oneline -30
git log --stat -10
```
Note where activity concentrates. List the top-level structure: entry points, core
modules, tests, config, migrations. Pin the stack: languages and versions, frameworks,
datastores, external services, build tooling, CI/CD.

### 2.4 Existing memory files
Read any that exist. Note what they cover, whether they look current or stale (against
recent git activity), and whether they *genuinely* conflict. NOT a conflict: a `CLAUDE.md`
whose whole content is `@AGENTS.md` is the standard import, not a competing source --
treat `AGENTS.md` as the real file. Skip any file with a "GENERATED by ~/.agents" header;
never edit it.

### Phase 2 output
Report a tight summary, oriented around the Phase 1 intent:
- **Project:** one line. **Stack.** **Structure.** **Recent activity.**
- **Existing context files:** what exists, note anything stale or contradictory.
- **Gaps:** what you can't infer from the code alone.

Keep it tight. The user knows their repo -- they're checking whether you understood it.

## Phase 3: Targeted questions

Ask 3-7 specific questions, grounded in what you saw and pointed at the intent. Good ones
reference the code:
- "There are two auth patterns -- JWT in `api/`, sessions in `web/`. Intentional or mid-migration?"
- "CI runs tests but I see no deploy step. Where and how does this ship?"

Skip generic questions (project goals, coding style -- style already lives in the global
rules). Always ask these two unless already answered:
1. The one-sentence purpose and who uses it (if Phase 1 didn't cover it).
2. What's rough, risky, or off-limits that I should know before changing anything?

If files genuinely conflict, ask which wins. Wait for answers before proceeding; don't
guess.

## Phase 4: Reflect back

Synthesize everything into a short summary:
- **What this codebase does** (in the user's terms)
- **Architecture in broad strokes** (how the pieces connect)
- **Conventions and constraints** (explicit and implicit)
- **Current state** (working, rough, where effort is focused)
- **Things you'd flag** (specific, not vague "could be improved")

Call out any real contradictions so they get resolved before they're written down. End
with: **"Is this accurate? Correct anything before I write it down."** Don't proceed until
the user confirms or corrects.

## Phase 5: Write the canonical AGENTS.md

Write `AGENTS.md` at the repo root -- the file every tool reads.
- **Scaffolded repo** (stub `AGENTS.md` plus a `CLAUDE.md` that says `@AGENTS.md`): fill in
  the stub, leave `CLAUDE.md` as the import.
- **Not scaffolded:** write `AGENTS.md`, then either run `/scaffold` for the full structure
  or add a one-line `CLAUDE.md` containing `@AGENTS.md` so Claude Code picks it up too.

This is repo-level context layered on the user's global rules -- don't restate global
preferences. Skip sections that would just restate the README. Use this structure:

```markdown
# [Project name]

## What this is
One paragraph: what it does, who uses it, why it exists.

## Stack and architecture
Language, framework, key dependencies, datastores, external services. 3-5 bullets on how
the pieces fit together.

## Repo layout
Top-level directories and what lives in each. Entry points. Where tests and config live.
Only include this if it isn't obvious from directory names.

## Conventions
Naming, file organization, error handling, logging, commit style. The "we always do X this
way" rules that aren't enforced by linters.

## Constraints and gotchas
Legacy code that's off-limits. Things that look wrong but are intentional. Flaky
dependencies. Decisions with non-obvious context behind them.

## Development workflow
- How to run locally
- How to run tests
- How to deploy (or where that's documented)
- Linter/formatter commands

## Current focus
What the user is working on now (from Phase 1). Vague enough to stay true for weeks.

## How to work in this repo
- Fix what's asked. If a bigger structural issue is in the blast radius, name it and ask
  before refactoring.
- If a change conflicts with patterns elsewhere, flag it before writing code.
- Follow existing patterns. If three files do X one way, do X that way.
- Read before guessing. If unsure a file/function exists or behaves a certain way, read it.
```

Show the full file, take corrections, then write it (and the one-line `CLAUDE.md` import if
it wasn't already there).

## Phase 6: Wire project memory into the vault

Record the project so it survives across sessions. Create `~/Vault/projects/<repo>/` and
write a project MOC (map of content) at `README.md` with:
- A 5-10 line summary of what the repo is and the user's current goal.
- A pointer to the repo's `AGENTS.md` (the canonical context) and, if built, the key
  modules from `graphify-out/GRAPH_REPORT.md`.
- An **Open questions** section (anything unresolved from Phase 3).
- A **Decisions** section, seeded with any architectural decisions surfaced during intake.
- A **Next** section (filled in Phase 7).

Use the obsidian skills (obsidian-cli / obsidian-markdown) for wikilinks and search if
they're installed; otherwise just write the markdown files directly -- the vault is a
folder of markdown, so writing files IS updating it. Keep the graph itself in the repo
(`graphify-out/`, gitignored); the vault holds the human-readable memory.

## Phase 7: Propose the first task

Now that you understand both the repo and the intent, propose a concrete starting point --
one first task or phase, not a whole project plan:
- State the first task in a line or two, tied directly to the user's intent.
- Name the 2-3 files or areas it will touch (use the graph).
- Flag any risk or unknown to resolve before starting.

Record it under **Next** in `~/Vault/projects/<repo>/README.md`. Then ask whether they want
to start it now, or -- if it's big enough to warrant a real plan -- hand off to a planning
skill (superpowers' brainstorming or writing-plans). Don't over-plan here; the job is to
remove the "where do I even start" friction.

## Wire an already-documented repo (wire-only mode)

The repo already explains itself (a real AGENTS.md, maybe a MASTER_PLAN/STATUS system). Don't
touch that -- it's the source of truth and better than anything you'd write. Just connect it to
the memory layer:

1. **Build the code graph** if it's missing: `/graphify .` (writes `graphify-out/`, gitignored).
2. **Create the vault project space** at `~/Vault/projects/<repo>/` with a MOC that *points at*
   the repo's own docs (AGENTS.md, MASTER_PLAN, STATUS, ARCHITECTURE) -- an index, not a
   re-summary. Never duplicate the north star. Link the key modules from the graph report, list
   any open questions, and add a "Next" line only if the plan makes the next step obvious.
3. **Quick drift check** (the same doctor pass as memory-checkpoint): if `CLAUDE.md` and
   `AGENTS.md` are duplicate copies, collapse `CLAUDE.md` to `@AGENTS.md`; fix any find-replace
   corruption (verify suspect tokens against the code); flag stale sections -- but never edit an
   immutable master plan or locked spec.
4. Report what you wired (graph built, vault MOC created, anything reconciled). The repo is now in
   the memory layer without a re-onboarding.

## Edge cases

- **Monorepo:** multiple distinct projects (packages/, apps/, services/) -- ask whether they
  want one top-level `AGENTS.md` or per-project files; keep the top-level one broad.
- **Empty or near-empty repo:** skip the mapping, lean on the Phase 1 intent and Phase 3
  questions, and flag that the file is inference-heavy.
- **"Just set it up":** run Phase 2 silently, write the best `AGENTS.md` from the code, flag
  guessed sections, still create the vault space and propose a first task.
- **Already has a filled-in AGENTS.md:** don't re-onboard. If it's not wired into the memory
  layer yet, use wire-only mode above (graph + vault, leave the docs alone). A scaffolded stub
  (just template placeholders) doesn't count as filled in -- do a full onboard to fill it. Only
  redo a full onboard over a real file if the user explicitly asks, renaming the old to
  `AGENTS.md.bak` first.
- **Tools missing:** if Graphify or the obsidian skills aren't installed, say so, skip that
  step, and continue -- the intake still works, just with less automation.
