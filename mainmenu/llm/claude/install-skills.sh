#!/bin/bash
# ---
# name: "Install Claude Skills"
# description: "Install custom Claude skills to your .claude configuration folder"
# type: config
# root: false
# order: 20
# tags: "llm, claude, skills, config"
# ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
SKILLS_SOURCE="$SCRIPT_DIR/.skills"
CONFIG_FILE="$MENU_ROOT/.configs/menusystem/settings.conf"

# Read backend preference from config
get_backend() {
    if [ -f "$CONFIG_FILE" ]; then
        backend=$(grep "^backend=" "$CONFIG_FILE" | cut -d'=' -f2)
        if [ "$backend" = "gum" ] && command -v gum &>/dev/null; then
            echo "gum"
            return
        fi
    fi
    # Fallback to whiptail
    echo "whiptail"
}

BACKEND=$(get_backend)

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

if [ -z "$CLAUDE_DIR" ]; then
    CLAUDE_DIR="$DEFAULT_CLAUDE_DIR"
fi
CLAUDE_DIR="${CLAUDE_DIR/#\~/$HOME}"

if [ ! -d "$CLAUDE_DIR" ]; then
    mkdir -p "$CLAUDE_DIR"
    echo -e "${GREEN}Created: $CLAUDE_DIR${NC}"
fi

SKILLS_DEST="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DEST"

# Build skill data
declare -A SKILL_DESC
declare -A SKILL_INSTALLED
SKILL_NAMES=()

for skill_file in "$SKILLS_SOURCE"/*/SKILL.md; do
    if [ -f "$skill_file" ]; then
        skill_dir=$(dirname "$skill_file")
        skill_name=$(basename "$skill_dir")
        SKILL_NAMES+=("$skill_name")
        
        # Get full description
        full_desc=$(grep "^description:" "$skill_file" | head -1 | sed 's/description: *//' | sed 's/"//g')
        SKILL_DESC[$skill_name]="$full_desc"
        
        # Check if installed
        if [ -d "$SKILLS_DEST/$skill_name" ]; then
            SKILL_INSTALLED[$skill_name]="yes"
        else
            SKILL_INSTALLED[$skill_name]="no"
        fi
    fi
done

if [ ${#SKILL_NAMES[@]} -eq 0 ]; then
    echo -e "${RED}No skills found${NC}"
    exit 1
fi

# ============= GUM BACKEND =============
if [ "$BACKEND" = "gum" ]; then
    
    # Show info header
    gum style --border double --border-foreground 39 --padding "1 2" --margin "1" \
        "Available Skills" "Use arrow keys, space to select, enter to confirm"
    
    # Build info display
    echo ""
    for skill_name in "${SKILL_NAMES[@]}"; do
        if [ "${SKILL_INSTALLED[$skill_name]}" = "yes" ]; then
            gum style --foreground 40 "✓ $skill_name (installed)"
        else
            gum style --foreground 250 "○ $skill_name"
        fi
        gum style --foreground 245 --italic "  ${SKILL_DESC[$skill_name]:0:60}..."
        echo ""
    done
    
    # Build choice list
    CHOICES=()
    for skill_name in "${SKILL_NAMES[@]}"; do
        if [ "${SKILL_INSTALLED[$skill_name]}" = "yes" ]; then
            CHOICES+=("$skill_name [installed]")
        else
            CHOICES+=("$skill_name")
        fi
    done
    
    # Select skills
    SELECTED=$(gum choose --no-limit --header "Select skills to install:" "${CHOICES[@]}")
    
    if [ -z "$SELECTED" ]; then
        echo -e "${YELLOW}No skills selected.${NC}"
        exit 0
    fi

# ============= WHIPTAIL BACKEND =============
else
    # Build info text for preview
    SKILL_INFO=""
    CHECKLIST_ITEMS=()
    
    for skill_name in "${SKILL_NAMES[@]}"; do
        if [ "${SKILL_INSTALLED[$skill_name]}" = "yes" ]; then
            status="ON"
            tag="[*]"
        else
            status="OFF"
            tag=""
        fi
        
        SKILL_INFO+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        SKILL_INFO+="  $skill_name $tag\n"
        SKILL_INFO+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        SKILL_INFO+="${SKILL_DESC[$skill_name]}\n\n"
        
        short_desc="${SKILL_DESC[$skill_name]:0:25}"
        [ -n "$tag" ] && short_desc="$tag $short_desc"
        CHECKLIST_ITEMS+=("$skill_name" "$short_desc" "$status")
    done
    
    # Show info preview
    echo -e "$SKILL_INFO" | whiptail --title "Available Skills" \
        --scrolltext --msgbox "$(echo -e "$SKILL_INFO")" 18 60
    
    # Show checklist
    SKILL_COUNT=${#SKILL_NAMES[@]}
    HEIGHT=$((SKILL_COUNT + 8))
    [ $HEIGHT -gt 18 ] && HEIGHT=18
    
    SELECTED=$(whiptail --title "Install Skills" \
        --checklist "[*] = installed. Space to toggle:" \
        $HEIGHT 50 $SKILL_COUNT \
        "${CHECKLIST_ITEMS[@]}" \
        3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$SELECTED" ]; then
        echo -e "${YELLOW}Cancelled.${NC}"
        exit 0
    fi
    
    SELECTED=$(echo "$SELECTED" | tr -d '"')
fi

# ============= INSTALL SELECTED =============
echo ""
echo -e "${BLUE}Installing selected skills...${NC}"
echo ""

installed=0
for skill_name in $SELECTED; do
    # Clean up skill name (remove [installed] suffix if present)
    skill_name=$(echo "$skill_name" | sed 's/ \[installed\]//')
    
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
echo -e "Backend used: ${CYAN}$BACKEND${NC}"
echo ""
