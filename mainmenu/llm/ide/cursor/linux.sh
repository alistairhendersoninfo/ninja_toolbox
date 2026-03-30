#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Cursor IDE..."
    log_info "Log file: $LOG_FILE"

    # Resolve the real user's home (not root's when run via sudo)
    local user_home="${SUDO_USER:+$(eval echo "~$SUDO_USER")}"
    user_home="${user_home:-$HOME}"

    # Check if already installed
    if command -v cursor &>/dev/null \
        || [[ -f /usr/bin/cursor ]] || [[ -f /opt/Cursor/cursor ]] \
        || [[ -f "$user_home/.local/bin/agent" ]]; then
        log_info "Cursor IDE already installed"
        mark_installed true
        return 0
    fi

    # The Cursor installer targets ~/.local/bin — run as the real user, not root
    log_step "Downloading and running Cursor installer..."
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$SUDO_USER" bash -c 'curl -fsS https://cursor.com/install | bash'
    else
        curl -fsS https://cursor.com/install | bash
    fi

    if command -v cursor &>/dev/null \
        || [[ -f /usr/bin/cursor ]] || [[ -f /opt/Cursor/cursor ]] \
        || [[ -f "$user_home/.local/bin/agent" ]]; then
        log_success "Cursor IDE installed successfully!"
        echo ""
        if command -v cursor &>/dev/null; then
            echo "Run 'cursor' to launch Cursor IDE"
        else
            echo "Run 'agent' to launch Cursor Agent"
            echo "You may need to add ~/.local/bin to your PATH first"
        fi
        echo ""
        mark_installed true
    else
        log_error "Cursor installation may have failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Cursor IDE..."
    require_root

    apt-get remove -y cursor 2>/dev/null || dpkg -r cursor 2>/dev/null || true
    rm -rf ~/.config/Cursor
    rm -rf ~/.cursor

    log_success "Cursor IDE removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
