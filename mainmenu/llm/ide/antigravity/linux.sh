#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing Google Antigravity IDE..."
    log_info "Log file: $LOG_FILE"
    require_root

    # Check if already installed
    if command -v antigravity &>/dev/null; then
        log_info "Antigravity already installed"
        mark_installed true
        return 0
    fi

    log_step "Adding Google Antigravity repository..."

    # Import GPG key
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor -o /usr/share/keyrings/google-antigravity.gpg

    # Add repository (DEB822 format)
    cat > /etc/apt/sources.list.d/google-antigravity.sources << 'EOF'
Types: deb
URIs: https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/
Suites: antigravity-debian
Components: main
Signed-By: /usr/share/keyrings/google-antigravity.gpg
EOF

    log_step "Updating package list..."
    apt-get update -qq

    log_step "Installing antigravity..."
    apt-get install -y antigravity

    if command -v antigravity &>/dev/null; then
        log_success "Google Antigravity IDE installed successfully!"
        echo ""
        echo "Run 'antigravity' to launch"
        echo "Or 'antigravity /path/to/project' to open a project"
        echo ""
        mark_installed true
    else
        log_error "Antigravity installation failed"
        exit 1
    fi
}

uninstall() {
    log_info "Removing Google Antigravity IDE..."
    require_root

    apt-get remove -y antigravity || true
    rm -f /etc/apt/sources.list.d/google-antigravity.sources
    rm -f /usr/share/keyrings/google-antigravity.gpg
    apt-get update -qq
    rm -rf ~/.config/antigravity
    rm -rf ~/.antigravity

    log_success "Google Antigravity IDE removed"
    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
