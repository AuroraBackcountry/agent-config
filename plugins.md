# Plugins & marketplaces (install, do not vendor)

Installed marketplace plugins are owned by Claude Code's plugin manager in
`~/.claude/plugins`. Do NOT copy them into `skills/`. List them here so a new
machine reinstalls them fresh and updatable.

## Claude Code (CLI)

    /plugin install superpowers@claude-plugins-official

(The official marketplace is built in; no `marketplace add` step needed.)

    /plugin marketplace add pbakaus/impeccable
    /plugin install impeccable@impeccable

(Design skill + /impeccable commands. Run `/impeccable init` only in owned repos
with a frontend; never in guest repos — it writes PRODUCT.md/DESIGN.md at root.)
After installing, turn it OFF globally and ON per UI repo: its hooks run on every edit
and every stop (up to 30 s) in every repo. `~/.claude/settings.json` holds
`"enabledPlugins": {"impeccable@impeccable": false}`; each UI repo's git-ignored
`.claude/settings.local.json` holds `true` (today: infoex-api, aurora-backcountry, guideops).

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
    /plugin install taste-skill@taste-skill

(Leonxlnx's taste-skill: one skill, `design-taste-frontend`; no hooks or MCP. Always-on
~246 tok, ~9.4k when it fires. Do NOT use `npx skills add` for it: like `ctx7 setup`,
it writes into `~/.agents/skills`. Reviewed at v2.1.4 (6010f91a, 2026-10-21): no
malicious code; scripts use Node built-ins only. A full run is long (30-45 min, a few
hundred k tokens) and its trigger overlaps impeccable. Writes `~/.taste-skill/history.json`.
Pages it builds hotlink jsDelivr, Google Fonts/Fontshare and picsum.photos; self-host
those before shipping a guest-facing page.
Like impeccable, OFF globally (`"taste-skill@taste-skill": false` in `~/.claude/settings.json`)
and ON per UI repo via its git-ignored `.claude/settings.local.json` (today: infoex-api,
aurora-backcountry, guideops).)

## Notes
- This lists user-scope plugins only. Project-scoped plugins (installed for a single
  repo) live in that repo's own `.claude` config and are not tracked here.
- Skills you author yourself go in `skills/` (this repo), not here.
- Cowork (desktop app) and claude.ai (web) manage their own plugins separately;
  they do not read this repo. Reinstall there via their GUIs if you want them on those surfaces.
