# STATUS — the single source of build truth

> State, not lifecycle: present-tense facts true right now. Never "draft PR",
> "on branch X", "redeploy on merge" — a merge makes those false and nothing
> re-edits them. Dated history goes in CHANGELOG.md (past tense, frozen,
> newest first), NEVER in this file: a changelog kept here once grew to 75%
> of a 281 KB STATUS.md and buried the current state past the default read
> window.
>
> Never a PR number, a build/deploy/update id, or "the latest X is Y": this edit
> rides the PR it describes, so write only what that PR knows before it merges.
>
> Ceiling: the whole file stays under 300 lines and 25 KB. Over either, /save compacts before it
> writes: shipped items and closed gaps are deleted (git holds them), embedded dates
> leave the current-state prose. Nothing else is allowed to grow it back.

## Now

Read this block first; it is the whole briefing. Keep it under 20 lines, one line per bullet: when something
lands, replace a line, never add one. Everything below it is reference.

- **Live:** (what runs where, e.g. "phones take main's OTA updates"; never which build)
- **Active:** (the one thing being built or proven)
- **Open:** (the one finding or blocker, with a pointer to its record)
- **Next:** (the next concrete step)
- **Where the rest is:** the sections below · phase or spec records in `docs/` · dated history in `CHANGELOG.md`

## Current state

(what is built and live right now — present tense, no embedded history; git holds the past)

## Known gaps

(tracked, deliberate — a closed gap is deleted, not struck through)
