# ktask demo

A guided 3-minute walkthrough of the full ktask pipeline.

## What the demo does

Takes a tiny Flask API (`demo/project/app.py`) that has no logging, and autonomously adds structured JSON request logging using the ktask pipeline:

```
ktask-new "add logging..."   →  generates task-01.md ... task-NN.md
ktask-loop ./tasks/          →  executes each task, routes by tier
                             →  all tasks renamed to .done.md
```

## Run it

```bash
cd ktask
./demo/run.sh
```

Add `--auto` to skip "Press Enter" prompts (good for screencasts):

```bash
./demo/run.sh --auto
```

## What you'll see

| Step | What happens |
|------|-------------|
| 0 | Pre-flight: checks kiro-cli auth and ktask.sh is loaded |
| 1 | Shows the sample project — a small Flask API with no logging |
| 2 | `ktask-new` calls kiro to decompose the feature into task files |
| 3 | Displays each generated task file (editable markdown) |
| 4 | `ktask-loop` runs all tasks autonomously, routing by tier |
| 5 | Shows completed `.done.md` files, the T2 implementation output, and budget used |

## Expected output

```
▶ Step 2  ktask-new — ask kiro to break the feature into atomic tasks

  created: demo/tasks/task-01.md   Explore existing app structure
  created: demo/tasks/task-02.md   Write tests for request logging
  created: demo/tasks/task-03.md   Implement JSON logging middleware
  created: demo/tasks/task-04.md   Document the logging configuration

▶ Step 4  ktask-loop — execute all tasks, route by tier, rename to .done.md

  ════ task-01.md [T0] ════  →  deepseek scout
  ════ task-02.md [T1] ════  →  qwen3-coder tester
  ════ task-03.md [T2] ════  →  sonnet coder
  ════ task-04.md [T1] ════  →  qwen3-coder doc-writer
  >> ktask-loop: all tasks complete.
```

## Requirements

- `kiro-cli` installed and authenticated (`kiro-cli whoami`)
- `ktask.sh` sourced or `install.sh` run
- `bc` for budget tracking (`apt install bc`)

## Files

```
demo/
├── run.sh          # the demo script
├── README.md       # this file
└── project/
    ├── app.py          # sample Flask API (the "before" state)
    └── requirements.txt
```

After the demo runs, `demo/tasks/` will contain the generated and executed task files.
