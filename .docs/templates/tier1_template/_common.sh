#!/bin/bash
# Shared functions for <tool-name> — sourced by all OS scripts.
# Do NOT add YAML headers here (metadata lives in meta.yaml).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

# Source platform detection (provides log_info, log_error, log_success, pkg_install, etc.)
source "$MENU_ROOT/.lib/platform.sh"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
SCRIPT_NAME="$(basename "$SCRIPT_DIR")"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

#######################################
# Add shared helper functions below
#######################################
