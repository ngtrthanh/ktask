# ktask

[![GitHub](https://img.shields.io/badge/GitHub-ngtrthanh%2Fktask-181717?logo=github&logoColor=white)](https://github.com/ngtrthanh/ktask)
[![Stars](https://img.shields.io/github/stars/ngtrthanh/ktask?style=flat&color=yellow)](https://github.com/ngtrthanh/ktask/stargazers)

**Autonomous development pipeline using Claude Code + kiro-cli.**

Claude Code handles judgment. kiro-cli workers handle execution. They share the workload, run in parallel, and bill to separate quotas.

---

## The Problem

Claude Code is powerful but has limits:
- **Context drift** — every file read adds tokens; long sessions become less precise
- **Sequential bottleneck** — one turn at a time; 10 independent tasks take 10 turns
- **Single quota** — all work bills to the same usage bucket

Running everything through Claude Code is like running every errand yourself when you could dispatch a team.

---

## The Solution

```
You
 └─▶ Claude Code              (orchestrator — judgment, architecture, synthesis)
       ├─▶ Direct edits       (high-stakes changes, context-dependent)
       └─▶ kturbo / kagent    (dispatches kiro workers — separate quota)
             ├─▶ kiro worker 1  ──┐
             ├─▶ kiro worker 2  ──┼── parallel, isolated contexts
             ├─▶ kiro worker 3  ──┤
             └─▶ kiro worker 4  ──┘
```

**kiro-cli** is a separate AI coding agent with its own credits/month budget (2000 for Pro+). By routing tasks to kiro workers:

- kiro burns kiro credits — Claude Code capacity is preserved
- Up to 4 workers run simultaneously — true parallelism
- Each worker has a clean context — no drift, no token bloat
- Task results are written to files — Claude Code reads summaries, not raw tool output

---

## Routing Tiers

Every task is assigned a tier based on its description. The tier determines the executor and model.

| Tier | Task Type | Executor | Model | Rate |
|------|-----------|----------|-------|------|
| **T3** | Architecture · Security · "Should I" · Judgment | Claude Code (you) | — | your quota |
| **T2** | Implement · Fix · Refactor · Debug | `coder` agent | claude-sonnet-4.6 | 1.30x |
| **T1** | Tests · Docs · Boilerplate · Scaffold | `tester` / `doc-writer` | qwen3-coder-next | **0.05x** |
| **T0** | Search · Grep · Explore · Summarise | `scout` / `analyst` | deepseek-3.2 | **0.25x** |

```
Does this task need:
 ├─ conversation context / prior decisions?  →  Claude Code (T3)
 ├─ architecture or security judgment?       →  Claude Code (T3)
 ├─ coding: implement, fix, refactor?        →  kiro coder  (T2)
 ├─ generation: tests, docs, scaffolding?    →  kiro tester (T1)
 └─ exploration: search, grep, summarise?    →  kiro scout  (T0)
```

Use `kroute "describe your task"` to get a recommendation without executing.

---

## Autonomous Task Loop

The highest-leverage feature: describe a feature, walk away, come back to done tasks.

```bash
# 1. Decompose a feature into atomic task files
ktask-new "add JWT authentication to the API" ./tasks/

# Output:
#   created: ./tasks/task-01.md  (explore existing auth patterns — T0)
#   created: ./tasks/task-02.md  (write tests for the JWT module — T1)
#   created: ./tasks/task-03.md  (implement JWT middleware — T2)
#   created: ./tasks/task-04.md  (document the auth endpoints — T1)

# 2. Execute all tasks in sequence, auto-routing by tier
ktask-loop ./tasks/

# Output:
#   ════ task-01.md [T0] ════  → kiro deepseek explores auth patterns  → task-01.done.md
#   ════ task-02.md [T1] ════  → kiro tester writes JWT tests          → task-02.done.md
#   ════ task-03.md [T2] ════  → kiro coder implements middleware       → task-03.done.md
#   ════ task-04.md [T1] ════  → kiro doc-writer documents endpoints   → task-04.done.md
#   >> ktask-loop: all tasks complete.
```

Each `.done.md` file contains the original task plus a `## Result` section with the executor output and timestamp. Full audit trail, no extra tooling.

---

## Install

```bash
git clone <repo-url> ~/dev/ktask
cd ~/dev/ktask
./install.sh
source ~/.bash_aliases
```

`install.sh` will:
1. Check that `kiro-cli` is installed and authenticated
2. Copy the 7 specialist agents to `~/.kiro/agents/`
3. Enable kiro's subagent feature (`chat.enableSubagent true`)
4. Add a `source` line to `~/.bash_aliases`

**Requirements:** `kiro-cli` (authenticated), `bash 4+`, `bc`

---

## Command Reference

### Task loop

```bash
ktask-new "feature description" [DIR]   # generate task-NN.md files
ktask-loop [DIR]                        # execute all task-*.md in order
ktask-run  task-01.md                   # execute a single task file
ktask-status [DIR]                      # show pending / done counts
```

### Single-shot queries

```bash
kask "question" [MODEL]   # one kiro query, any model
kh   "question"           # haiku (0.40x) — fast
kq   "question"           # qwen3-coder (0.05x) — ultra cheap code gen
kds  "question"           # deepseek (0.25x) — cheap research
```

### Parallel execution (up to 4 workers)

```bash
kturbo    "t1" "t2" "t3" "t4"           # auto model
kturbo -m MODEL "t1" ...                # pin model
kturbo-t0 "t1" "t2" "t3" "t4"          # deepseek (T0)
kturbo-t1 "t1" "t2" "t3" "t4"          # qwen3-coder (T1)
kturbo-t2 "t1" "t2" "t3" "t4"          # sonnet (T2)
kturbo-fast "t1" "t2" "t3" "t4"        # haiku
kparallel tasks.txt [MODEL]             # file-based batch, auto-batches 4
```

### Named agents

```bash
kagent scout "where is validateUser defined?"
kagent analyst "summarise error patterns in app.log"
kagent tester "write tests for src/auth/token.go"
kagent coder "implement the rate limiter in src/middleware/"

kagent-turbo tester "t1" "t2" "t3"     # 3 test tasks in parallel
```

### Job monitoring

```bash
kstats                      # show job history stats from ~/.ktask_jobs.jsonl
```

### Routing and budget

```bash
kroute "task description"   # print recommended tier + command
kbudget                     # session credit usage + monthly reference
kreset-budget               # reset session counter
kmodels                     # list models with credit rates
```

### Interactive sessions

```bash
korchestrate    # kiro TUI — orchestrator agent with internal subagents
korch-classic   # same, classic terminal UI
kiro            # plain kiro interactive chat
```

---

## Benefit: Quantified

### Context preservation

A typical "explore 10 files" task in Claude Code:
- 10 `Read` tool calls → 10 tool result blocks in context
- Context grows by ~20K tokens
- Future turns are slower and more expensive

Same task via kiro:
```bash
kturbo-t0 \
  "list all exported functions in src/api/" \
  "find all files importing from @internal/" \
  "grep for TODO/FIXME, group by file" \
  "summarise the directory structure under src/"
```
- 4 workers run in parallel (~5s wall time)
- Claude Code receives 4 short text summaries
- Context grows by ~2K tokens (summaries, not raw tool output)
- **~10× less context growth, ~10× less time**

### Cost efficiency

A full feature cycle (explore → generate → implement → document):

| Without ktask | With ktask | Saving |
|---|---|---|
| 15–20 Claude Code turns | 3–4 Claude Code turns | ~80% turns saved |
| Sequential, ~15 min | Parallel, ~3 min | ~80% time saved |
| All on Claude quota | T0/T1/T2 on kiro quota | Separate billing |
| 0.05% budget/feature | 0.03% kiro budget | Budget split across two systems |

### Quality gates

T3 tasks **halt the loop** and print `NEEDS HUMAN:`. This means:
- Architecture decisions always surface to you
- Security changes never happen autonomously
- The pipeline knows what it doesn't know

---

## How It Works: The Full Pipeline

```
ktask-new "add Slack alerts to my monitoring system"
    │
    ▼
kiro sonnet plans 4 tasks, writes task-01.md ... task-04.md
    │
    ▼
ktask-loop ./tasks/
    │
    ├─ task-01.md  "find all alert call sites in scanner/"
    │    tier: T0  →  kiro deepseek scout reads codebase  →  task-01.done.md
    │
    ├─ task-02.md  "write unit tests for the new Slack notifier"
    │    tier: T1  →  kiro qwen3-coder tester writes tests  →  task-02.done.md
    │
    ├─ task-03.md  "implement internal/notifier/slack.go"
    │    tier: T2  →  kiro sonnet coder reads existing alert.go,
    │                  implements Slack client, runs go build  →  task-03.done.md
    │
    └─ task-04.md  "review the security implications of the Slack webhook"
         tier: T3  →  NEEDS HUMAN — loop halts, you review
```

---

## Task File Format

```markdown
# Task: Short imperative title

## Description
What to do and why, in 1-3 sentences.

## Context          ← optional but improves T2 quality
- Relevant file paths
- Framework or library in use

## Checklist
- [ ] Concrete step 1
- [ ] Concrete step 2
```

After execution, `ktask-run` appends:

```markdown
## Result

Tier: T2  |  Completed: 2026-06-21T05:46:00Z

[executor output]
```

See [docs/task-format.md](docs/task-format.md) for the full spec.

---

## Agents

| Agent | Role | Model |
|-------|------|-------|
| `orchestrator` | Decomposes + delegates to internal subagents | auto |
| `scout` | Finds symbols, call graphs, imports | deepseek-3.2 |
| `analyst` | Log scanning, structured reports | haiku-4.5 |
| `researcher` | Web search + URL fetch | haiku-4.5 |
| `tester` | Unit/integration test generation | qwen3-coder-next |
| `doc-writer` | Docstrings, README sections, comments | qwen3-coder-next |
| `coder` | Full implementation tasks | claude-sonnet-4.6 |

See [docs/agents.md](docs/agents.md) for configuration details.

---

## Files

```
ktask/
├── ktask.sh              # shell library — source this
├── install.sh            # one-command installer
├── agents/               # kiro agent configs (copied to ~/.kiro/agents/)
│   ├── orchestrator.json
│   ├── scout.json
│   ├── analyst.json
│   ├── researcher.json
│   ├── tester.json
│   ├── doc-writer.json
│   └── coder.json
├── examples/
│   └── tasks/            # three example task files to try
│       ├── task-01.md    # T0: find TODO comments
│       ├── task-02.md    # T1: write auth tests
│       └── task-03.md    # T2: implement rate limiting
└── docs/
    ├── routing-tiers.md  # tier system explained
    ├── task-format.md    # task file spec
    ├── budget-guide.md   # credit budget strategy
    └── agents.md         # agent configs and customisation
```

---

## Quick Start

```bash
# Install
git clone <repo> ~/dev/ktask && cd ~/dev/ktask && ./install.sh
source ~/.bash_aliases

# Check setup
kwhoami && kagents && kmodels

# Try the routing advisor
kroute "find all database calls in the codebase"
kroute "write unit tests for the payment module"
kroute "implement the checkout flow"
kroute "should we use Redis or Postgres for sessions"

# Run a parallel research batch
kturbo-t0 \
  "list all Go interfaces in the project" \
  "find all TODO comments grouped by file" \
  "summarise the test coverage across packages" \
  "check which files have no error handling"

# Run the autonomous task loop
ktask-new "add request logging middleware to the API" ./tasks/
ktask-loop ./tasks/

# Check job stats
kstats

# Check budget used
kbudget
```
