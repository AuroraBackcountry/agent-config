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

- **Nothing prunes the write surfaces.** Decision files and the monthly
  `_traces-*.md` grow without bound (~15 KB/day when busy) and `_sessions.log` is
  repo-only now but unbounded — though `/recall` now reads only the decisions tail,
  so growth costs disk, not context.
- **State-not-lifecycle prose still lives in three places** (AGENTS.md,
  memory-checkpoint, the STATUS banners); the project-key rule is now stated once,
  in AGENTS.md, with save/recall pointing at it.
- **Backup coverage is the vault remote, nothing else.** Time Machine's destination
  still fails to mount; `~/.claude/projects` (~780 MB of transcripts) and
  `~/.claude/settings.json` have no off-disk copy.
- No check covers `install.sh`, `sync.sh`, or `scaffold.sh`.

## Next

1. Fix the Time Machine destination (or pick another off-disk backup for
   `~/.claude/projects` and `~/.claude/settings.json`) — the last data with a
   single copy.
