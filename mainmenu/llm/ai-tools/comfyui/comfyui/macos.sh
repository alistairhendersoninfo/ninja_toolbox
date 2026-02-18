#!/bin/bash
# macOS implementation — do NOT add YAML headers here (use meta.yaml)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

exec > >(tee -a "$LOG_FILE") 2>&1

# ── Install ──────────────────────────────────────────────────────────────────
install() {
    log_info "Installing ComfyUI on macOS..."
    log_info "Log file: $LOG_FILE"

    # Idempotency — skip if already installed
    if [[ -f "$COMFYUI_DIR/main.py" ]]; then
        log_info "ComfyUI already installed at $COMFYUI_DIR"
        mark_installed true
        return 0
    fi

    # Python 3.12 via Homebrew
    if ! command -v "python${PYTHON_VERSION}" &>/dev/null; then
        log_step "Installing Python ${PYTHON_VERSION} via Homebrew..."
        brew install "python@${PYTHON_VERSION}"
    else
        log_info "Python ${PYTHON_VERSION} already installed"
    fi

    # Create parent directory
    log_step "Creating install directory..."
    sudo mkdir -p /opt/apps/LLM
    sudo chown "$USER" /opt/apps/LLM

    # Clone ComfyUI
    log_step "Cloning ComfyUI repository..."
    git clone "$COMFYUI_REPO" "$COMFYUI_DIR"

    # Create virtual environment
    log_step "Creating Python virtual environment..."
    "python${PYTHON_VERSION}" -m venv "$COMFYUI_DIR/venv"

    # Activate venv and install dependencies
    source "$COMFYUI_DIR/venv/bin/activate"

    log_step "Upgrading pip..."
    pip install --upgrade pip

    log_step "Installing PyTorch (MPS/Metal support)..."
    pip install torch torchvision torchaudio

    log_step "Installing ComfyUI requirements..."
    pip install -r "$COMFYUI_DIR/requirements.txt"

    # Install ComfyUI-Manager
    log_step "Installing ComfyUI-Manager..."
    git clone "$COMFYUI_MANAGER_REPO" "$COMFYUI_DIR/custom_nodes/ComfyUI-Manager"
    if [[ -f "$COMFYUI_DIR/custom_nodes/ComfyUI-Manager/requirements.txt" ]]; then
        pip install -r "$COMFYUI_DIR/custom_nodes/ComfyUI-Manager/requirements.txt"
    fi

    # Verify installation
    log_step "Verifying installation..."
    cd "$COMFYUI_DIR"
    python main.py --quick-test-for-ci

    deactivate

    echo ""
    log_success "ComfyUI installed successfully!"
    echo ""
    echo "  Location: $COMFYUI_DIR"
    echo "  To run:   source $COMFYUI_DIR/venv/bin/activate && python $COMFYUI_DIR/main.py"
    echo "  Web UI:   http://127.0.0.1:8188"
    echo ""

    mark_installed true
}

# ── Uninstall ────────────────────────────────────────────────────────────────
uninstall() {
    log_info "Removing ComfyUI..."

    if [[ ! -d "$COMFYUI_DIR" ]]; then
        log_info "ComfyUI not found at $COMFYUI_DIR — nothing to remove"
        mark_installed false
        return 0
    fi

    echo ""
    read -rp "Remove $COMFYUI_DIR and all models/data? [y/N] " confirm
    if [[ "$confirm" != [yY] ]]; then
        log_info "Uninstall cancelled"
        return 0
    fi

    rm -rf "$COMFYUI_DIR"
    log_success "ComfyUI removed"
    mark_installed false
}

ACTION="${1:-install}"

case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
