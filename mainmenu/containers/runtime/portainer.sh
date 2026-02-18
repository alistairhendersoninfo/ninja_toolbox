#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="portainer"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

CONTAINER_NAME="portainer"
VOLUME_NAME="portainer_data"
IMAGE="portainer/portainer-ce:lts"

install() {
    log_info "Installing Portainer CE (Docker management UI)"
    log_info "Log file: $LOG_FILE"
    echo ""

    # Check Docker is available
    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed. Install Docker first from the menu."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        log_error "Docker daemon is not running or current user lacks permissions."
        log_error "Ensure Docker is running and your user is in the 'docker' group."
        exit 1
    fi

    # Remove existing container if present
    if docker ps -a --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "${CONTAINER_NAME}"; then
        log_step "Removing existing Portainer container..."
        docker stop "${CONTAINER_NAME}" 2>/dev/null || true
        docker rm "${CONTAINER_NAME}" 2>/dev/null || true
    fi

    # Step 1: Create volume
    log_step "Creating Docker volume '${VOLUME_NAME}'..."
    docker volume create "${VOLUME_NAME}"

    # Step 2: Pull and run Portainer
    log_step "Pulling and starting Portainer CE..."
    docker run -d \
        -p 9443:9443 \
        --name "${CONTAINER_NAME}" \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "${VOLUME_NAME}:/data" \
        "${IMAGE}"

    # Step 3: Create systemd service (optional, for host-level management)
    log_step "Creating systemd service unit..."
    if [[ -w /etc/systemd/system/ ]]; then
        cat > /etc/systemd/system/portainer.service <<SERVICE
[Unit]
Description=Portainer CE Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start ${CONTAINER_NAME}
ExecStop=/usr/bin/docker stop ${CONTAINER_NAME}

[Install]
WantedBy=multi-user.target
SERVICE
        systemctl daemon-reload
        systemctl enable portainer.service 2>/dev/null || true
        log_info "Systemd service created and enabled."
    else
        log_info "Skipping systemd service (no write access to /etc/systemd/system/)."
        log_info "Portainer will auto-restart via Docker's --restart=always policy."
    fi

    # Step 4: Verify
    log_step "Verifying Portainer is running..."
    sleep 3
    if docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Status}}' | grep -q "Up"; then
        log_success "Portainer CE is running."
    else
        log_error "Portainer container may not have started correctly."
        docker logs "${CONTAINER_NAME}" --tail 20
    fi

    echo ""
    log_success "Portainer CE installed successfully."
    log_info "Access the web UI at: https://localhost:9443"
    log_info "On first visit, create your admin user."
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Portainer CE"

    if ! command -v docker &>/dev/null; then
        log_error "Docker is not installed."
        exit 1
    fi

    log_step "Stopping and removing Portainer container..."
    docker stop "${CONTAINER_NAME}" 2>/dev/null || true
    docker rm "${CONTAINER_NAME}" 2>/dev/null || true

    log_step "Removing Portainer volume..."
    docker volume rm "${VOLUME_NAME}" 2>/dev/null || true

    # Remove systemd service if it exists
    if [[ -f /etc/systemd/system/portainer.service ]]; then
        log_step "Removing systemd service..."
        systemctl disable portainer.service 2>/dev/null || true
        rm -f /etc/systemd/system/portainer.service
        systemctl daemon-reload 2>/dev/null || true
    fi

    echo ""
    log_success "Portainer CE uninstalled."
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
