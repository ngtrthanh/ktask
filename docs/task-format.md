# Task File Format

Task files are plain markdown. `ktask-run` reads the title, description, and checklist to construct the prompt sent to the kiro executor.

## Minimal format

```markdown
# Task: Short imperative title

## Description
1-3 sentences explaining what to do and why.

## Checklist
- [ ] Step 1
- [ ] Step 2
```

## Full format (with context)

```markdown
# Task: Implement rate limiting middleware

## Description
Add per-IP rate limiting to the API layer. Each IP is limited to 100 req/min.
Return 429 with Retry-After header on breach.

## Context
- Framework: Express.js
- Existing middleware: src/middleware/auth.js (see pattern)
- Config file: src/config/server.js

## Checklist
- [ ] Read src/middleware/auth.js to understand registration pattern
- [ ] Implement sliding-window limiter using in-memory Map
- [ ] Register on all routes in src/app.js
- [ ] Return { error, retryAfter } JSON on 429
```

## After execution

`ktask-run` appends a `## Result` section with execution metadata:

```markdown
## Result

Tier: T2  |  Completed: 2026-06-21T05:46:00Z

[kiro executor output here]
```

The file is then renamed `task-NN.done.md`.

## File naming

Task files must match `task-*.md` to be picked up by `ktask-loop`. Recommended naming:
- `task-01.md`, `task-02.md` — sequential for ordered execution
- `task-auth-01.md` — feature-prefixed for grouped tasks

`ktask-new` always generates `task-NN.md` with zero-padded two-digit numbers starting from the next available slot.

## Tips

- **Keep tasks atomic**: one task should produce one coherent diff or report. Multi-file refactors that depend on each other should be split into sequenced task files.
- **Include file paths**: the more specific the path context, the less time the executor spends searching.
- **T2 tasks benefit from `## Context`**: the coder agent reads the context block and uses it to locate the right files before implementing.
- **T3 tasks halt the loop**: if you want Claude Code to review something mid-pipeline, add a T3-keyword (e.g., "review this design") to a task and the loop will pause there.
