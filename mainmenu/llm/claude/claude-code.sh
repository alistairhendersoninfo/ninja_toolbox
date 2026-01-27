#!/bin/bash
# ---
# name: "Claude Code CLI"
# description: "Install Anthropic's official Claude Code CLI for AI-assisted development"
# type: install
# root: false
# order: 10
# check_path: "/home/alistair/.local/bin/claude:~/.local/bin/claude"
# tags: "llm, claude, anthropic, ai, cli"
# ---

ACTION="${1:-install}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$ACTION" = "install" ]; then
    echo -e "${BLUE}Installing Claude Code CLI...${NC}"
    
    # Check if already installed
    if command -v claude &>/dev/null; then
        echo -e "${GREEN}Claude Code already installed: $(claude --version 2>/dev/null)${NC}"
        exit 0
    fi
    
    # Download and run official installer
    curl -fsSL https://claude.ai/install.sh | bash
    
    # Update PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v claude &>/dev/null; then
        echo -e "${GREEN}Claude Code installed successfully!${NC}"
        echo ""
        echo -e "${BLUE}Quick Start:${NC}"
        echo "  claude           # Start interactive mode"
        echo "  claude \"query\"   # One-shot query"
        echo "  claude --help    # Show all options"
    else
        echo -e "${YELLOW}Claude installed. You may need to restart your terminal or run:${NC}"
        echo 'export PATH="$HOME/.local/bin:$PATH"'
    fi
else
    echo -e "${BLUE}Uninstalling Claude Code CLI...${NC}"
    rm -f "$HOME/.local/bin/claude"
    rm -rf "$HOME/.claude"
    echo -e "${GREEN}Claude Code uninstalled.${NC}"
fi
