---
name: graphify
description: "Use for STRUCTURE questions about a LARGE or UNFAMILIAR codebase where reading the source won't cover it: architecture, file/module relationships, 'what touches X', cross-document connections. NOT the first stop for how-code-behaves questions in a small or familiar repo (read the source), and graph answers about behavior must be confirmed in source before changing code: the graph is a derived map, built on demand and stale until rebuilt — not ground truth. Turns any input (code, docs, papers, images, videos) into a persistent knowledge graph with god nodes, community detection, and query/path/explain tools."
---

# /graphify

Query-first. The graph is an on-demand map for large or unfamiliar corpora, stale
until rebuilt. Verified against graphifyy `0.9.23` (see `.graphify_version`); the
full upstream build-pipeline skill this replaced lives in git history (pre-2026-08)
if a deep semantic build is ever needed again.

## Query an existing graph (the common case)

Run from the repo root — all three read `graphify-out/graph.json`:

```bash
graphify query "how does auth connect to the api?"   # NL query; --budget N caps output (default 2000 tokens)
graphify path "NodeA" "NodeB"                        # shortest path between two nodes
graphify explain "SomeNode"                          # a node and its neighbors, plain language
```

The graph shows structure as of its last build, nothing newer — confirm any
behavior claim in source before changing code.

## Build or refresh (on demand only)

- **Code-only corpus** (the usual case): `graphify update .` — pure AST, zero LLM
  tokens. Same command refreshes an existing graph after changes.
- **Mixed corpus** (docs/papers/images worth semantic extraction): only for large
  corpora. Load `references/extraction-spec.md` and follow it VERBATIM as the
  subagent extraction prompt — its node-ID format must byte-match the AST
  extractor's output, or the merge produces orphan duplicate nodes.
- Outputs land in `graphify-out/` (`graph.json`, `GRAPH_REPORT.md`, `graph.html`),
  kept out of every repo's `git status` by the machine-wide ignore
  (`~/.config/git/ignore`).

## Local guards (deviations from upstream — keep these)

- A **tracked** `graphify-out/` is the team's committed artifact: read theirs,
  never rebuild over it (`git ls-files --error-unmatch graphify-out/graph.json`
  exits 0 = tracked).
- **No auto-refresh exists on this machine** — removed 2026-08-26 after 351
  background rebuilds against 7 manual queries. Do NOT run
  `graphify hook install`, `graphify claude install`, or upstream's silent
  `uv tool install --upgrade graphifyy` step unless explicitly asked: the first
  two re-create always-on wiring, the third moves the pinned version.
- Never merge onto a live `graph.json`: `graphify merge-graphs` into a scratch
  `--out` path, inspect, then replace.

## CLI notes

`graphify --help` under-documents the CLI: subcommand `--help` is a stub, and real
subcommands missing from the top-level listing include
`export html|obsidian|wiki|svg|graphml|neo4j|falkordb` and `reflect --if-stale`
(verified against 0.9.23 source, 2026-08-26).
