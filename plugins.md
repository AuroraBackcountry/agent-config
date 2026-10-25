# Plugins & marketplaces (install, do not vendor)

Installed marketplace plugins are owned by Claude Code's plugin manager in
`~/.claude/plugins`. Do NOT copy them into `skills/`. List them here so a new
machine reinstalls them fresh and updatable.

## Claude Code (CLI)

    /plugin install superpowers@claude-plugins-official

(The official marketplace is built in; no `marketplace add` step needed.)

    /plugin marketplace add pbakaus/impeccable
    claude plugin install impeccable@impeccable --scope local    # inside each UI repo

(Design skill + /impeccable commands. Run `/impeccable init` only in owned repos
with a frontend; never in guest repos — it writes PRODUCT.md/DESIGN.md at root.)
Local scope only, never user scope: its hooks run on every edit and every stop (up to
30 s), so it belongs only in UI repos (today: infoex-api, aurora-backcountry, guideops).
The install writes `"enabledPlugins": {"impeccable@impeccable": true}` into that repo's
git-ignored `.claude/settings.local.json`. `~/.claude/settings.json` keeps
`"impeccable@impeccable": false` with NO user-scope install: a `false` triggers no
auto-install, and it stops a session that merely attaches a UI repo (`--add-dir`) from
loading the plugin — without it that repo's local `true` is the only vote and wins.
(`claude plugin list` then notes on each local row that the user setting is overridden;
expected.) The old scheme — one user-scope install, off globally, on per repo — made
Claude Code auto-install a second local copy wherever it was on (each worktree too), so
every UI repo listed it twice.

    /plugin marketplace add upstash/context7
    /plugin install context7@context7-marketplace

(Upstash Context7: version-specific library docs. Upstash's own plugin, not the
thinner `context7@claude-plugins-official` mirror — same hosted endpoint, but it
adds the auto-trigger skill, a `docs-researcher` subagent that keeps doc dumps out
of the main context, and `/context7:docs`. Always-on cost measured 2026-08-26:
1,172 B ≈ 317 tok derived (skill frontmatter 298 + MCP server instructions 637 +
command frontmatter 84 + agent frontmatter 153) — roughly double the ~149 tok the
plugin's own docs claim.

No local process: it's Context7's hosted MCP server over HTTP, so queries leave the
machine. Public library docs only, never anything private. Works unauthenticated;
`export CONTEXT7_API_KEY` before launching Claude Code if the anonymous rate limit
starts biting. Do NOT use `ctx7 setup` to install it — its `--universal` target
writes into `~/.agents/skills`, i.e. this repo, and its MCP mode writes an agent
rules file; both go around sync.sh.)

    /plugin marketplace add Leonxlnx/taste-skill
    claude plugin install taste-skill@taste-skill --scope local    # inside each UI repo

(Leonxlnx's taste-skill: one skill, `design-taste-frontend`; no hooks or MCP. Always-on
~246 tok, ~9.4k when it fires. Do NOT use `npx skills add` for it: like `ctx7 setup`,
it writes into `~/.agents/skills`. Reviewed at v2.1.4 (6010f91a, 2026-10-21): no
malicious code; scripts use Node built-ins only. A full run is long (30-45 min, a few
hundred k tokens) and its trigger overlaps impeccable. Writes `~/.taste-skill/history.json`.
Pages it builds hotlink jsDelivr, Google Fonts/Fontshare and picsum.photos; self-host
those before shipping a guest-facing page.
Like impeccable, local scope only, installed inside each UI repo (today: infoex-api,
aurora-backcountry, guideops); no user-scope copy, `"taste-skill@taste-skill": false` in
`~/.claude/settings.json`.)

## Notes
- This lists what a new machine reinstalls: user-scope plugins, plus the two UI plugins
  installed at local scope inside each UI repo. Any other project-scoped plugin lives in
  that repo's own `.claude` config and is not tracked here.
- Skills you author yourself go in `skills/` (this repo), not here.
- Cowork (desktop app) and claude.ai (web) manage their own plugins separately;
  they do not read this repo. Reinstall there via their GUIs if you want them on those surfaces.
