---
description: Lay the standard project layout into this repo (non-destructive)
---
Scaffold is for repos I own. Before running it, settle ownership:

    gh repo view --json viewerPermission --jq .viewerPermission

WRITE/TRIAGE/READ means a guest repo (someone else's — I branch and PR): stop and use
`repo-intake`'s guest mode instead. Every file scaffold lays down is a tracked-file
change their owner has to review — and on a repo whose hooks directory is tracked
(husky-style `core.hooksPath`), even the hook install would modify a tracked file.
ADMIN/MAINTAIN, no remote, or no `gh`: it's mine (ask if genuinely unsure), continue.

Run the scaffold script against the current project root:

    bash ~/.agents/scaffold.sh "$PWD"

It never overwrites existing files, so it is safe to run repeatedly. After it runs:

1. Summarize which files were added.
2. If AGENTS.md was newly created, ask me 2-3 quick questions about this project
   (what it is, the stack, any rule that should override the global defaults) and fill it in.
3. If a .gitignore already existed it was skipped; remind me to merge in the lines from
   ~/.agents/templates/project/.gitignore.
4. Remind me that .claude/settings.local.json and CLAUDE.local.md are gitignored.
