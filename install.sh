#!/usr/bin/env bash
# install.sh — ktask system installer
set -e

KTASK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTS_DST="${HOME}/.kiro/agents"
SHELL_RC="${HOME}/.bash_aliases"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}  !${NC} %s\n" "$1"; }
err()  { printf "${RED}  ✗${NC} %s\n" "$1"; }

echo ""
echo "  ktask installer"
echo "  ────────────────────────────────────────"

# Check dependencies
if ! command -v kiro-cli &>/dev/null; then
    err "kiro-cli not found. Install from https://kiro.dev"
    exit 1
fi
ok "kiro-cli found: $(kiro-cli --version 2>/dev/null | head -1)"

if ! command -v bc &>/dev/null; then
    warn "bc not found — credit tracking disabled (apt install bc)"
fi

# Check kiro auth
if kiro-cli whoami &>/dev/null; then
    ok "kiro-cli authenticated"
else
    warn "kiro-cli not authenticated — run: kiro-cli login"
fi

# Enable subagent
kiro-cli settings chat.enableSubagent true &>/dev/null && ok "kiro subagent enabled"

# Install agent configs
mkdir -p "$AGENTS_DST"
cp -f "$KTASK_DIR/agents/"*.json "$AGENTS_DST/"
ok "installed $(ls "$KTASK_DIR/agents/"*.json | wc -l) agents to $AGENTS_DST"

# Wire ktask.sh into shell RC
SOURCE_LINE="source \"$KTASK_DIR/ktask.sh\""
if grep -qF "$SOURCE_LINE" "$SHELL_RC" 2>/dev/null; then
    ok "ktask.sh already sourced in $SHELL_RC"
else
    echo "" >> "$SHELL_RC"
    echo "# ktask — Claude Code + kiro-cli workload system" >> "$SHELL_RC"
    echo "$SOURCE_LINE" >> "$SHELL_RC"
    ok "added source line to $SHELL_RC"
fi

echo ""
echo "  Installation complete."
echo "  Run:  source $SHELL_RC"
echo "  Then: ktask-new \"your feature\" ./tasks/"
echo ""
