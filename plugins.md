# Plugins & marketplaces (install, do not vendor)

Installed marketplace plugins are owned by Claude Code's plugin manager in
`~/.claude/plugins`. Do NOT copy them into `skills/`. List them here so a new
machine reinstalls them fresh and updatable.

## Claude Code (CLI)

    /plugin install superpowers@claude-plugins-official

(The official marketplace is built in; no `marketplace add` step needed.)

## Notes
- This lists user-scope plugins only. Project-scoped plugins (installed for a single
  repo) live in that repo's own `.claude` config and are not tracked here.
- Skills you author yourself go in `skills/` (this repo), not here.
- Cowork (desktop app) and claude.ai (web) manage their own plugins separately;
  they do not read this repo. Reinstall there via their GUIs if you want them on those surfaces.
