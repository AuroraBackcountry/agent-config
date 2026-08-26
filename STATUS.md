# STATUS — the single source of build truth

> State, not lifecycle: present-tense facts true right now. Never "draft PR", "on branch
> X", "redeploy on merge" — a merge makes those false and nothing re-edits them. History
> lives in `git log` and `~/Vault/decisions/agent-config.md`; this file keeps no changelog.

## Current state

Public since 2026-07-26 under MIT. Two clones on this machine: **`~/.agents` is the
canonical clone and the live install — every edit happens there**. `~/code/agent-config`
is a reference-only checkout; editing it gets wiped by the next sync.

- **Rules.** `AGENTS.md` (the shared payload) + `rules/ponytail.md` + one per-tool overlay
  are baked by `sync.sh` into `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, and
  `generated/cursor-user-rules.md`. A post-commit hook re-bakes on every commit and
  `sync.sh --check` reports drift. The destinations carry a GENERATED marker; the sources
  deliberately do not, so nothing that keys off that marker protects `AGENTS.md` itself.
- **Skills.** Three authored (`repo-intake`, `memory-checkpoint`, `standup`), three
  vendored (`defuddle`, `graphify`, `playwright-cli`), plus `plasmic-designer` symlinked
  from the vault and gitignored. `skills/` is symlinked into `~/.claude/skills`.
- **Commands.** `/scaffold`, `/save`, `/recall`, symlinked per file into
  `~/.claude/commands`.
- **Hooks.** `session-end.sh` writes a breadcrumb plus a per-session trace and snapshots
  the vault; `graphify-post-commit.sh` refreshes a repo's code graph in the background,
  opt-in per repo via an existing `graphify-out/graph.json`.
- **Browser tooling.** `playwright-cli` drives, `chrome-devtools-mcp` diagnoses with CrUX
  upload disabled in both the user and `~`-local scopes. context7 comes from Upstash's
  own marketplace, not Anthropic's mirror.
- **Checks.** `tests/session-end.test.sh` covers the session-end hook: worktree project
  identity, non-repo filtering, and concurrent-append atomicity. It is the only test here.

## Known gaps

- **The vault has no backup.** `~/Vault` is git-versioned locally (the SessionEnd hook
  snapshots it every session) but has no remote, and the Time Machine destination fails to
  mount. It holds the only copy of the `plasmic-designer` skill, the guideops `.env`
  files, and every decision note. Its `.git` is 82 MB against a 2 MB working tree.
- **Ending a session takes two commands.** `/save` writes history (vault log, decisions)
  and `memory-checkpoint` writes state (`STATUS.md`); neither is sufficient alone, both
  write the vault MOC's "Next" line, and checkpoint's "only if no `/save` ran this
  session" condition is not observable by anything.
- **Nothing prunes the history surfaces.** STATUS changelogs, `~/Vault/decisions/*.md`,
  and `logs/_traces-*.md` all grow monotonically. infoex-api's `STATUS.md` is 281 KB, of
  which 75% is changelog sitting above the state it is supposed to surface.
- **Two duplications have already diverged.** The doctor pass exists in both
  `memory-checkpoint` Phase 4 and `repo-intake`'s wire-only mode, and the intake copy is
  the weaker one. The machine-wide gitignore seeding block is byte-identical in
  `install.sh` and `cloud-setup.sh`.
- **Codex support has no user on this machine.** The `codex` CLI is not on PATH and the
  newest session in `~/.codex/sessions` is 2026-07-26. Cursor is still in use. The cost is
  roughly 50 lines across 8 files; the argument for keeping it is that multi-tool support
  is what the public README sells.
- No check covers `install.sh`, `sync.sh`, `scaffold.sh`, or `graphify-post-commit.sh`.

## Next

1. One session-end entry point: `/save` takes stock once and writes both surfaces;
   `memory-checkpoint` narrows to mid-session capture and the doctor pass.
2. History out of the hot path: `STATUS.md` keeps state, `CHANGELOG.md` keeps history,
   `/recall` reads the tail of the decisions file rather than all of it.
3. Collapse the two duplications.
4. Then the vault backup.
