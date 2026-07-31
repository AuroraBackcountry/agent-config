# agent-config

A portable, personal AI-agent setup you can fork and make your own: **one canonical
rules file** shared across Claude Code, Codex, and Cursor, plus skills, slash commands,
session hooks, a project scaffold, and a plain-markdown memory layer that survives
between sessions.

Written by one solo developer for real daily use, published so anyone can adopt the
structure. The rules content is mine — the point is that you replace it with yours.

## The idea: four memory layers

AI coding sessions forget everything. This repo organizes durable memory into four
layers, each answering a different question:

| Layer | Question | Lives in |
|---|---|---|
| **Rules** | How should the agent behave? | `AGENTS.md` + per-tool overlays, baked into each tool's global config by `sync.sh` |
| **Knowledge** | What was decided, and why? | A local vault (`~/Vault`) — plain markdown folders under git (the SessionEnd hook snapshots it each session); Obsidian is a nice viewer, not a requirement |
| **Structure** | How does the code connect? | A derived code graph per repo (`graphify-out/`, gitignored), kept fresh by a post-commit hook |
| **History** | What actually happened? | git — the immutable record |

Skills like `repo-intake` (onboard a repo) and `memory-checkpoint` (reconcile state
before compacting context) orchestrate the layers; they are not sources of truth.
One convention does a lot of work here: **status surfaces record state, not
lifecycle** — present-tense facts that stay true, never "draft PR / merge pending"
phrasing that a merge silently invalidates.

## What's here

    AGENTS.md            Canonical rules: how I work. The shared 90%. REPLACE WITH YOURS.
    overlays/            Per-tool notes (the 10%): claude, codex, cursor.
    rules/               Pinned shared rules baked into the globals by sync.sh (ponytail).
    skills/              Skills, authored + vendored (symlinked into ~/.claude/skills;
                         .skill-lock.json tracks the npx-skills-vendored ones, and
                         THIRD_PARTY_LICENSES.md attributes all vendored components).
    commands/            Global slash commands: /scaffold, /save, /recall.
    hooks/               session-end.sh (vault breadcrumb + session trace) and
                         graphify-post-commit.sh (background code-graph refresh).
    templates/project/   The standard per-repo skeleton (AGENTS.md, STATUS.md, .claude/).
    plugins.md           Marketplace plugins to install (not vendored here).
    scaffold.sh          Lay the standard layout into a project (non-destructive).
    sync.sh              Regenerate the global Claude + Codex files from canonical.
    install.sh           Wire everything into this machine (backs up first).
    cloud-setup.sh       Headless subset of install.sh for ephemeral cloud VMs
                         (run by the SessionStart hooks; never syncs the vault).

**Tool support is not symmetrical.** The shared rules reach all three tools. Skills,
slash commands, hooks, and the vault workflow (`/save`, `/recall`) are Claude
Code-only. Codex gets one baked rules file; Cursor gets a manual paste.

## Prerequisites

Required: `bash`, `git`, and [Claude Code](https://claude.com/claude-code) (the main
consumer — without it the install still succeeds but nothing reads the files).

Optional — each degrades gracefully if absent:

- **`graphify` CLI** (`pip install graphifyy` or `uv tool install graphifyy`) — powers
  the code-graph layer and the post-commit refresh hook. Without it the hook silently
  no-ops and you simply have no Structure layer.
- **`python3`** — enriches the session-end trace (transcript parsing). Breadcrumbs work without it.
- **`jq`** — only used to merge the SessionEnd hook into an *existing*
  `~/.claude/settings.json`; without it you get the JSON to paste by hand.
- **GitHub CLI (`gh`)** — powers the `standup` skill and the ownership check in
  `repo-intake`'s guest-repo mode; without it those fall back to asking you.
- **Node** — only for updating vendored skills via [`npx skills`](https://github.com/vercel-labs/skills).
- **Obsidian** — optional viewer for the vault. The vault is just markdown folders.

Platform: macOS and Linux. The graph-refresh hook's CPU guard is macOS-only (it
silently skips on Linux — see the `ponytail:` note in `hooks/graphify-post-commit.sh`).
Windows: use WSL; native Git-Bash symlinks are unreliable.

## Install

> **Personalize before you install.** `install.sh` bakes `AGENTS.md` into your global
> `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, and swaps your `~/.claude/skills`
> and commands for this repo's (existing files are backed up to
> `<file>.bak.<timestamp>`, never deleted — but your own rules stop applying until
> you restore them).

```bash
# 1. Fork this repo, then clone your fork to ~/.agents
git clone https://github.com/<you>/agent-config ~/.agents
cd ~/.agents

# 2. Make it yours (see next section) — edit AGENTS.md at minimum

# 3. Wire it in (re-runnable; backs up anything it touches)
./install.sh
```

Manual step for Cursor: paste `generated/cursor-user-rules.md` (built by `sync.sh`)
into Cursor Settings > Rules > User Rules (Cursor has no on-disk global file).
`./sync.sh --check` reports when any baked output is stale.

## Make it yours

- **`AGENTS.md`** — rewrite *Who I am*, *Talking to me*, *Tech*, *Writing*, and
  *Judgment calls* in your own voice. Keep *Projects* and *Memory and source of truth*
  if you adopt the memory system — the skills depend on those conventions. (References
  to `MASTER_PLAN` / locked specs apply only to repos that keep one.)
- **`overlays/*.md`** — per-tool preferences; edit to taste.
- **`rules/ponytail.md`** — an opinionated vendored coding ruleset baked into every
  session. Delete it if it's not your style (`sync.sh` handles its absence).
- **Vault location** — defaults to `~/Vault`; override with `VAULT_DIR`.
- **`plugins.md`** — my marketplace shopping list; replace with yours.
- **`skills/`** — prune what you won't use (`graphify` needs the CLI installed).
  `.skill-lock.json` tracks the npx-skills-vendored ones; `THIRD_PARTY_LICENSES.md`
  attributes everything vendored.
- **Personal skills you don't want published:** keep the real folder outside the repo
  (the vault works — it's local and versioned), symlink it into `skills/`, and add the
  symlink's name to `.gitignore`. The global `~/.claude/skills` link follows it, so the
  skill stays live while the repo stays clean. Re-clone the repo and it's one `ln -s`
  to restore.

Then run `./sync.sh` to regenerate the globals whenever you change rules or overlays.

## How the globals are wired

The global Claude (`~/.claude/CLAUDE.md`) and Codex (`~/.codex/AGENTS.md`) files are
GENERATED by `sync.sh` (canonical + pinned rules + the tool's overlay, concatenated).
They are baked, not imported, because Claude's `@import` was unreliable for
home/absolute paths when this was built. A generated header marks them; edit
`AGENTS.md` or an overlay, never the generated file. Per-repo `CLAUDE.md` still uses
the reliable relative `@AGENTS.md` import.

## Daily use

- New project: run `/scaffold` in Claude Code, or `~/.agents/scaffold.sh` in the repo.
  It lays down `AGENTS.md`, a `STATUS.md` (the single build-truth surface), `.claude/`
  scaffolding, and installs the graph-refresh hook.
- Change how you work: edit `AGENTS.md` (or an overlay), then run `./sync.sh`.
- Save context: `/save` writes a session log + decisions into the vault. The
  SessionEnd hook also traces every session automatically (branch, changes, transcript
  path, first prompt) so a forgotten `/save` still leaves a searchable record.
- Resume context: `/recall` reads the recent vault notes for the current project.
- Onboard an unfamiliar repo: the `repo-intake` skill maps it, builds the code graph,
  writes its `AGENTS.md`, and wires the vault. On a repo you don't own it goes
  vault-first: context lives in `~/Vault/projects/<repo>/repo-local/` and links into
  the repo as gitignored files — nothing lands in the owner's tracked tree.
- Start a session on a repo you share with others: the `standup` skill — is my memory
  intact, what changed while I was gone, who is in which files, any migration drift.
- Before compacting a long session: the `memory-checkpoint` skill reconciles
  `STATUS.md` + vault against git so nothing is lost.
- Add a marketplace plugin: install via `/plugin`, then record it in `plugins.md`.

## Cloud sessions

Claude Code on the web runs in an ephemeral VM — nothing `install.sh` wired into
your laptop exists there. Two `SessionStart` hooks close the gap, both no-ops on
a local machine (they check `CLAUDE_CODE_REMOTE`):

- **This repo:** `.claude/hooks/session-start.sh` runs `cloud-setup.sh` when a
  cloud session boots on agent-config itself — bakes the rules into the VM's
  global `CLAUDE.md`, links skills and slash commands, seeds the machine-wide
  git ignore.
- **Scaffolded repos:** the project template ships the same hook. It clones your
  agent-config fork and runs `cloud-setup.sh`. Set `AGENTS_REPO` to your fork's
  clone URL in the cloud environment's settings, and make sure the environment
  can reach it (public fork, or added to the environment's repositories).
  Without `AGENTS_REPO` the hook is a silent no-op and the session simply runs
  without the personal layer.

**The vault stays home, on purpose.** It holds secrets (`repo-local/` carries
`.env` files) and never leaves your own machine, so cloud sessions run without
the Knowledge layer: `/save` and `/recall` hit an empty `~/Vault` that dies with
the VM, and the SessionEnd breadcrumb hook is not wired. Anything worth keeping
from a cloud session should be committed to the repo, or added to the vault by
hand later.

## Uninstall

Reverse everything `install.sh` did:

1. Restore the `.bak.<timestamp>` files it created (including
   `~/.claude/settings.json.bak.*` if the SessionEnd hook was merged into an
   existing settings file).
2. Remove the `~/.claude/skills` symlink and the per-command symlinks in
   `~/.claude/commands`.
3. Remove the SessionEnd hook entry from `~/.claude/settings.json` — on a machine
   where no settings file existed before install, `install.sh` created it, so
   delete the entry (or the file) by hand; there is no `.bak` for that case.
4. If `~/.claude/CLAUDE.md` or `~/.codex/AGENTS.md` carry the `GENERATED by
   ~/.agents` marker and no `.bak` exists (fresh machine), delete them — they were
   generated by `sync.sh`, not backed up from anything.
5. `~/.agents/.git/hooks/post-commit` (the sync-on-commit hook) disappears with the
   clone. Scaffolded repos keep their graphify line in their own post-commit hooks;
   remove that line per repo if you want it gone.

## What is committed vs personal

Per repo, these stay out of git:
`CLAUDE.local.md`, `AGENTS.override.md`, `.claude/settings.local.json`, `graphify-out/`.
Two layers enforce it: the template `.gitignore` (repos you scaffold) and the
machine-wide git ignore (`~/.config/git/ignore`, seeded by `install.sh`) — the latter
covers repos you don't own, where the template never lands and editing the owner's
`.gitignore` would cost them a review.

Never commit secrets (API keys in MCP configs, `~/.codex/config.toml`). A private repo
is not the same as safe to leak — and this one is public.

## De-dup rules (why things live where they do)

GUI installs (claude.ai web, Cowork desktop) and the Claude Code CLI use separate
storage that does not sync. To avoid fragmentation:

1. Skills live only in `skills/` here, symlinked to `~/.claude/skills`.
2. Marketplace plugins (e.g. superpowers) are installed via `/plugin` and listed in
   `plugins.md`. Do not copy them into `skills/`.
3. Cowork and web are separate surfaces; install there via their GUIs if you want them.

## Credits

Vendored components, all MIT — full texts in
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md):
[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) (defuddle),
[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (graphify skill),
[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (ponytail rules).

## License

MIT — see [LICENSE](LICENSE).
