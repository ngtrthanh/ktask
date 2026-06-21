# Routing Tiers

The routing system assigns every task to one of four tiers based on keyword analysis of the task description. The tier determines which executor handles the task and at what cost.

## Tier Overview

```
T3  judgment / architecture / security
      └─▶ Claude Code (this session, your quota)

T2  implement / fix / refactor / debug
      └─▶ kiro coder agent (claude-sonnet-4.6, 1.30x credits)

T1  tests / docs / boilerplate / scaffold
      └─▶ kiro tester / doc-writer / qwen3-coder-next (0.05x credits)

T0  search / explore / grep / summarize / research
      └─▶ kiro analyst / scout / deepseek-3.2 (0.25x credits)
```

## Why This Ordering

**T3 stays in Claude Code** because these tasks require:
- Full conversation context (Claude Code has it; kiro workers don't)
- Judgment about tradeoffs that can't be expressed in a static prompt
- Accountability — security and architecture decisions need human review

**T2 goes to kiro sonnet** because implementation is:
- Self-contained: "read X, implement Y, verify with Z"
- High enough stakes to use the best autonomous coding model
- Parallelisable: 4 implementation tasks can run at once

**T1 goes to qwen3-coder** because generation is:
- Deterministic given a clear spec
- Very cheap at 0.05x — 40,000 tasks per 2000-credit budget
- Low risk: tests and docs don't break production

**T0 goes to deepseek** because exploration is:
- Pure I/O — read files, search, count, report
- Independent of each other — ideal for 4-way parallelism
- Extremely cheap: the result feeds T2/T3 decisions

## Keyword Detection

The tier detector (`_ktask_tier`) uses regex patterns on the lowercased task content:

| Tier | Trigger keywords |
|------|-----------------|
| T3 | architect, design decision, should i, security, vulnerability, code review, tradeoff, scalab* |
| T2 | implement, fix bug, refactor, debug, add feature, migrate, integrate, build module |
| T1 | write test, unit test, docstring, readme, documentation, boilerplate, scaffold, create file |
| T0 | search, find, list, grep, scan, count, explore, summarize, research, analyze log |

Tiers are checked top-down (T3 first). The first match wins. Unmatched tasks default to T0.

## Overriding the Tier

The `ktask-run` function detects tier automatically. To force a model:

```bash
# Force a T0 task onto sonnet (e.g., exploration that needs web search)
kask "$(cat task-01.md)" claude-sonnet-4.6

# Force T1 through the orchestrator for complex scaffolding
kagent orchestrator "$(cat task-01.md)"
```

## Adjusting Patterns

Edit `_ktask_tier()` in `ktask.sh` to add project-specific keywords:

```bash
local t2_pat="(implement|fix bug|your-project-verb|...)"
```
