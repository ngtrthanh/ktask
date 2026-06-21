#!/usr/bin/env bash
# demo/run.sh — ktask onboarding demo
#
# Walks a newcomer through the full ktask pipeline in ~3 minutes:
#   1. Check setup
#   2. See what the sample project looks like
#   3. ktask-new: decompose a feature into task files
#   4. ktask-loop: execute all tasks autonomously
#   5. Inspect results + budget
#
# Usage: ./demo/run.sh [--auto]
#   --auto  skip "press enter" prompts (for CI / screencasts)

KTASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEMO_DIR="$KTASK_DIR/demo"
PROJECT_DIR="$DEMO_DIR/project"
TASKS_DIR="$DEMO_DIR/tasks"

AUTO=false
[[ "$1" == "--auto" ]] && AUTO=true

# ── Colours ───────────────────────────────────────────────────────────────────
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; RED='\033[0;31m'

# ── Helpers ───────────────────────────────────────────────────────────────────
header() {
    echo ""
    printf "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
    printf "${CYAN}${BOLD}  %s${RESET}\n" "$1"
    printf "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

step() {
    echo ""
    printf "${BLUE}${BOLD}▶ Step %s${RESET}  %s\n" "$1" "$2"
    echo ""
}

ok()   { printf "  ${GREEN}✓${RESET}  %s\n" "$1"; }
info() { printf "  ${DIM}%s${RESET}\n" "$1"; }
cmd()  { printf "  ${YELLOW}\$${RESET}  ${BOLD}%s${RESET}\n" "$1"; }

pause() {
    if [ "$AUTO" = false ]; then
        printf "\n  ${DIM}Press Enter to continue...${RESET}"
        read -r
    else
        sleep 1
    fi
}

hr() { printf "  ${DIM}────────────────────────────────────────${RESET}\n"; }

# ── Pre-flight check ──────────────────────────────────────────────────────────
preflight() {
    local fail=false

    if ! command -v kiro-cli &>/dev/null; then
        printf "  ${RED}✗${RESET}  kiro-cli not found\n"
        echo "     Install: https://kiro.dev"
        fail=true
    else
        ok "kiro-cli: $(kiro-cli --version 2>/dev/null | head -1)"
    fi

    if ! kiro-cli whoami &>/dev/null; then
        printf "  ${RED}✗${RESET}  kiro-cli not authenticated\n"
        echo "     Run: kiro-cli login"
        fail=true
    else
        local email; email=$(kiro-cli whoami 2>/dev/null | grep -i email | awk '{print $2}')
        ok "authenticated as: ${email:-<unknown>}"
    fi

    # Source ktask if not already loaded
    if ! command -v ktask-new &>/dev/null; then
        source "$KTASK_DIR/ktask.sh" 2>/dev/null
    fi

    if ! command -v ktask-new &>/dev/null; then
        printf "  ${RED}✗${RESET}  ktask.sh not loaded\n"
        echo "     Run: source $KTASK_DIR/ktask.sh"
        fail=true
    else
        ok "ktask.sh loaded"
    fi

    [ "$fail" = true ] && echo "" && echo "  Fix the above and re-run." && exit 1
}

# ── Main ──────────────────────────────────────────────────────────────────────

clear
echo ""
printf "${MAGENTA}${BOLD}"
cat << 'BANNER'
  ██╗  ██╗████████╗ █████╗ ███████╗██╗  ██╗
  ██║ ██╔╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
  █████╔╝    ██║   ███████║███████╗█████╔╝
  ██╔═██╗    ██║   ██╔══██║╚════██║██╔═██╗
  ██║  ██╗   ██║   ██║  ██║███████║██║  ██╗
  ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
BANNER
printf "${RESET}"
printf "  ${DIM}Claude Code + kiro-cli autonomous dev pipeline${RESET}\n"
printf "  ${DIM}Demo: add structured logging to a Flask API${RESET}\n"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
header "0 / 5  Pre-flight checks"
preflight
pause

# ─────────────────────────────────────────────────────────────────────────────
header "1 / 5  The project we're working on"

step "1" "tiny-api — a minimal Flask REST API (no logging, no tests)"
echo ""
printf "  ${DIM}%s${RESET}\n" "$PROJECT_DIR/"
hr
cat "$PROJECT_DIR/app.py"
hr
echo ""
printf "  ${YELLOW}Problem:${RESET}  No request logging. When something breaks in prod,\n"
printf "            you have no idea which endpoint was called or what the payload was.\n"
echo ""
printf "  ${GREEN}Goal:${RESET}     Add structured JSON logging to every endpoint — autonomously.\n"

pause

# ─────────────────────────────────────────────────────────────────────────────
header "2 / 5  Plan: decompose the feature into task files"

step "2" "ktask-new — ask kiro to break the feature into atomic tasks"

rm -rf "$TASKS_DIR" && mkdir -p "$TASKS_DIR"

cmd "ktask-new \"add structured JSON request logging to every API endpoint in $PROJECT_DIR/app.py\" $TASKS_DIR"
echo ""

ktask-new "add structured JSON request logging to every API endpoint in $PROJECT_DIR/app.py. \
Log method, path, status code, and duration for every request. \
Use Python's built-in logging module with a JSON formatter. \
The project is at $PROJECT_DIR/app.py." "$TASKS_DIR"

echo ""
printf "  ${GREEN}Generated task files:${RESET}\n"
for f in "$TASKS_DIR"/task-*.md; do
    title=$(grep -m1 '^# Task:' "$f" | sed 's/^# Task: //')
    printf "  ${DIM}%-20s${RESET}  %s\n" "$(basename "$f")" "$title"
done

pause

# ─────────────────────────────────────────────────────────────────────────────
header "3 / 5  Inspect the task files"

step "3" "Each task file has a title, description, and checklist"

for f in "$TASKS_DIR"/task-*.md; do
    echo ""
    printf "  ${BOLD}$(basename "$f")${RESET}\n"
    hr
    cat "$f"
    hr
done

echo ""
printf "  ${DIM}These files are the contract between you and the AI workers.\n"
printf "  Edit any task before running — they're just markdown.${RESET}\n"

pause

# ─────────────────────────────────────────────────────────────────────────────
header "4 / 5  Execute: autonomous task loop"

step "4" "ktask-loop — execute all tasks, route by tier, rename to .done.md"

cmd "ktask-loop $TASKS_DIR"
echo ""

printf "  ${DIM}Each task is analysed for tier (T0/T1/T2/T3) and routed to the\n"
printf "  right kiro specialist. T3 tasks halt for human review.${RESET}\n"
echo ""
printf "  ${DIM}Tier routing:${RESET}\n"
printf "  ${DIM}  T0  search/explore  →  deepseek-3.2      (0.25x credits)${RESET}\n"
printf "  ${DIM}  T1  tests/docs      →  qwen3-coder-next   (0.05x credits)${RESET}\n"
printf "  ${DIM}  T2  implement/fix   →  claude-sonnet-4.6  (1.30x credits)${RESET}\n"
printf "  ${DIM}  T3  judgment/arch   →  YOU                (Claude Code)${RESET}\n"
echo ""

ktask-loop "$TASKS_DIR"

pause

# ─────────────────────────────────────────────────────────────────────────────
header "5 / 5  Results"

step "5a" "All tasks completed → renamed to .done.md"

echo ""
for f in "$TASKS_DIR"/task-*.done.md; do
    tier=$(grep -m1 '^Tier:' "$f" | awk '{print $2}')
    ts=$(grep -m1 '^Tier:' "$f" | grep -oP 'Completed: \K[^\s]+')
    title=$(grep -m1 '^# Task:' "$f" | sed 's/^# Task: //')
    printf "  ${GREEN}✓${RESET}  ${BOLD}%-30s${RESET}  [%s]  %s\n" "$(basename "$f")" "$tier" "$title"
done

echo ""
step "5b" "Inspect what kiro actually did (task-*.done.md contains full output)"

echo ""
printf "  ${DIM}The ## Result section in each .done.md shows exactly what ran:${RESET}\n"
echo ""

# Show the T2 result (most interesting)
T2_FILE=$(grep -l 'Tier: T2' "$TASKS_DIR"/*.done.md 2>/dev/null | head -1)
if [ -n "$T2_FILE" ]; then
    printf "  ${BOLD}%s  (T2 — implementation):${RESET}\n" "$(basename "$T2_FILE")"
    hr
    # Show just the Result section, strip ANSI, limit lines
    awk '/^## Result/{found=1} found{print}' "$T2_FILE" \
        | sed 's/\x1b\[[0-9;]*[mGKHF]//g' \
        | sed 's/\x1b\[[?][0-9]*[hl]//g' \
        | head -30
    hr
fi

echo ""
step "5c" "Budget used this session"

echo ""
kbudget

# ─────────────────────────────────────────────────────────────────────────────
echo ""
printf "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
printf "${MAGENTA}${BOLD}  Demo complete!${RESET}\n"
printf "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
echo ""
printf "  What just happened:\n"
printf "  ${GREEN}✓${RESET}  One command described the feature (ktask-new)\n"
printf "  ${GREEN}✓${RESET}  kiro planned it into atomic task files\n"
printf "  ${GREEN}✓${RESET}  ktask-loop routed each task to the cheapest capable model\n"
printf "  ${GREEN}✓${RESET}  All tasks executed autonomously, results written to .done.md\n"
printf "  ${GREEN}✓${RESET}  Claude Code context untouched — full capacity preserved\n"
echo ""
printf "  Next steps:\n"
printf "  ${CYAN}\$${RESET}  ktask-new \"your feature\" ./tasks/    # start your own pipeline\n"
printf "  ${CYAN}\$${RESET}  ktask-status ./tasks/                # check progress\n"
printf "  ${CYAN}\$${RESET}  kturbo-t0 \"t1\" \"t2\" \"t3\" \"t4\"       # 4 parallel research tasks\n"
printf "  ${CYAN}\$${RESET}  kroute \"describe your task\"          # ask the routing advisor\n"
echo ""
printf "  ${DIM}Full docs: $(realpath "$KTASK_DIR/README.md")${RESET}\n"
echo ""
