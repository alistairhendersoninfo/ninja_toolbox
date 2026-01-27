#!/bin/bash
# ---
# name: "Claude Code CLI"
# description: "Install Anthropic's official Claude Code CLI for AI-assisted development"
# type: install
# root: false
# order: 10
# check_command: "claude --version"
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
    
    # Check for npm
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm is required. Please install Node.js first.${NC}"
        exit 1
    fi
    
    # Install Claude Code globally
    npm install -g @anthropic-ai/claude-code
    
    if command -v claude &> /dev/null; then
        echo -e "${GREEN}Claude Code installed successfully!${NC}"
        echo ""
        echo -e "${BLUE}Quick Start:${NC}"
        echo "  claude           # Start interactive mode"
        echo "  claude \"query\"   # One-shot query"
        echo "  claude --help    # Show all options"
        echo ""
        echo -e "${YELLOW}Run 'claude' to authenticate with your Anthropic API key.${NC}"
    else
        echo -e "${RED}Installation failed.${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}Uninstalling Claude Code CLI...${NC}"
    npm uninstall -g @anthropic-ai/claude-code
    echo -e "${GREEN}Claude Code uninstalled.${NC}"
fi
