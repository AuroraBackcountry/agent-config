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
- Skills and plugins are tools, not gates: use one when it clearly fits. My rules (brief, Ponytail's smallest change, auto mode's reins) win over any skill's ceremony; a question or a one-line fix needs no skill check or brainstorm.

## Tech
- Mixed stack (AWS, Supabase, Next.js, Plasmic, and more), not locked to one.
- Lean toward durability, low latency, robustness, and security when choosing how to build.
- Code: include types/hints; comment only the non-obvious.
- Browser work has two tools, don't deliberate per task. `playwright-cli` (the `playwright-cli` skill) is the default driver: cross-browser, ref-based interaction, sessions, request mocking, and it generates/heals the `@playwright/test` suites I already have. `chrome-devtools-mcp` is Chrome-only and for diagnosis: performance traces, Core Web Vitals, network inspection, console with source-mapped stacks, heap snapshots, Lighthouse. Rule of thumb: Playwright tells me the flow broke, chrome-devtools tells me why it's slow or why a request failed.

## Writing for guests / social
- Tight, no marketing fluff. Ask before anything promotional. No em-dashes in what I publish.

## Judgment calls
- On legal, accounting, or insurance, give me the substance and let me decide, skip the "consult a professional."
- Search the web for anything time-sensitive.
- If a tool, skill, or automation would clearly help, name it and why.

## Projects
- Use the standard layout: `/scaffold` sets it up, `repo-intake` onboards an unfamiliar repo, `memory-checkpoint` locks in state before compacting.
- Not every repo is mine. In a **guest repo** (someone else owns it; I branch and PR), the memory system never writes tracked files: no scaffold, no AGENTS.md/STATUS.md edits, no .gitignore changes. My agent context lives in the vault (`~/Vault/projects/<project>/repo-local/`) and links into the repo as gitignored files. Start shared-repo sessions with the `standup` skill.
- A ruling goes in the body of the commit that makes it, one line: the decision and why. My repos squash with the commit messages, so it reaches main; a PR body does not, so PRs carry no Decisions section (a guest repo: also the PR description, since its squash setting is theirs). `~/Vault/decisions` takes only personal or cross-repo decisions; session notes go to `~/Vault/logs`. The vault cites a PR number or the merge commit, never a branch commit id (the branch dies at the merge). A decision with no commit to ride on goes in STATUS.md on the next working branch.

## Memory and source of truth
- Four layers, each a different question. Rules: AGENTS.md + overlays (how I behave). Knowledge: the Obsidian vault (intent, decisions, status). Structure: the current source, read live; Graphify (`graphify-out/`) is an on-demand map for large or unfamiliar repos — nothing builds it by default. History: git (the immutable record).
- `repo-intake` and `memory-checkpoint` orchestrate these layers; they are not sources of truth.
- One project key, derived one way: the **main repo's directory name**, from `git rev-parse --git-common-dir` (so a worktree files under its parent repo, not under its own throwaway name); the folder name only when there is no repo. One alias, because one repo is cloned twice: a directory named `.agents` files under `agent-config`. Vault logs, decisions, the project MOC and session traces all key off that same string, so deriving it differently anywhere splits one project's memory into two.
- On conflict: for how code behaves, current source and passing tests win; for intent, current decision notes and locked specs win. Graphify is derived and lags uncommitted changes, so treat it as a map, not ground truth. `MASTER_PLAN` and locked specs stay immutable during routine work.
- STATUS records **state, not lifecycle** and is the one home of build state: present tense, no PR numbers or build/update ids, Now block first (read it first, the rest only when needed), under 300 lines and 25 KB. Side files that hold status (a ledger, a walk list) are named on its `Status docs:` line and keep the same rule; status-lint checks the changed lines before each commit and in CI. Its edit rides the PR it describes, never a PR of its own. Memory and the vault point to it, never copy it or record merges. Full rule: `/save` step 3.
- One home per fact; every other place points to it. STATUS Now: one pointer line per active thing, no feature description. A ledger: one status word per phase and where it runs. A walk list: a walk's steps only; a feature's PR walks its agent-runnable legs (web, emulator) before merge, so only legs that need me land there, and a walk that passes deletes its line. The phase or spec file: the detail, what shipped, the limits. How-to notes (fixtures, intercepts, stubs): beside the code they are about. Vault logs link the PR and never restate state. Memory: only what the repo cannot hold.
- Orienting: read the source first — that is the default for every repo. On a large or unfamiliar repo where reading alone won't cover it, build a Graphify graph on demand (`/graphify .`) and query it for structure, then confirm behavior in source before changing anything. Pull the relevant vault note when intent or history matters.
