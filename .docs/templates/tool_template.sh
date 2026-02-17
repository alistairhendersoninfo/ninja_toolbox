#!/bin/bash
# Metadata lives in the companion .meta.yaml file (NOT inline).
# Copy tool_template.meta.yaml alongside this script and fill in the fields.
# See: .docs/technical_manuals/os-modular-architecture.md for full reference.
#
# type: tool — requires a binary to be installed before this script can run.
# The menu checks the 'binary' field in .meta.yaml and blocks execution if not found.
#
# Folder convention:
#   mainmenu/education/{category}/{tool}/{technique}/this-script.sh
#   e.g. mainmenu/education/network/nmap/scanning/quick-scan.sh

#######################################
# TOOL SCRIPT TEMPLATE
# Use this for scripts that USE an installed tool
# (education, demonstration, automation)
#######################################

set -euo pipefail

# Determine script location and menu root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source cross-platform library (provides logging, etc.)
source "$MENU_ROOT/.lib/platform.sh"

# Defence in depth — verify binary is available
# (The menu already checks this, but this catches direct CLI execution)
REQUIRED_BINARY="required-command"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

# If this script requires root (root: true in YAML header), uncomment:
# require_tool_root
# NOTE: Use require_tool_root (not require_root) for tool scripts.
# require_root is for package management (forbids root on macOS for Homebrew).
# require_tool_root requires root on BOTH platforms (for raw sockets, etc.).

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Main function
run() {
    log_info "Running: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    #######################################
    # YOUR TOOL SCRIPT LOGIC HERE
    #######################################

    log_step "Step 1: ..."
    # e.g., nmap -sn 192.168.1.0/24

    log_step "Step 2: ..."
    # Your code here

    #######################################
    # END LOGIC
    #######################################

    echo ""
    log_success "Complete: $SCRIPT_NAME"
}

# Tool scripts only support "run" (called as "install" by menu)
run
