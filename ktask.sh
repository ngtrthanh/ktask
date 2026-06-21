#!/usr/bin/env bash
# ktask.sh — Claude Code + kiro-cli shared-workload system
#
# Source this file in your shell:
#   echo 'source /path/to/ktask/ktask.sh' >> ~/.bashrc
#
# Or run install.sh to set everything up automatically.
#
# REQUIRES: kiro-cli installed and authenticated (kiro-cli whoami)
# REQUIRES: bc (apt install bc)

# ── Configuration ─────────────────────────────────────────────────────────────

KTASK_DIR="${KTASK_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
KIRO_BUDGET_FILE="${HOME}/.kiro_session_budget"
KIRO_MONTHLY_BUDGET="${KIRO_MONTHLY_BUDGET:-2000}"

# ── Internal helpers ──────────────────────────────────────────────────────────

# Strip ANSI escape codes from a string
function _kiro_strip_ansi() {
    echo "$1" | sed 's/\x1b\[[0-9;]*[mGKHF]//g' | sed 's/\x1b\[[?][0-9]*[hl]//g'
}

# Parse and accumulate credit usage from kiro output
function _kiro_accum_credits() {
    local credits
    credits=$(echo "$1" | grep -oP 'Credits: \K[0-9.]+' | tail -1)
    if [ -n "$credits" ]; then
        local prev; prev=$(cat "$KIRO_BUDGET_FILE" 2>/dev/null || echo "0")
        printf "%.4f" "$(echo "$prev + $credits" | bc -l)" > "$KIRO_BUDGET_FILE"
    fi
}

# Detect task tier from content keywords
function _ktask_tier() {
    local content="${1,,}"
    local t3_pat="(architect|design decision|should i|best approach|security|vulnerabilit|review this|code review|is it safe|tradeoff|scalab)"
    local t2_pat="(implement|fix bug|refactor|debug|add feature|update.*function|migrate|integrate|build.*module)"
    local t1_pat="(write test|unit test|docstring|readme|documentation|boilerplate|scaffold|generate.*class|create.*file)"
    if echo "$content" | grep -qP "$t3_pat"; then echo "T3"
    elif echo "$content" | grep -qP "$t2_pat"; then echo "T2"
    elif echo "$content" | grep -qP "$t1_pat"; then echo "T1"
    else echo "T0"
    fi
}

# Extract task body (everything before ## Result)
function _ktask_extract() {
    awk '/^## Result/{exit} {print}' "$1"
}

# ── Budget ────────────────────────────────────────────────────────────────────

# kbudget — show session credit usage and monthly reference
function kbudget() {
    local used; used=$(cat "$KIRO_BUDGET_FILE" 2>/dev/null || echo "0")
    local pct; pct=$(echo "scale=1; $used * 100 / $KIRO_MONTHLY_BUDGET" | bc -l 2>/dev/null || echo "?")
    printf '\n  kiro-cli Credit Budget\n'
    printf '  ─────────────────────────────────────────\n'
    printf '  Session used  : %s credits\n' "$used"
    printf '  Monthly quota : %s credits\n' "$KIRO_MONTHLY_BUDGET"
    printf '  Session burn  : %s%% of monthly\n\n' "$pct"
    printf '  Model rates:\n'
    printf '    qwen3-coder-next  0.05x  →  ~40,000 tasks/month\n'
    printf '    deepseek-3.2      0.25x  →   ~8,000 tasks/month\n'
    printf '    claude-haiku-4.5  0.40x  →   ~5,000 tasks/month\n'
    printf '    claude-sonnet-4.6 1.30x  →   ~1,538 tasks/month\n'
    printf '    claude-opus-4.8   2.20x  →     ~909 tasks/month\n\n'
}

# kreset-budget — reset session accumulator
function kreset-budget() {
    echo "0" > "$KIRO_BUDGET_FILE"
    echo ">> budget counter reset."
}

# ── Routing advisor ───────────────────────────────────────────────────────────

# kroute "task" — print recommended tier and command without executing
function kroute() {
    local task="${1:?Usage: kroute \"task description\"}"
    local tl="${task,,}"
    local t3_pat="(architect|design decision|should i|best approach|security|vulnerabilit|review this|code review|is it safe|tradeoff|scalab)"
    local t2_pat="(implement|fix bug|refactor|debug|add feature|update.*function|migrate|integrate|build.*module)"
    local t1_pat="(write test|unit test|docstring|readme|documentation|boilerplate|scaffold|generate.*class|create.*file)"
    local t0_pat="(search|find|list|what is|where is|grep|scan|count|explore|summarize|research|check if|look for|analyze log)"
    if echo "$tl" | grep -qP "$t3_pat"; then
        echo "  T3 → Claude Code directly  (judgment / architecture / security)"
    elif echo "$tl" | grep -qP "$t2_pat"; then
        echo "  T2 → kask \"$task\" claude-sonnet-4.6  (1.30x)"
    elif echo "$tl" | grep -qP "$t1_pat"; then
        echo "  T1 → kask \"$task\" qwen3-coder-next   (0.05x)"
    elif echo "$tl" | grep -qP "$t0_pat"; then
        echo "  T0 → kask \"$task\" deepseek-3.2       (0.25x)"
    else
        echo "  T1/2 → kask \"$task\"  (auto model)"
    fi
}

# ── Single-shot queries ───────────────────────────────────────────────────────

# kask "task" [MODEL] — one non-interactive kiro query
function kask() {
    local out
    out=$(echo "$1" | kiro-cli chat --no-interactive --trust-all-tools --model "${2:-auto}" 2>&1)
    _kiro_accum_credits "$out"
    echo "$out"
}

# kh / kq / kds — model-pinned aliases
function kh()  { local o; o=$(echo "$1" | kiro-cli chat --no-interactive --trust-all-tools --model claude-haiku-4.5 2>&1);      _kiro_accum_credits "$o"; echo "$o"; }
function kq()  { local o; o=$(echo "$1" | kiro-cli chat --no-interactive --trust-all-tools --model qwen3-coder-next 2>&1);    _kiro_accum_credits "$o"; echo "$o"; }
function kds() { local o; o=$(echo "$1" | kiro-cli chat --no-interactive --trust-all-tools --model deepseek-3.2 2>&1);         _kiro_accum_credits "$o"; echo "$o"; }

# ── Parallel execution ────────────────────────────────────────────────────────

# kturbo [-m MODEL] "t1" "t2" "t3" "t4"
# Run up to 4 kiro workers in parallel, collect and print labeled results.
function kturbo() {
    local model="auto"
    if [[ "$1" == "-m" ]]; then model="$2"; shift 2; fi
    if [ $# -eq 0 ]; then echo "Usage: kturbo [-m MODEL] \"t1\" [\"t2\"] [\"t3\"] [\"t4\"]"; return 1; fi

    local tasks=("$@")
    local count=$(( ${#tasks[@]} > 4 ? 4 : ${#tasks[@]} ))
    local pids=() tmpfiles=()

    echo ">> kturbo: launching $count worker(s) in parallel [model: $model]..."
    for (( i=0; i<count; i++ )); do
        local tmp; tmp=$(mktemp /tmp/kturbo_XXXXXX)
        tmpfiles+=("$tmp")
        echo "${tasks[$i]}" | kiro-cli chat --no-interactive --trust-all-tools --model "$model" > "$tmp" 2>&1 &
        pids+=($!)
    done

    local total=0
    for (( i=0; i<count; i++ )); do
        wait "${pids[$i]}"
        local cr; cr=$(grep -oP 'Credits: \K[0-9.]+' "${tmpfiles[$i]}" | tail -1)
        [ -n "$cr" ] && { _kiro_accum_credits "Credits: $cr"; total=$(echo "$total + $cr" | bc -l 2>/dev/null || echo "$total"); }
        printf '\n━━━ Worker %d/%d%s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' $((i+1)) $count "${cr:+  [${cr} cr]}"
        printf 'Task  : %s\n' "${tasks[$i]}"
        printf '────────────────────────────────────────────────────────────\n'
        cat "${tmpfiles[$i]}"; rm -f "${tmpfiles[$i]}"
    done
    printf '\n>> kturbo: done. Batch cost: %.4f credits\n' "$total"
}

# Tier-pinned kturbo variants
function kturbo-t0()   { kturbo -m deepseek-3.2      "$@"; }  # 0.25x — explore/research
function kturbo-t1()   { kturbo -m qwen3-coder-next   "$@"; }  # 0.05x — generate/boilerplate
function kturbo-t2()   { kturbo -m claude-sonnet-4.6  "$@"; }  # 1.30x — implement/fix
function kturbo-fast() { kturbo -m claude-haiku-4.5   "$@"; }  # 0.40x — general fast

# kparallel FILE [MODEL] — batch-execute tasks from a file (one per line), 4 at a time
function kparallel() {
    local file="${1:?Usage: kparallel <tasks-file> [model]}"
    local model="${2:-auto}"
    [ ! -f "$file" ] && echo "ERROR: $file not found" && return 1
    local batch=() n=1
    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        batch+=("$line")
        if [ ${#batch[@]} -eq 4 ]; then
            echo ">> kparallel: batch $n"; kturbo -m "$model" "${batch[@]}"; batch=(); (( n++ ))
        fi
    done < "$file"
    [ ${#batch[@]} -gt 0 ] && { echo ">> kparallel: batch $n"; kturbo -m "$model" "${batch[@]}"; }
}

# ── Named-agent dispatch ──────────────────────────────────────────────────────

# kagent AGENT "task" — run a named kiro agent non-interactively
function kagent() {
    local agent="${1:?Usage: kagent <agent> \"task\"}"
    local out
    out=$(echo "${2:?Missing task}" | kiro-cli chat --no-interactive --trust-all-tools --agent "$agent" 2>&1)
    _kiro_accum_credits "$out"
    echo "$out"
}

# kagent-turbo AGENT "t1" "t2" ... — up to 4 tasks on the same agent in parallel
function kagent-turbo() {
    local agent="${1:?Usage: kagent-turbo <agent> \"t1\" [\"t2\"] ...}"; shift
    [ $# -eq 0 ] && echo "No tasks provided." && return 1
    local tasks=("$@")
    local count=$(( ${#tasks[@]} > 4 ? 4 : ${#tasks[@]} ))
    local pids=() tmpfiles=()
    echo ">> kagent-turbo [$agent]: launching $count worker(s)..."
    for (( i=0; i<count; i++ )); do
        local tmp; tmp=$(mktemp /tmp/kagent_XXXXXX); tmpfiles+=("$tmp")
        echo "${tasks[$i]}" | kiro-cli chat --no-interactive --trust-all-tools --agent "$agent" > "$tmp" 2>&1 &
        pids+=($!)
    done
    for (( i=0; i<count; i++ )); do
        wait "${pids[$i]}"
        local cr; cr=$(grep -oP 'Credits: \K[0-9.]+' "${tmpfiles[$i]}" | tail -1)
        [ -n "$cr" ] && _kiro_accum_credits "Credits: $cr"
        printf '\n━━━ [%s] %d/%d%s ━━━\n' "$agent" $((i+1)) $count "${cr:+  [${cr} cr]}"
        cat "${tmpfiles[$i]}"; rm -f "${tmpfiles[$i]}"
    done
    echo ">> kagent-turbo: done."
}

# ── Task loop ─────────────────────────────────────────────────────────────────

# ktask-new "feature description" [DIR]
# Ask kiro to decompose the feature into atomic task-NN.md files.
function ktask-new() {
    local desc="${1:?Usage: ktask-new \"feature description\" [output-dir]}"
    local dir="${2:-.}"
    mkdir -p "$dir"

    local next=1
    while [ -f "$dir/task-$(printf '%02d' $next).md" ] || \
          [ -f "$dir/task-$(printf '%02d' $next).done.md" ]; do (( next++ )); done

    echo ">> ktask-new: planning tasks for: $desc"
    local raw
    raw=$(kask "You are a task planner. Break the following feature into 3-6 atomic, self-contained development tasks.
For each task output EXACTLY this format with XTASK and XEND as literal delimiters:

XTASK
# Task: <short imperative title>

## Description
<1-2 sentences of what to do and why>

## Checklist
- [ ] concrete step
- [ ] concrete step
XEND

Feature: $desc

Output ONLY the XTASK/XEND blocks, no other text." claude-sonnet-4.6)

    local clean; clean=$(_kiro_strip_ansi "$raw")
    local n=$next in_task=0 content=""

    while IFS= read -r line; do
        if [[ "$line" == "XTASK" ]]; then in_task=1; content=""
        elif [[ "$line" == "XEND" ]]; then
            if [ $in_task -eq 1 ] && [ -n "$content" ]; then
                local f="$dir/task-$(printf '%02d' $n).md"
                printf '%s' "$content" > "$f"
                echo "  created: $f"
                (( n++ ))
            fi
            in_task=0; content=""
        elif [ $in_task -eq 1 ]; then
            content+="$line"$'\n'
        fi
    done <<< "$clean"

    local created=$(( n - next ))
    echo ">> ktask-new: $created task(s) created in $dir"
    [ $created -gt 0 ] && echo "   Next: ktask-loop $dir"
}

# ktask-run TASK_FILE
# Execute one task file: detect tier → route to right executor →
# append ## Result → rename to .done.md
function ktask-run() {
    local file="${1:?Usage: ktask-run <task-file>}"
    [ ! -f "$file" ] && echo "ERROR: not found: $file" && return 1

    local content; content=$(_ktask_extract "$file")
    local tier; tier=$(_ktask_tier "$content")
    echo ">> ktask-run: $(basename "$file")  [tier: $tier]"

    local result=""
    case "$tier" in
        T3)
            local title; title=$(grep -m1 '^#' "$file" | sed 's/^#* *//')
            echo "  NEEDS HUMAN: $title"
            echo "  → T3 requires judgment. Halting loop."
            return 2
            ;;
        T2)
            result=$(kagent coder "$content")
            ;;
        T1)
            if echo "${content,,}" | grep -qP "(test|spec)"; then
                result=$(kagent tester "$content")
            elif echo "${content,,}" | grep -qP "(doc|readme|comment)"; then
                result=$(kagent doc-writer "$content")
            else
                result=$(kq "$content")
            fi
            ;;
        T0)
            result=$(kturbo-t0 "$content")
            ;;
    esac

    {
        printf '\n## Result\n\n'
        printf 'Tier: %s  |  Completed: %s\n\n' "$tier" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        echo "$result"
    } >> "$file"

    local done="${file%.md}.done.md"
    mv "$file" "$done"
    echo ">> ktask-run: done → $(basename "$done")"
}

# ktask-loop [DIR]
# Process all task-*.md files in DIR numerically.
# Halts on T3 tasks (requires human input), continues through T0/T1/T2.
function ktask-loop() {
    local dir="${1:-.}"
    local found=0

    for f in $(ls "$dir"/task-*.md 2>/dev/null | sort -t- -k2 -V); do
        found=1
        printf '\n════════════════════════════════════════════════════════════\n'
        printf ' %s\n' "$(basename "$f")"
        printf '════════════════════════════════════════════════════════════\n'
        ktask-run "$f"
        [ $? -eq 2 ] && echo ">> ktask-loop: halted — human input required." && return 2
    done

    [ $found -eq 0 ] && echo ">> ktask-loop: no task-*.md files in $dir" && return 1
    printf '\n>> ktask-loop: all tasks complete.\n'
}

# ktask-status [DIR] — show pending and completed task counts
function ktask-status() {
    local dir="${1:-.}"
    local pending; pending=$(ls "$dir"/task-*.md 2>/dev/null | wc -l)
    local done; done=$(ls "$dir"/task-*.done.md 2>/dev/null | wc -l)
    local total=$(( pending + done ))
    printf '\n  Task status in %s\n' "$dir"
    printf '  ──────────────────────────────\n'
    printf '  Total    : %d\n' "$total"
    printf '  Done     : %d\n' "$done"
    printf '  Pending  : %d\n\n' "$pending"
    [ $pending -gt 0 ] && ls "$dir"/task-*.md 2>/dev/null | while read -r f; do
        printf '  [ ] %s\n' "$(basename "$f")"
    done
    [ $done -gt 0 ] && ls "$dir"/task-*.done.md 2>/dev/null | while read -r f; do
        printf '  [x] %s\n' "$(basename "$f")"
    done
    echo ""
}

# ── Interactive sessions ──────────────────────────────────────────────────────

alias korchestrate='kiro-cli chat --tui --trust-all-tools --agent orchestrator'
alias korch-classic='kiro-cli chat --trust-all-tools --agent orchestrator'
alias kiro='kiro-cli chat --trust-all-tools'

# ── Agent management ──────────────────────────────────────────────────────────

alias kagents='kiro-cli agent list'
alias kmodels='kiro-cli chat --list-models'
alias kwhoami='kiro-cli whoami'
function knew()  { kiro-cli agent create "${1:?Usage: knew <name>}"; }
function kedit() { kiro-cli agent edit "${1:?Usage: kedit <name>}"; }
