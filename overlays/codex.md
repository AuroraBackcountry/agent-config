# Codex overlay

Applies only when the agent is Codex. Concatenated into ~/.codex/AGENTS.md by sync.sh
(Codex has no import mechanism).

Strengths to lean on:
- Fast, sandboxed execution and tight PR-sized diffs.
- Running and iterating on code in an isolated environment.

Prefer Codex for: contained tasks with a clear diff, test-and-fix loops, and work that should stay inside a sandbox.
