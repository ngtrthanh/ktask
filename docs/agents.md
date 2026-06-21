# Agents

Seven specialist agents are included. All are globally installed to `~/.kiro/agents/` by `install.sh`.

## Agent roster

| Agent | Tier | Model | Purpose |
|-------|------|-------|---------|
| `orchestrator` | — | auto | Decomposes tasks and delegates to internal subagents (up to 4 parallel) via kiro's `use_subagent` tool |
| `scout` | T0 | deepseek-3.2 | Finds symbols, traces call graphs, maps imports — returns exact file paths and line numbers |
| `analyst` | T0 | haiku-4.5 | Scans logs, counts occurrences, summarises data — returns structured markdown tables |
| `researcher` | T0/1 | haiku-4.5 | Web search and URL fetching — returns cited factual summaries |
| `tester` | T1 | qwen3-coder-next | Writes unit/integration tests matching project conventions |
| `doc-writer` | T1 | qwen3-coder-next | Writes docstrings, README sections, and inline comments |
| `coder` | T2 | sonnet-4.6 | Isolated coding tasks — reads, implements, runs verification, reports diff |

## Customising agents

Edit any JSON file in `agents/` and re-run `install.sh` to deploy.

Key fields:
```json
{
  "name": "my-agent",
  "description": "shown in kagents list",
  "prompt": "system prompt injected before every task",
  "tools": ["read", "write", "shell", "grep", "glob"],
  "model": "claude-haiku-4.5",
  "includeMcpJson": false
}
```

Available tools: `read`, `write`, `shell`, `grep`, `glob`, `code`, `delegate`, `web_search`, `web_fetch`, `use_aws`

## Creating a project-local agent

Place a `agents/` directory in your project root with agent JSON files. kiro-cli discovers them automatically when invoked from that directory.

```bash
mkdir -p .kiro/agents/
cp $(ktask-dir)/agents/coder.json .kiro/agents/my-coder.json
# edit .kiro/agents/my-coder.json with project-specific prompt
kagent my-coder "implement the payment flow"
```

## The orchestrator agent

The orchestrator uses kiro's internal `use_subagent` tool — distinct from the shell-level `kturbo` parallelism. When you run `korchestrate` or `kagent orchestrator "..."`, the orchestrator:

1. Reads the task
2. Decomposes it into subtasks
3. Spawns up to 4 kiro subagents internally and in parallel
4. Synthesises all results

This is different from `kturbo` in that the orchestrator has a single unified context across results; `kturbo` spawns isolated processes whose outputs you receive separately.
