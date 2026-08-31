# agent-config

My personal Claude Code setup: **one canonical rules file** baked into the global
config (with a Cursor overlay pasted in by hand), plus skills, slash commands,
session hooks, a project scaffold, and a plain-markdown memory layer that survives
between sessions.

**This is not a product.** It is wired to my machine — my home paths, my vault, my
projects, my way of working — and it changes whenever my habits do. It is public so
I can link to it and because the structure may be worth reading. **Do not run
`install.sh`.** It rewrites your global Claude config and swaps your skills and
commands for mine. Read it, take the ideas, build your own.

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

    AGENTS.md            Canonical rules: how I work. The shared 90%.
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
    plugins.md           Marketplace plugins I install (not vendored here).
    scaffold.sh          Lay the standard layout into a project (non-destructive).
    sync.sh              Regenerate the global Claude file from canonical.
    install.sh           Wire everything into my machine (backs up first).

**Tool support is not symmetrical.** Skills, slash commands, hooks, and the vault
workflow (`/save`, `/recall`) are Claude Code-only; Cursor gets a manual paste of
the shared rules. (A Codex overlay existed until 2026-08 and died of disuse — the
git history has it if Codex returns.)

## What it leans on

Required: `bash`, `git`, and [Claude Code](https://claude.com/claude-code) (the main
consumer — without it the install still succeeds but nothing reads the files).

Optional — each degrades gracefully if absent:

- **`graphify` CLI** (`pip install graphifyy` or `uv tool install graphifyy`) — powers
  the optional on-demand code graph. Without it `/graphify` is unavailable; the
  Structure layer is simply reading the code, which is the default anyway.
- **`python3`** — enriches the session-end trace (transcript parsing). Breadcrumbs work without it.
- **`jq`** — merges the SessionEnd hook into an *existing* `~/.claude/settings.json`
  and wires the SessionStart staleness self-heal; without it the install emits JSON to paste
  by hand and the self-heal is NOT wired (a pulled rules change stays stale until
  the next local commit).
- **GitHub CLI (`gh`)** — powers the `standup` skill and the ownership check in
  `repo-intake`'s guest-repo mode; without it those fall back to asking.
- **Node** — for the `npm i -g` CLIs some skills drive (`@playwright/cli`, `defuddle-cli`).
- **Obsidian** — optional viewer for the vault. The vault is just markdown folders.

Platform: macOS and Linux (the vault-backup launchd agent is macOS-only; use cron on
Linux). Windows: use WSL; native Git-Bash symlinks are unreliable.

## Wiring it onto my machine

`install.sh` bakes `AGENTS.md` into `~/.claude/CLAUDE.md` and swaps `~/.claude/skills`
and the global commands for this repo's. Existing files are backed up to
`<file>.bak.<timestamp>`, never deleted.

```bash
git clone git@github.com:AuroraBackcountry/agent-config.git ~/.agents
cd ~/.agents
./install.sh   # re-runnable; backs up anything it touches
```

Cursor (manual): paste `AGENTS.md` + `overlays/cursor.md` into Cursor Settings >
Rules > User Rules — Cursor has no on-disk global file and nothing here generates a
bundle for it. `./sync.sh --check` reports when the baked Claude global is stale.

## Local conventions

- **Vault location** — defaults to `~/Vault`; override with `VAULT_DIR`.
- **`rules/ponytail.md`** — a vendored coding ruleset baked into every session
  (`sync.sh` handles its absence if it ever goes).
- **`skills/`** — `graphify` needs its CLI installed; the `playwright-cli` skill is
  generated by `install.sh` only when `npm i -g @playwright/cli` is present.
  `THIRD_PARTY_LICENSES.md` attributes everything vendored.
- **Personal skills that should not be published:** keep the real folder outside the
  repo (the vault works — it's local and versioned), symlink it into `skills/`, and
  add the symlink's name to `.gitignore`. The global `~/.claude/skills` link follows
  it, so the skill stays live while the repo stays clean. Re-clone and it's one
  `ln -s` to restore.

Run `./sync.sh` to regenerate the global after changing rules or overlays.

## How the globals are wired

The global Claude file (`~/.claude/CLAUDE.md`) is GENERATED by `sync.sh` (canonical +
pinned rules + the tool's overlay, concatenated). It is baked, not imported — not
because imports are unreliable (they aren't anymore; `@~/` imports are documented and
supported), but because Cowork desktop sessions skip user-scope external imports, so
an import-based global would silently load nothing there. A baked flat file works on
every surface. A generated header marks it; edit `AGENTS.md` or an overlay, never the
generated file. Per-repo `CLAUDE.md` uses the relative `@AGENTS.md` import.

## Daily use

- New project: run `/scaffold` in Claude Code, or `~/.agents/scaffold.sh` in the repo.
  It lays down `AGENTS.md`, a `STATUS.md` (the single build-truth surface), and
  `.claude/` scaffolding.
- Change how I work: edit `AGENTS.md` (or an overlay), then run `./sync.sh`.
- End a session: `/save` takes stock against git once and writes both surfaces —
  `STATUS.md` (state) and the vault (session log + decisions). The SessionEnd hook
  also traces every repo session automatically (branch, changes, transcript path,
  first prompt) so a forgotten `/save` still leaves a searchable record.
- Resume context: `/recall` reads the recent vault notes for the current project.
- Onboard an unfamiliar repo: the `repo-intake` skill maps it, writes its
  `AGENTS.md`, and wires the vault (building a Graphify graph only when the repo
  is too large to map by reading). On a repo I don't own it goes
  vault-first: context lives in `~/Vault/projects/<project>/repo-local/` and links into
  the repo as gitignored files — nothing lands in the owner's tracked tree.
- Start a session on a repo shared with others: the `standup` skill — is my memory
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
The vault stays on my own machine either way — cloud sessions run without the
Knowledge layer, so anything worth keeping from one should be committed to the
repo or added to the vault by hand.

## Unwinding the install

Reverse everything `install.sh` did:

1. Restore the `.bak.<timestamp>` files it created (including
   `~/.claude/settings.json.bak.*` if the SessionEnd hook was merged into an
   existing settings file).
2. Remove the `~/.claude/skills` symlink and the per-command symlinks in
   `~/.claude/commands`. Unload the vault-backup launchd agent:
   `launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.agent-config.vault-daily.plist`
   and delete that plist.
3. Remove BOTH hook entries from `~/.claude/settings.json`: the SessionEnd hook
   and the SessionStart sync-check (the entry whose command mentions `sync.sh`).
   On a machine where no settings file existed before install, `install.sh`
   created it, so delete the entries (or the file) by hand; there is no `.bak`
   for that case.
4. If `~/.claude/CLAUDE.md` carries the `GENERATED by ~/.agents` marker and no
   `.bak` exists (fresh machine), delete it — it was generated by `sync.sh`, not
   backed up from anything.
5. `~/.agents/.git/hooks/post-commit` (the sync-on-commit hook) disappears with the
   clone.

## What is committed vs personal

Per repo, these stay out of git:
`CLAUDE.local.md`, `AGENTS.override.md`, `.claude/settings.local.json`, `graphify-out/`.
Two layers enforce it: the template `.gitignore` (repos I scaffold) and the
machine-wide git ignore (`~/.config/git/ignore`, seeded by `install.sh`) — the latter
covers repos I don't own, where the template never lands and editing the owner's
`.gitignore` would cost them a review.

Never commit secrets (API keys in MCP configs, `~/.codex/config.toml`). A private repo
is not the same as safe to leak — and this one is public.

## De-dup rules (why things live where they do)

GUI installs (claude.ai web, Cowork desktop) and the Claude Code CLI use separate
storage that does not sync. To avoid fragmentation:

1. Skills live only in `skills/` here, symlinked to `~/.claude/skills`.
2. Marketplace plugins (e.g. superpowers) are installed via `/plugin` and listed in
   `plugins.md`. Do not copy them into `skills/`.
3. Cowork and web are separate surfaces; they get their own GUI installs.

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
