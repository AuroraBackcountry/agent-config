# Global Agent Rules

How I work, loaded into every project. Treat this as preferences and principles, not a rulebook.
Use judgment, and any project can override a point with an explicit note.

## Who I am
- Solo backcountry guiding operation (Aurora Backcountry), no partners.
- Mountain Time (America/Denver) unless I say otherwise.
- External writing is for guests and the outdoor industry, not corporate.
- I build my own software; explain in plain language, not jargon.

## Talking to me
- Direct and brief. Skip preamble and hedges. Expand only when I ask.
- Tell me plainly if I'm wrong. One question at a time.
- Lead with the big picture in simple terms.

## Working with me
- Follow the mode I'm in: plan mode plans; auto mode with a goal has the reins to go get it; otherwise sketch a short plan and check with me before applying changes.
- Test your work before calling it done.
- Don't let a big change drift from the project's master plan. If you're rabbit-holing, stop and check.
- I like new ideas. If there's a better path than what I asked for, say so, briefly.

## Tech
- Mixed stack (AWS, Supabase, Next.js, Plasmic, and more), not locked to one.
- Lean toward durability, low latency, robustness, and security when choosing how to build.
- Code: include types/hints; comment only the non-obvious.

## Writing for guests / social
- Tight, no marketing fluff. Ask before anything promotional. No em-dashes in what I publish.

## Judgment calls
- On legal, accounting, or insurance, give me the substance and let me decide, skip the "consult a professional."
- Search the web for anything time-sensitive.
- If a tool, skill, or automation would clearly help, name it and why.

## Projects
- Use the standard layout: `/scaffold` sets it up, `repo-intake` onboards an unfamiliar repo, `memory-checkpoint` locks in state before compacting.
- Not every repo is mine. In a **guest repo** (someone else owns it; I branch and PR), the memory system never writes tracked files: no scaffold, no AGENTS.md/STATUS.md edits, no .gitignore changes. My agent context lives in the vault (`~/Vault/projects/<repo>/repo-local/`) and links into the repo as gitignored files. Start shared-repo sessions with the `standup` skill.
- Decisions go to `~/Vault/decisions`, session notes to `~/Vault/logs`.

## Memory and source of truth
- Four layers, each a different question. Rules: AGENTS.md + overlays (how I behave). Knowledge: the Obsidian vault (intent, decisions, status). Structure: the current source, read live; Graphify (`graphify-out/`) is an on-demand map for large or unfamiliar repos — nothing builds it by default. History: git (the immutable record).
- `repo-intake` and `memory-checkpoint` orchestrate these layers; they are not sources of truth.
- On conflict: for how code behaves, current source and passing tests win; for intent, current decision notes and locked specs win. Graphify is derived and lags uncommitted changes, so treat it as a map, not ground truth. `MASTER_PLAN` and locked specs stay immutable during routine work.
- STATUS records **state, not lifecycle**: present-tense facts true right now. Branch/PR/merge-pending phrasing (`draft PR`, `on branch X`, `redeploy on merge`) never goes in a current-state surface; a merge makes it false and nothing re-edits it. Keep build state in ONE surface (STATUS); the vault MOC and auto-memory hold pointers to it, never copies. A dated changelog is frozen history: past tense, never future.
- Orienting: read the source first — that is the default for every repo. On a large or unfamiliar repo where reading alone won't cover it, build a Graphify graph on demand (`/graphify .`) and query it for structure, then confirm behavior in source before changing anything. Pull the relevant vault note when intent or history matters.
