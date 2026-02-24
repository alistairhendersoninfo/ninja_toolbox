#!/bin/bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="docker"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# -E makes ERR trap fire inside functions, not just at top level
trap 'log_error "FAILED at line $LINENO: $BASH_COMMAND (exit $?)"; log_error "Log: $LOG_FILE"; exit 1' ERR

DATA_ROOT="/opt/app/docker"

# Resolve distro for Docker repo once (Kali uses Debian's repo)
_resolve_docker_distro() {
    # shellcheck source=/dev/null
    . /etc/os-release
    DOCKER_DISTRO="$ID"
    DOCKER_CODENAME="${VERSION_CODENAME:-}"
    if [[ "$DOCKER_DISTRO" == "kali" ]]; then
        DOCKER_DISTRO="debian"
        DOCKER_CODENAME="bookworm"
    fi
}

install() {
    log_info "Installing Docker CE"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    _resolve_docker_distro

    # Step 0: Clear any stuck apt/dpkg locks
    wait_for_apt

    # Step 1: Remove old/conflicting packages
    log_step "Removing old Docker packages if present..."
    apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc 2>/dev/null || true

    # Step 2: Install prerequisites
    log_step "Installing prerequisites..."
    pkg_update
    pkg_install ca-certificates curl gnupg

    # Step 3: Add Docker GPG key
    log_step "Adding Docker GPG key from download.docker.com/linux/${DOCKER_DISTRO}..."
    install -m 0755 -d /etc/apt/keyrings
    rm -f /etc/apt/keyrings/docker.gpg

    local gpg_url="https://download.docker.com/linux/${DOCKER_DISTRO}/gpg"
    log_info "Downloading: $gpg_url"
    curl -fsSL "$gpg_url" -o /tmp/docker-gpg-key
    log_info "Downloaded $(wc -c < /tmp/docker-gpg-key) bytes"

    gpg --dearmor --batch --yes -o /etc/apt/keyrings/docker.gpg < /tmp/docker-gpg-key
    rm -f /tmp/docker-gpg-key
    chmod a+r /etc/apt/keyrings/docker.gpg
    log_info "GPG key installed to /etc/apt/keyrings/docker.gpg"

    # Step 4: Add Docker apt repository
    log_step "Adding Docker apt repository (${DOCKER_DISTRO} ${DOCKER_CODENAME})..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_DISTRO} ${DOCKER_CODENAME} stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    log_info "Repo written to /etc/apt/sources.list.d/docker.list"
    apt-get update

    # Step 5: Install Docker CE and plugins
    log_step "Installing Docker CE, CLI, containerd, Buildx, and Compose..."
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # Step 6: Create docker group
    log_step "Creating docker group..."
    groupadd docker || true

    # Step 7: Add current user to docker group
    REAL_USER="${SUDO_USER:-$USER}"
    log_step "Adding user '${REAL_USER}' to docker group..."
    usermod -aG docker "$REAL_USER"

    # Step 8: Configure data directory
    log_step "Configuring Docker data root at ${DATA_ROOT}..."
    mkdir -p "$DATA_ROOT"

    cat > /etc/docker/daemon.json <<JSON
{
    "data-root": "${DATA_ROOT}",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
JSON

    # Step 9: Enable and start Docker
    log_step "Enabling and starting Docker service..."
    systemctl enable --now docker

    # Step 10: Verify
    log_step "Verifying installation..."
    docker --version
    docker compose version

    echo ""
    log_success "Docker CE installed successfully."
    log_info "Data directory: ${DATA_ROOT}"
    log_info ""
    log_info "IMPORTANT: Log out and back in for docker group membership to take effect."
    log_info "Then test with: docker run hello-world"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Docker CE"
    require_root

    log_step "Stopping Docker service..."
    systemctl stop docker 2>/dev/null || true
    systemctl stop docker.socket 2>/dev/null || true
    systemctl disable docker 2>/dev/null || true

    log_step "Removing Docker packages..."
    apt-get purge -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true

    log_step "Removing Docker apt repository and GPG key..."
    rm -f /etc/apt/sources.list.d/docker.list
    rm -f /etc/apt/keyrings/docker.gpg

    echo ""
    log_info "Docker data directory at ${DATA_ROOT} has NOT been removed."
    log_info "To remove all Docker data: sudo rm -rf ${DATA_ROOT}"
    log_info "To remove config: sudo rm -f /etc/docker/daemon.json"

    echo ""
    log_success "Docker CE uninstalled."
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
