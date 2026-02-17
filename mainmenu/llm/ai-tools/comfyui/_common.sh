#!/bin/bash
# Shared functions for ComfyUI installer — sourced by all OS scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="comfyui"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"

# ── Shared config ─────────────────────────────────────────────────────────────
COMFYUI_DIR="/opt/apps/LLM/ComfyUI"
COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI.git"
COMFYUI_MANAGER_REPO="https://github.com/ltdrdata/ComfyUI-Manager.git"
PYTHON_VERSION="3.12"
