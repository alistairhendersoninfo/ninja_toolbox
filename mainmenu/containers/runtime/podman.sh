#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="podman"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

STORAGE_ROOT="/opt/app/podman"
STORAGE_CONF="/etc/containers/storage.conf"

install() {
    log_info "Installing Podman (rootless container engine)"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    # Step 1: Install podman
    log_step "Installing podman..."
    pkg_update
    pkg_install podman

    # Step 2: Install rootless dependencies
    log_step "Installing rootless prerequisites (slirp4netns, fuse-overlayfs)..."
    pkg_install slirp4netns fuse-overlayfs uidmap

    # Step 3: Configure storage
    log_step "Configuring container storage at ${STORAGE_ROOT}..."
    mkdir -p "$STORAGE_ROOT"
    mkdir -p "$(dirname "$STORAGE_CONF")"

    # Back up existing config if present
    if [[ -f "$STORAGE_CONF" ]]; then
        cp "$STORAGE_CONF" "${STORAGE_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
    fi

    cat > "$STORAGE_CONF" <<CONF
[storage]
driver = "overlay"
graphroot = "${STORAGE_ROOT}"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
CONF

    # Step 4: Enable podman socket for the invoking user
    REAL_USER="${SUDO_USER:-$USER}"
    log_step "Enabling podman socket for user '${REAL_USER}'..."
    if command -v loginctl &>/dev/null; then
        loginctl enable-linger "$REAL_USER" 2>/dev/null || true
    fi
    # The user socket must be enabled by the user themselves
    log_info "To enable the podman user socket, run as ${REAL_USER}:"
    log_info "  systemctl --user enable --now podman.socket"

    # Step 5: Verify
    log_step "Verifying installation..."
    podman --version
    podman info --format '{{.Host.OCIRuntime.Name}}' 2>/dev/null || true

    echo ""
    log_success "Podman installed successfully."
    log_info "Storage root: ${STORAGE_ROOT}"
    log_info ""
    log_info "Test with: podman run --rm docker.io/library/hello-world"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Podman"
    require_root

    log_step "Removing podman packages..."
    pkg_remove podman
    apt-get autoremove -y 2>/dev/null || true

    echo ""
    log_info "Podman storage at ${STORAGE_ROOT} has NOT been removed."
    log_info "To remove all data: sudo rm -rf ${STORAGE_ROOT}"
    log_info "To remove config: sudo rm -f ${STORAGE_CONF}"

    echo ""
    log_success "Podman uninstalled."
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
