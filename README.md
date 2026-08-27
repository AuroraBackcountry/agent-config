# agent-config

A portable, personal AI-agent setup you can fork and make your own: **one canonical
rules file** baked into Claude Code's global config (with a Cursor overlay you can
paste in by hand), plus skills, slash commands, session hooks, a project scaffold,
and a plain-markdown memory layer that survives between sessions.

Written by one solo developer for real daily use, published so anyone can adopt the
structure. The rules content is mine — the point is that you replace it with yours.

## The idea: four memory layers

AI coding sessions forget everything. This repo organizes durable memory into four
layers, each answering a different question:

| Layer | Question | Lives in |
|---|---|---|
| **Rules** | How should the agent behave? | `AGENTS.md` + per-tool overlays; `sync.sh` bakes the Claude global (`~/.claude/CLAUDE.md`) |
| **Knowledge** | What was decided, and why? | A local vault (`~/Vault`) — plain markdown folders under git, committed and pushed to a private remote once a day by `hooks/vault-daily.sh`; Obsidian is a nice viewer, not a requirement |
| **Structure** | How does the code connect? | The current source, read live. For large or unfamiliar repos, an optional derived code graph (`graphify-out/`, gitignored), built on demand with `/graphify` — nothing refreshes it automatically, so treat it as a dated map |
| **History** | What actually happened? | git — the immutable record |

Skills like `repo-intake` (onboard a repo) and `memory-checkpoint` (reconcile state
before compacting context) orchestrate the layers; they are not sources of truth.
One convention does a lot of work here: **status surfaces record state, not
lifecycle** — present-tense facts that stay true, never "draft PR / merge pending"
phrasing that a merge silently invalidates.

## What's here

    AGENTS.md            Canonical rules: how I work. The shared 90%. REPLACE WITH YOURS.
    overlays/            Per-tool notes (the 10%): claude, cursor.
    rules/               Pinned shared rules baked into the globals by sync.sh (ponytail).
    skills/              Skills, authored + vendored (symlinked into ~/.claude/skills;
                         THIRD_PARTY_LICENSES.md attributes vendored components).
                         playwright-cli is NOT vendored: install.sh regenerates it
                         from the installed @playwright/cli (gitignored), so the
                         skill can never go stale against the binary.
    commands/            Global slash commands: /scaffold, /save, /recall.
    hooks/               session-end.sh (vault breadcrumb + session trace, repo
                         sessions only) and vault-daily.sh (daily vault commit +
                         push, wired as a launchd agent by install.sh).
    templates/project/   The standard per-repo skeleton (AGENTS.md, STATUS.md, .claude/).
    plugins.md           Marketplace plugins to install (not vendored here).
    scaffold.sh          Lay the standard layout into a project (non-destructive).
    sync.sh              Regenerate the global Claude file from canonical.
    install.sh           Wire everything into this machine (backs up first).

**Tool support is not symmetrical.** Skills, slash commands, hooks, and the vault
workflow (`/save`, `/recall`) are Claude Code-only; Cursor gets a manual paste of
the shared rules. (A Codex overlay existed until 2026-08 and died of disuse — the
git history has it if Codex returns.)

## Prerequisites

Required: `bash`, `git`, and [Claude Code](https://claude.com/claude-code) (the main
consumer — without it the install still succeeds but nothing reads the files).

Optional — each degrades gracefully if absent:

- **`graphify` CLI** (`pip install graphifyy` or `uv tool install graphifyy`) — powers
  the optional on-demand code graph. Without it `/graphify` is unavailable; the
  Structure layer is simply reading the code, which is the default anyway.
- **`python3`** — enriches the session-end trace (transcript parsing). Breadcrumbs work without it.
- **`jq`** — only used to merge the SessionEnd hook into an *existing*
  `~/.claude/settings.json`; without it you get the JSON to paste by hand.
- **GitHub CLI (`gh`)** — powers the `standup` skill and the ownership check in
  `repo-intake`'s guest-repo mode; without it those fall back to asking you.
- **Node** — for the `npm i -g` CLIs some skills drive (`@playwright/cli`, `defuddle-cli`).
- **Obsidian** — optional viewer for the vault. The vault is just markdown folders.

Platform: macOS and Linux (the vault-backup launchd agent is macOS-only; use cron on
Linux). Windows: use WSL; native Git-Bash symlinks are unreliable.

## Install

> **Personalize before you install.** `install.sh` bakes `AGENTS.md` into your global
> `~/.claude/CLAUDE.md`, and swaps your `~/.claude/skills` and commands for this
> repo's (existing files are backed up to `<file>.bak.<timestamp>`, never deleted —
> but your own rules stop applying until you restore them).

```bash
# 1. Fork this repo, then clone your fork to ~/.agents
git clone https://github.com/<you>/agent-config ~/.agents
cd ~/.agents

# 2. Make it yours (see next section) — edit AGENTS.md at minimum

# 3. Wire it in (re-runnable; backs up anything it touches)
./install.sh
```

Cursor (optional, manual): paste `AGENTS.md` + `overlays/cursor.md` into Cursor
Settings > Rules > User Rules — Cursor has no on-disk global file and nothing here
generates a bundle for it. `./sync.sh --check` reports when the baked Claude global
is stale.

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
- **`skills/`** — prune what you won't use (`graphify` needs the CLI installed; the
  `playwright-cli` skill is generated by `install.sh` only when
  `npm i -g @playwright/cli` is present). `THIRD_PARTY_LICENSES.md` attributes
  everything vendored.
- **Personal skills you don't want published:** keep the real folder outside the repo
  (the vault works — it's local and versioned), symlink it into `skills/`, and add the
  symlink's name to `.gitignore`. The global `~/.claude/skills` link follows it, so the
  skill stays live while the repo stays clean. Re-clone the repo and it's one `ln -s`
  to restore.

Then run `./sync.sh` to regenerate the global whenever you change rules or overlays.

## How the globals are wired

The global Claude file (`~/.claude/CLAUDE.md`) is GENERATED by `sync.sh` (canonical +
pinned rules + the tool's overlay, concatenated). It is baked, not imported, because
Claude's `@import` was unreliable for home/absolute paths when this was built. A
generated header marks it; edit `AGENTS.md` or an overlay, never the generated file.
Per-repo `CLAUDE.md` still uses the reliable relative `@AGENTS.md` import.

## Daily use

- New project: run `/scaffold` in Claude Code, or `~/.agents/scaffold.sh` in the repo.
  It lays down `AGENTS.md`, a `STATUS.md` (the single build-truth surface), and
  `.claude/` scaffolding.
- Change how you work: edit `AGENTS.md` (or an overlay), then run `./sync.sh`.
- End a session: `/save` takes stock against git once and writes both surfaces —
  `STATUS.md` (state) and the vault (session log + decisions). The SessionEnd hook
  also traces every repo session automatically (branch, changes, transcript path,
  first prompt) so a forgotten `/save` still leaves a searchable record.
- Resume context: `/recall` reads the recent vault notes for the current project.
- Onboard an unfamiliar repo: the `repo-intake` skill maps it, writes its
  `AGENTS.md`, and wires the vault (building a Graphify graph only when the repo
  is too large to map by reading). On a repo you don't own it goes
  vault-first: context lives in `~/Vault/projects/<repo>/repo-local/` and links into
  the repo as gitignored files — nothing lands in the owner's tracked tree.
- Start a session on a repo you share with others: the `standup` skill — is my memory
  intact, what changed while I was gone, who is in which files, any migration drift.
- Before compacting mid-session: the `memory-checkpoint` skill captures verified
  state into `STATUS.md` and repairs memory-file drift (the doctor pass). The vault
  is `/save`'s to write, and session end is `/save`'s job.
- Add a marketplace plugin: install via `/plugin`, then record it in `plugins.md`.

## Cloud sessions

Nothing here wires Claude Code on the web (research preview). A cloud-bootstrap
layer — two `CLAUDE_CODE_REMOTE`-gated SessionStart hooks plus `cloud-setup.sh` —
existed until 2026-08 and was deleted with zero observed executions in its
lifetime; its only measurable effect was a no-op at every local session start. If
cloud sessions become real, the platform's own mechanisms cover the job: a
per-environment **setup script** (configured at claude.ai/code) for VM
provisioning, repo-committed `.claude/` config for the rest, and a
`CLAUDE_CODE_REMOTE=true` gate for any repo hook that should run only in a VM.
The vault stays on your own machine either way — cloud sessions run without the
Knowledge layer, so anything worth keeping from one should be committed to the
repo or added to the vault by hand.

## Uninstall

Reverse everything `install.sh` did:

1. Restore the `.bak.<timestamp>` files it created (including
   `~/.claude/settings.json.bak.*` if the SessionEnd hook was merged into an
   existing settings file).
2. Remove the `~/.claude/skills` symlink and the per-command symlinks in
   `~/.claude/commands`. Unload the vault-backup launchd agent:
   `launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.agent-config.vault-daily.plist`
   and delete that plist.
3. Remove the SessionEnd hook entry from `~/.claude/settings.json` — on a machine
   where no settings file existed before install, `install.sh` created it, so
   delete the entry (or the file) by hand; there is no `.bak` for that case.
4. If `~/.claude/CLAUDE.md` carries the `GENERATED by ~/.agents` marker and no
   `.bak` exists (fresh machine), delete it — it was generated by `sync.sh`, not
   backed up from anything.
5. `~/.agents/.git/hooks/post-commit` (the sync-on-commit hook) disappears with the
   clone.

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

Vendored components — full texts in
[THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md). MIT:
[kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) (defuddle),
[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (graphify skill),
[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (ponytail rules).
(The playwright-cli skill is not vendored — install.sh generates it locally from the
installed `@playwright/cli` package, which carries its own Apache-2.0 license.)

## License

MIT — see [LICENSE](LICENSE).
