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

# Build skill info text for preview
SKILL_INFO=""
CHECKLIST_ITEMS=()

for skill_file in "$SKILLS_SOURCE"/*/SKILL.md; do
    if [ -f "$skill_file" ]; then
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")

        # Get full description for info display
        full_desc=$(grep "^description:" "$skill_file" | head -1 | sed 's/description: *//' | sed 's/"//g')

        # Check if already installed
        if [ -d "$SKILLS_DEST/$skill_name" ]; then
            status="ON"
            installed_tag="[INSTALLED]"
        else
            status="OFF"
            installed_tag=""
        fi

        # Build info text
        SKILL_INFO+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        SKILL_INFO+="  $skill_name $installed_tag\n"
        SKILL_INFO+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        SKILL_INFO+="$full_desc\n\n"

        # Short desc for checklist
        short_desc=$(echo "$full_desc" | cut -c1-25)
        if [ -n "$installed_tag" ]; then
            short_desc="[*] $short_desc"
        fi

        CHECKLIST_ITEMS+=("$skill_name" "$short_desc" "$status")
    fi
done

# Check if we have any skills
if [ ${#CHECKLIST_ITEMS[@]} -eq 0 ]; then
    echo -e "${RED}No skills found in $SKILLS_SOURCE${NC}"
    exit 1
fi

# Show skill info first (scrollable)
echo -e "$SKILL_INFO" | whiptail --title "Available Skills" \
    --scrolltext --msgbox "$(echo -e "$SKILL_INFO")" 20 70

# Calculate dimensions for checklist
SKILL_COUNT=$((${#CHECKLIST_ITEMS[@]} / 3))
HEIGHT=$((SKILL_COUNT + 8))
if [ $HEIGHT -gt 18 ]; then HEIGHT=18; fi

# Show checklist using whiptail
SELECTED=$(whiptail --title "Install Skills" \
    --checklist "[*] = installed. Space to toggle:" \
    $HEIGHT 55 $SKILL_COUNT \
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
