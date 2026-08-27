# STATUS — the single source of build truth

> State, not lifecycle: present-tense facts true right now. Never "draft PR", "on branch
> X", "redeploy on merge" — a merge makes those false and nothing re-edits them. History
> lives in `git log` and `~/Vault/decisions/agent-config.md`; this file keeps no changelog.

## Current state

Public since 2026-07-26 under MIT. Two clones on this machine: **`~/.agents` is the
canonical clone and the live install — every edit happens there**. `~/code/agent-config`
is a reference-only checkout; it is only as fresh as the last push + pull.

- **Rules.** `AGENTS.md` + `rules/ponytail.md` + `overlays/claude-code.md` are baked by
  `sync.sh` into exactly one destination: `~/.claude/CLAUDE.md`. Baking survived the
  2026-08-26 audit on its real merit (Cowork skips user-scope imports); the stale
  rationale is corrected in the sync.sh header. Freshness has two mechanisms: the
  post-commit hook (local commits) and a SessionStart `--check || sync` hook (heals
  drift from ff-pulls — verified by injecting drift and watching it re-bake).
  Codex support is deleted (no binary, zero sessions in 31 days; history has it).
  Cursor is manual: `overlays/cursor.md` exists to paste, nothing generates a bundle.
- **Skills.** Three authored (`repo-intake` — cut to a 7.4 KB kernel, `memory-checkpoint`,
  `standup`), one vendored-and-forked (`defuddle`, shrunk, install line corrected to
  `defuddle-cli`), one vendored (`graphify`), one machine-generated (`playwright-cli`,
  produced by install.sh from the installed `@playwright/cli`, gitignored, cannot go
  stale against the binary). `skills/` is symlinked into `~/.claude/skills`.
  `plasmic-designer` is deleted (one use ever; recoverable from vault history).
- **Session-end roles.** `/save` is the single session-end entry point: one git
  take-stock, then STATUS.md (state) and the vault (log, decisions, MOC pointer).
  `memory-checkpoint` is mid-session capture plus the doctor pass, of which it holds
  the ONLY copy; repo-intake delegates to it.
- **Hooks.** `session-end.sh`: breadcrumb + trace for repo sessions only, writes no
  git. `vault-daily.sh`: launchd agent at 17:00 commits and pushes `~/Vault` to the
  private remote (`AuroraBackcountry/vault`); one evidence line per run in
  `~/.cache/vault-daily.log`.
- **Vault.** Git-versioned with an off-machine remote. History was rewritten
  2026-08-26 to remove three guideops `.env` files before the first push;
  `~/Vault/.gitignore` fences `*.env` out going forward. `.git` is packed (~2 MB,
  from 84 MB of loose objects under the old per-session snapshot).
- **Graphify.** On-demand only, machine-wide: no post-commit hook anywhere, no graph
  in this repo, guideops' stale graph deleted. infoex-api, aurora-backcountry, and
  avalanche-search keep graphs that stay frozen until a manual `/graphify --update`.
- **Checks.** `tests/session-end.test.sh` — 12 checks, including the non-repo
  writes-nothing gate and never-commits-the-vault. Still the only test here.

## Known gaps

- **Nothing from the 2026-08-26 overhaul is pushed.** ~/.agents `main` is local-only
  ahead of `origin/main` (as is infoex-api's `main` by one docs commit); the
  reference checkout lags until push + pull.
- **graphify's SKILL.md is still 41 KB** of upstream build machinery for a workflow
  that uses two commands; shrink-or-drop is an open decision.
- **Three repos still track the dead cloud hook** (accounting-agent, infoex-api,
  quickbooks-connector carry the scaffolded SessionStart hook + wiring). Harmless
  locally (exit 0); in a cloud session it would now fail, since `cloud-setup.sh` no
  longer exists.
- **Nothing prunes the read surfaces.** `/recall` loads whole decision files
  (`~/Vault/decisions/infoex-api.md` is 74 KB) and the monthly `_traces-*.md` files
  grow all month (~15 KB/day when busy); `_sessions.log` is repo-only now but
  unbounded.
- **Convention prose is still restated** in places: the project-key derivation
  appears inline in save.md and recall.md beside their pointer to the global rule;
  state-not-lifecycle text lives in AGENTS.md, memory-checkpoint, and both STATUS
  banners.
- **Backup coverage is the vault remote, nothing else.** Time Machine's destination
  still fails to mount; `~/.claude/projects` (~780 MB of transcripts) and
  `~/.claude/settings.json` have no off-disk copy. `~/Vault-backup-2026-08-26` (the
  pre-scrub safety copy, secrets included in its history) sits on the same disk
  awaiting a keep-or-delete call.
- No check covers `install.sh`, `sync.sh`, or `scaffold.sh`.

## Next

1. Push `~/.agents` main; pull the reference checkout and infoex-api's main.
2. Decide graphify: shrink the skill to a query-first ~3 KB, or drop it.
3. Strip the dead cloud hook from the three scaffolded repos.
4. Decide the fate of `~/Vault-backup-2026-08-26` once the remote has earned trust.
