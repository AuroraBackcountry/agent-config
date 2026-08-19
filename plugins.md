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

    /plugin marketplace add upstash/context7
    /plugin install context7@context7-marketplace

(Upstash Context7: version-specific library docs. Upstash's own plugin, not the
thinner `context7@claude-plugins-official` mirror — same hosted endpoint, but it
adds the auto-trigger skill, a `docs-researcher` subagent that keeps doc dumps out
of the main context, and `/context7:docs`. ~149 tok always-on.

No local process: it's Context7's hosted MCP server over HTTP, so queries leave the
machine. Public library docs only, never anything private. Works unauthenticated;
`export CONTEXT7_API_KEY` before launching Claude Code if the anonymous rate limit
starts biting. Do NOT use `ctx7 setup` to install it — its `--universal` target
writes into `~/.agents/skills`, i.e. this repo, and its MCP mode writes an agent
rules file; both go around sync.sh.)

## Notes
- This lists user-scope plugins only. Project-scoped plugins (installed for a single
  repo) live in that repo's own `.claude` config and are not tracked here.
- Skills you author yourself go in `skills/` (this repo), not here.
- Cowork (desktop app) and claude.ai (web) manage their own plugins separately;
  they do not read this repo. Reinstall there via their GUIs if you want them on those surfaces.
