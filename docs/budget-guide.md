# Budget Guide

kiro-cli has a separate 2000 credit/month budget from your Claude Code session. Every task you route to kiro is Claude Code capacity preserved.

## Model rates

| Model | Rate | Monthly capacity |
|-------|------|-----------------|
| qwen3-coder-next | 0.05x | ~40,000 tasks |
| deepseek-3.2 | 0.25x | ~8,000 tasks |
| minimax-m2.1 | 0.15x | ~13,333 tasks |
| claude-haiku-4.5 | 0.40x | ~5,000 tasks |
| glm-5 | 0.50x | ~4,000 tasks |
| claude-sonnet-4.6 | 1.30x | ~1,538 tasks |
| claude-opus-4.8 | 2.20x | ~909 tasks |

## Real session cost example

A typical feature (4 tasks: 1× explore, 1× generate tests, 1× implement, 1× document):

| Task | Tier | Model | Est. credits |
|------|------|-------|-------------|
| Scan codebase for patterns | T0 | deepseek-3.2 | ~0.05 |
| Write unit tests | T1 | qwen3-coder | ~0.03 |
| Implement the feature | T2 | sonnet-4.6 | ~0.46 |
| Generate API docs | T1 | qwen3-coder | ~0.03 |
| **Total** | | | **~0.57 credits** |

0.57 credits out of 2000 = **0.03% of monthly budget** for a complete feature cycle.

## Tracking usage

```bash
kbudget          # show session total and monthly burn rate
kreset-budget    # reset session counter (e.g. start of day)
```

Credits are parsed from kiro's own output line: `Credits: 0.07 • Time: 5s`.

## Saving Claude Code capacity

Each task routed to kiro instead of Claude Code:
1. Doesn't consume a Claude Code message turn
2. Doesn't bloat the Claude Code context window with file reads
3. Can run in parallel (4 workers) vs. Claude Code's sequential turns

A session where you use `kturbo-t0` for 8 exploration tasks in parallel = 8 turns saved and ~2 seconds wall time instead of ~2 minutes.

## Setting a custom budget

Override the monthly cap for `kbudget` display:

```bash
export KIRO_MONTHLY_BUDGET=1500   # if you have a different plan
source ktask.sh
```
