---
name: standup
description: Use when starting a work session on a repo shared with other people - before picking up a task, after time away, or when unsure what teammates are currently working on and what is safe to touch.
---

# Standup

Start-of-session orientation for a repo you share with other people. Answers three
questions before any work begins: **is my memory intact, what changed while I was gone,
and what is safe to touch.**

On a solo repo this is unnecessary. The value is entirely in the shared case, where the
codebase moved overnight and someone else may already be inside the files you were
planning to open.

## The four steps

Run them in order. Report findings as you go; do not fix anything yet.

### 1. Memory intact?

Local agent context is often gitignored or symlinked, which means a branch switch,
`git clean -fdx`, or a fresh clone silently removes it.

```bash
ls -la AGENTS.md CLAUDE.md 2>&1        # broken symlink shows as a dangling arrow
```

If missing or dangling, restore from the vault backup before anything else:
`~/Vault/projects/<project>/repo-local/` (`<project>` per the global project-key
rule). A session that starts without context is a session
that re-derives everything wrong.

Then load durable memory with the `recall` skill.

### 2. Sync

Fetch only. Orientation never moves you off your branch or touches the worktree — a
`checkout main` here is exactly the kind of "fix" this skill promises not to make.

```bash
git fetch origin --prune
git log --oneline ..origin/main     # what landed on main while you were gone
```

Read the new commits. On a shared repo these are the changes you did not make and do not
yet know about. Update local main later, when you actually need it — not here.

### 3. Who is in what

This is the step that prevents collisions.

```bash
gh pr list --state open --json number,title,author,headRefName \
  --jq '.[] | "#\(.number) [\(.author.login)] \(.title) — \(.headRefName)"'

for b in $(git for-each-ref --format='%(refname:short)' refs/remotes/origin \
           | grep -v 'origin/HEAD\|origin/main'); do
  git branch -r --merged origin/main | grep -qx "  $b" || \
    echo "$(git log -1 --format='%ad %an' --date=short $b)  $b"
done | sort -r
```

For any open PR touching your intended area, list its files
(`gh pr view <n> --json files`) and say plainly whose lane you would be entering.

### 4. Schema and migration drift

Only where the project has migrations. If teammates merged migrations while you were away,
your local database is now behind.

```bash
# merged recently
git log --oneline -10 -- '**/migrations/**'

# in flight in someone's open PR — the one that bites
gh pr list --state open --json number,title,files --jq \
  '.[] | select([.files[].path | test("migrations")] | any)
       | "PR #\(.number) \(.title):", (.files[].path | select(test("migrations")) | "    \(.)")'
```

Flag any migration that is merged-but-not-applied locally, or in-flight in someone's open
PR. Never auto-apply. On a `db push` project (no `_prisma_migrations` table), reconciling
can prompt for data loss — that prompt is read, never reflexed through.

## Output

Close with a short report, not a transcript:

- **Memory:** intact, or what was restored
- **New since last session:** the commits that matter, in one line each
- **Occupied:** who is in which files, and therefore what to stay out of
- **Clear:** what is safe to pick up
- **Blocked/unknown:** anything that needs a teammate's answer first

Then stop and let the human choose the task. This skill orients; it does not start work.

## Common mistakes

| Mistake | Why it hurts |
|---|---|
| Skipping step 1 because "the repo looks fine" | Dangling symlinks look identical to present files in a plain `ls` |
| Reading only open PRs | Unmerged branches with no PR are live work too |
| Checking only file paths for collisions | A shared service or route collides even when the paths differ |
| Auto-applying migrations found in step 4 | Reconciling a drifted schema can drop columns |
| Reporting every command's raw output | The value is the judgment, not the transcript |
