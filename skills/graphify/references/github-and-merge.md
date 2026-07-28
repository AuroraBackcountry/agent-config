# graphify reference: GitHub clone and cross-repo merge

Load this when the user passed one or more `https://github.com/...` URLs, or named several local subfolders to merge into one graph.

> **Local deviation (verified 2026-07-28, graphifyy 0.9.23): never merge to `--out
> graphify-out/graph.json`** — not even where the monorepo snippet below says to.
> That path is the live per-repo graph, and `graphify update` (which the scaffold
> post-commit hook runs after every commit) reconciles it in place: the local repo's
> `repo::`-prefixed nodes get re-keyed to bare ids, dangling any cross-repo edge that
> referenced them, and foreign-node survival is an implementation detail of the
> reconcile pass, not a contract. Merge to a separate sibling file instead —
> `graphify-out/merged-graph.json` (the CLI's own default) or `cross-repo-graph.json`
> — which `update` and the hook never touch. Query it explicitly:
> `graphify query "..." --graph graphify-out/merged-graph.json`. The "fast path takes
> over" sentence at the bottom does not apply to merged graphs; refresh one by
> re-running `merge-graphs` after a source graph changes. And keep merged graphs out
> of the vault: they're derived Structure, `save-result`/`reflect`/reports assume
> `memory/` sits beside the graph, and the machine-wide ignore already hides
> `graphify-out/` everywhere — guest repos included.

### Step 0 - Clone GitHub repo(s) (only if a GitHub URL was given)

**Single repo:**
```bash
LOCAL_PATH=$(graphify clone <github-url> [--branch <branch>])
# Use LOCAL_PATH as the target for all subsequent steps
```

**Multiple repos (cross-repo graph):**
```bash
# Clone each repo, run the full pipeline on each, then merge
graphify clone <url1>   # → ~/.graphify/repos/<owner1>/<repo1>
graphify clone <url2>   # → ~/.graphify/repos/<owner2>/<repo2>
# Run /graphify on each local path to produce their graph.json files
# Then merge:
graphify merge-graphs \
  ~/.graphify/repos/<owner1>/<repo1>/graphify-out/graph.json \
  ~/.graphify/repos/<owner2>/<repo2>/graphify-out/graph.json \
  --out graphify-out/cross-repo-graph.json
```

Graphify clones into `~/.graphify/repos/<owner>/<repo>` and reuses existing clones on repeat runs. Each node in the merged graph carries a `repo` attribute so you can filter by origin.

**Multiple local subfolders (monorepo or multi-service layout):**

The skill pipeline writes all intermediate and final outputs to `graphify-out/` in the current working directory. Running the skill on each subfolder separately will clobber the same output dir. Instead, use the CLI directly for each subfolder — it places `graphify-out/` *inside* the scanned path:

```bash
graphify extract ./core/     # → ./core/graphify-out/graph.json
graphify extract ./service/  # → ./service/graphify-out/graph.json
graphify extract ./platform/ # → ./platform/graphify-out/graph.json
# Add --backend gemini|kimi|openai|deepseek|claude-cli depending on which API key you have set

# Then merge at the project root:
graphify merge-graphs \
  ./core/graphify-out/graph.json \
  ./service/graphify-out/graph.json \
  ./platform/graphify-out/graph.json \
  --out graphify-out/graph.json
```

Once `graphify-out/graph.json` exists, the fast path above takes over: any codebase question runs `graphify query` directly on the merged graph — no re-extraction, no size gate.
