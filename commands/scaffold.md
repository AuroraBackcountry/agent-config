---
description: Lay the standard project layout into this repo (non-destructive)
---
Run the scaffold script against the current project root:

    bash ~/.agents/scaffold.sh "$PWD"

It never overwrites existing files, so it is safe to run repeatedly. After it runs:

1. Summarize which files were added.
2. If AGENTS.md was newly created, ask me 2-3 quick questions about this project
   (what it is, the stack, any rule that should override the global defaults) and fill it in.
3. If a .gitignore already existed it was skipped; remind me to merge in the lines from
   ~/.agents/templates/project/.gitignore.
4. Remind me that .claude/settings.local.json and CLAUDE.local.md are gitignored.
