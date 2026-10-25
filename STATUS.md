# STATUS — the single source of build truth

> State, not lifecycle: present-tense facts true right now. Never "draft PR", "on branch
> X", "redeploy on merge" — a merge makes those false and nothing re-edits them. History
> lives in `git log` and `~/Vault/decisions/agent-config.md`; this file keeps no changelog.

## Now

Read this block first; it is the whole briefing. Under 20 lines; lines get replaced, not added.

- **Live:** `~/.agents` is the install; the baked global matches source (`./sync.sh --check`).
  STATUS rule: no PR numbers or build ids, the edit rides its own PR, waiting edits go to
  `~/Vault/projects/<project>/status-queue.md`, 300 lines and 25 KB.
- **Active:** nothing. The standing rule holds — the next change waits for an observed failure.
- **Open:** nothing. impeccable and taste-skill are local-scope installs in infoex-api,
  aurora-backcountry and guideops only; no user-scope copy, nothing in `~/.claude/settings.json`.
- **Next:** nothing queued.
- **Where the rest is:** Current state and Known gaps below · decisions in
  `~/Vault/decisions/agent-config.md` · history in `git log`.

## Current state

Public since 2026-07-26 under MIT, but not a product: the README says so outright and
tells readers not to run `install.sh`. It is wired to this machine and changes with my
habits; nobody has forked it.

Two clones on this machine, with different jobs. **`~/.agents` is the canonical clone
and the live install** — settings.json points the hooks there, `~/.claude/skills` and
the global commands symlink there, and it is the only copy anything loads from. But
sessions run from `~/code/agent-config` (97 of 97 logged `agent-config` sessions; the
last from `~/.agents` was 2026-07-28), editing `~/.agents` by absolute path. The
reference checkout is only as fresh as the last push + pull.

- **Rules.** `AGENTS.md` + `rules/ponytail.md` + `overlays/claude-code.md` are baked by
  `sync.sh` into exactly one destination: `~/.claude/CLAUDE.md`. Baked deliberately —
  Cowork skips user-scope imports, so an import-based global would load nothing there.
  Freshness has two mechanisms: the post-commit hook (local commits) and
  `hooks/session-start.sh` (heals pulled drift; every overwrite leaves a `.pre-sync` safety
  copy). The same hook prints a line into the session when the last vault backup did not
  push, none ran for 2 days, a self-heal failed in the last 7 days, or the session repo's
  memory files fail the doctor pass's mechanical checks (`hooks/memory-lint.sh`: the STATUS
  rule via `hooks/status-lint.sh`, a CLAUDE.md copy of AGENTS.md or an AGENTS.md over 300
  lines / 30 KB in owned repos, PR numbers or ids in the vault MOC, "STATUS #N" in
  auto-memory); silent when healthy. `/save` runs status-lint before writing STATUS.
  There is no Codex support (history has it).
  Cursor is manual: `overlays/cursor.md` exists to paste, nothing generates a bundle.
- **Template.** `templates/project/STATUS.md` opens with a Now block (live, active, open, next;
  under 20 lines, one line per bullet) and carries a 300-line and 25 KB ceiling. Its
  `.gitignore` (also the seed of the machine-wide ignore) covers `.claude/worktrees/`.
  `/recall` reads Now first and the rest on need; `/save` rewrites Now first and, over the
  ceiling, deletes shipped items and closed gaps before it writes (git holds them). The global
  rule states the same in one sentence, so a repo that already has a STATUS.md follows it once
  it gains the block.
- **Skills.** Three authored (`repo-intake` — cut to a 7.4 KB kernel, `memory-checkpoint`,
  `standup`), one vendored-and-forked (`defuddle`, shrunk, install line corrected to
  `defuddle-cli`), one vendored (`graphify`), one machine-generated (`playwright-cli`,
  produced by install.sh from the installed `@playwright/cli`, gitignored, cannot go
  stale against the binary). `skills/` is symlinked into `~/.claude/skills`.
  `plasmic-designer` lives only in `aurora-backcountry/.claude/skills/`, the repo that uses it.
- **Session-end roles.** `/save` is the single session-end entry point: one git
  take-stock, then STATUS.md (state) and the vault (log, decisions, MOC pointer). Its
  step 3 holds the full STATUS rule; AGENTS.md carries a one-line summary.
  `memory-checkpoint` is mid-session capture plus the doctor pass, of which it holds
  the ONLY copy; repo-intake delegates to it.
- **Hooks.** `session-end.sh`: one trace entry for repo sessions only, writes no git (the
  `_sessions.log` breadcrumb is gone: nothing read it). `vault-daily.sh`: launchd agent at 17:00 commits and pushes `~/Vault` to the
  private remote (`AuroraBackcountry/vault`); one evidence line per run in
  `~/.cache/vault-daily.log`.
  The trace safety net is used, barely: five sessions have read a `_traces-*.md`
  file, four through `/recall` and one through `/standup`; it passes the ever-used bar.
- **Vault.** Git-versioned with an off-machine private remote. Its history contains
  no env files (verified against every commit, including everything pushed);
  `~/Vault/.gitignore` fences `*.env` out, and vault-daily refuses to run while an
  env-named file is tracked or the day's changes hold key-shaped text (known prefixes, private
  keys, JWTs). `.gitignore` also fences `*.pem`, `*.key`, `*.p12`, `credentials*.json`.
  `.git` is packed (~2 MB).
- **Graphify.** On-demand only, machine-wide: no post-commit hook anywhere, no graph in
  this repo. infoex-api, aurora-backcountry and guideops keep graphs (dead repos live in
  `~/code/_archive/`; drag one back to `~/code` to work on it), each
  frozen until a manual `/graphify --update`; infoex-api keeps one dated snapshot, the others
  keep every snapshot they ever built.
- **Checks.** `tests/session-end.test.sh` (worktree identity, non-repo
  writes-nothing, concurrency, never-commits-the-vault, the `.agents` project-key
  alias) and
  `tests/vault-daily.test.sh` (every exit logs, commit-failure reported, both secrets
  gates, quiet-day no-op; the push itself is deliberately untested) and
  `tests/session-start.test.sh` (silent when healthy, one line per failure kind) and
  `tests/status-lint.test.sh` (each break kind caught, the known look-alikes pass) and
  `tests/memory-lint.test.sh` (each mechanical check, guest repos exempt). No counts here —
  a number in prose that must track code is a drift generator; run them.

## Known gaps

- **Nothing prunes the write surfaces.** Decision files and the monthly
  `_traces-*.md` grow without bound (~15 KB/day when busy) — though `/recall` reads
  only the decisions tail, so growth costs disk, not context.
- **The STATUS rule lives in two places:** in full in `/save` step 3 (memory-checkpoint
  points there) and as a short banner in the template; the project-key rule is stated once, in
  AGENTS.md, with save, recall, repo-intake, memory-checkpoint and standup pointing
  at it and every vault path written as `<project>`.
- **The `.agents` key alias is stated in two languages** — prose in AGENTS.md and a
  branch in `session-end.sh` — kept together by a comment. The shell side has a test;
  a prose-only edit that diverges from it is undetectable, and would split the vault
  silently (`/save` writing one key, the hook another).
- No check covers `install.sh`, `sync.sh`, or `scaffold.sh`.

## Next

Nothing queued.

**Standing rule:** the next change to this repo is triggered by an observed
failure, not by another review pass. Review can find work here indefinitely;
only breakage gets to order it.
