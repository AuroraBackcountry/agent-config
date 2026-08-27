---
name: defuddle
description: Extract clean markdown from a web page with the defuddle CLI - use instead of WebFetch for articles, blog posts, and non-library docs (it strips nav/ads, saving tokens). NOT for URLs ending in .md (already markdown - WebFetch those) and not for library docs (context7 covers those).
---

# Defuddle

```bash
defuddle parse <url> --md            # clean markdown to stdout
defuddle parse <url> --md -o out.md  # ... or to a file
```

Always pass `--md`. If not installed: `npm i -g defuddle-cli` (NOT `defuddle` —
that's the library package; both ship a `defuddle` bin but this skill was written
against defuddle-cli). `defuddle --help` covers the rest (`--json`, `-p title`).
