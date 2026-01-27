#!/bin/bash
# ---
# name: "Install Claude Skills"
# description: "Install custom Claude skills to your .claude configuration folder"
# type: config
# root: false
# order: 20
# tags: "llm, claude, skills, config"
# ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Claude Skills Installer${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if we have skills to install
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo -e "${RED}No skills folder found at: $SKILLS_SOURCE${NC}"
    exit 1
fi

# Count available skills
SKILL_COUNT=$(find "$SKILLS_SOURCE" -name "SKILL.md" | wc -l)
echo -e "${CYAN}Available skills to install: ${SKILL_COUNT}${NC}"
echo ""

# List available skills
echo -e "${YELLOW}Skills:${NC}"
for skill_file in "$SKILLS_SOURCE"/*/SKILL.md; do
    if [ -f "$skill_file" ]; then
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        # Extract description from SKILL.md
        desc=$(grep "^description:" "$skill_file" | head -1 | sed 's/description: *//' | cut -c1-60)
        echo -e "  ${GREEN}•${NC} $skill_name"
        echo -e "    $desc..."
    fi
done
echo ""

# Default .claude location
DEFAULT_CLAUDE_DIR="$HOME/.claude"

# Prompt for .claude location
echo -e "${YELLOW}Where is your .claude folder located?${NC}"
echo -e "  Default: ${CYAN}$DEFAULT_CLAUDE_DIR${NC}"
echo ""
read -p "Path to .claude folder (press Enter for default): " CLAUDE_DIR

# Use default if empty
if [ -z "$CLAUDE_DIR" ]; then
    CLAUDE_DIR="$DEFAULT_CLAUDE_DIR"
fi

# Expand ~ if used
CLAUDE_DIR="${CLAUDE_DIR/#\~/$HOME}"

# Verify the directory exists or create it
if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}Directory does not exist: $CLAUDE_DIR${NC}"
    read -p "Create it? (y/n): " create_dir
    if [ "$create_dir" = "y" ] || [ "$create_dir" = "Y" ]; then
        mkdir -p "$CLAUDE_DIR"
        echo -e "${GREEN}Created: $CLAUDE_DIR${NC}"
    else
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
fi

# Create skills directory in .claude if it doesn't exist
SKILLS_DEST="$CLAUDE_DIR/skills"
if [ ! -d "$SKILLS_DEST" ]; then
    mkdir -p "$SKILLS_DEST"
    echo -e "${GREEN}Created skills folder: $SKILLS_DEST${NC}"
fi

echo ""
echo -e "${BLUE}Installing skills...${NC}"
echo ""

# Copy each skill
installed=0
for skill_dir in "$SKILLS_SOURCE"/*/; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")
        dest_dir="$SKILLS_DEST/$skill_name"
        
        if [ -d "$dest_dir" ]; then
            echo -e "${YELLOW}Updating:${NC} $skill_name"
            rm -rf "$dest_dir"
        else
            echo -e "${GREEN}Installing:${NC} $skill_name"
        fi
        
        cp -r "$skill_dir" "$dest_dir"
        ((installed++))
    fi
done

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "Installed ${CYAN}$installed${NC} skill(s) to: ${CYAN}$SKILLS_DEST${NC}"
echo ""
echo -e "${YELLOW}Skills will be available in your next Claude session.${NC}"
echo ""
