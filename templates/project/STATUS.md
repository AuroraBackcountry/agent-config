# STATUS — the single source of build truth

> State, not lifecycle: present-tense facts true right now. Never "draft PR",
> "on branch X", "redeploy on merge" — a merge makes those false and nothing
> re-edits them. Dated history goes in CHANGELOG.md (past tense, frozen,
> newest first), NEVER in this file: a changelog kept here once grew to 75%
> of a 281 KB STATUS.md and buried the current state past the default read
> window.

## Now

Read this block first; it is the whole briefing. Keep it under 20 lines: when something
lands, replace a line, never add one. Everything below it is reference.

- **Live:** (what is deployed or installed right now)
- **Active:** (the one thing being built or proven)
- **Open:** (the one finding or blocker, with a pointer to its record)
- **Next:** (the next concrete step)
- **Where the rest is:** the sections below · phase or spec records in `docs/` · dated history in `CHANGELOG.md`

## Current state

(what is built and live right now — present tense, no embedded history; git holds the past)

## Known gaps

(tracked, deliberate — a closed gap is deleted, not struck through)
