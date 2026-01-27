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
SKILLS_SOURCE="$SCRIPT_DIR/.skills"

# Check if we have skills to install
if [ ! -d "$SKILLS_SOURCE" ]; then
    echo -e "${RED}No skills folder found at: $SKILLS_SOURCE${NC}"
    exit 1
fi

# Default .claude location
DEFAULT_CLAUDE_DIR="$HOME/.claude"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Claude Skills Installer${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

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

# Create directory if needed
if [ ! -d "$CLAUDE_DIR" ]; then
    mkdir -p "$CLAUDE_DIR"
    echo -e "${GREEN}Created: $CLAUDE_DIR${NC}"
fi

SKILLS_DEST="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DEST"

# Build checkbox list
# Format: "skill_name" "description" ON/OFF
CHECKLIST_ITEMS=()

for skill_file in "$SKILLS_SOURCE"/*/SKILL.md; do
    if [ -f "$skill_file" ]; then
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        
        # Extract description (first 50 chars)
        desc=$(grep "^description:" "$skill_file" | head -1 | sed 's/description: *//' | sed 's/"//g' | cut -c1-50)
        if [ -z "$desc" ]; then
            desc="No description"
        fi
        
        # Check if already installed
        if [ -d "$SKILLS_DEST/$skill_name" ]; then
            status="ON"
            desc="[INSTALLED] $desc"
        else
            status="OFF"
        fi
        
        CHECKLIST_ITEMS+=("$skill_name" "$desc" "$status")
    fi
done

# Check if we have any skills
if [ ${#CHECKLIST_ITEMS[@]} -eq 0 ]; then
    echo -e "${RED}No skills found in $SKILLS_SOURCE${NC}"
    exit 1
fi

# Calculate dimensions
SKILL_COUNT=$((${#CHECKLIST_ITEMS[@]} / 3))
HEIGHT=$((SKILL_COUNT + 10))
if [ $HEIGHT -gt 20 ]; then HEIGHT=20; fi

# Show checklist using whiptail
SELECTED=$(whiptail --title "Claude Skills Installer" \
    --checklist "Select skills to install:\n(Already installed skills are pre-selected)" \
    $HEIGHT 78 $SKILL_COUNT \
    "${CHECKLIST_ITEMS[@]}" \
    3>&1 1>&2 2>&3)

# Check if user cancelled
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Cancelled.${NC}"
    exit 0
fi

# Parse selected items (whiptail returns "item1" "item2" format)
SELECTED=$(echo "$SELECTED" | tr -d '"')

if [ -z "$SELECTED" ]; then
    echo -e "${YELLOW}No skills selected.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Installing selected skills...${NC}"
echo ""

installed=0
for skill_name in $SELECTED; do
    src_dir="$SKILLS_SOURCE/$skill_name"
    dest_dir="$SKILLS_DEST/$skill_name"
    
    if [ -d "$src_dir" ]; then
        if [ -d "$dest_dir" ]; then
            echo -e "${YELLOW}Updating:${NC} $skill_name"
            rm -rf "$dest_dir"
        else
            echo -e "${GREEN}Installing:${NC} $skill_name"
        fi
        
        cp -r "$src_dir" "$dest_dir"
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
