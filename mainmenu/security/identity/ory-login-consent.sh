#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-login-consent"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory/login-consent"
SECRETS_FILE="/opt/app/docker/ory/login-consent/.env"

install() {
    log_info "Installing Ory Login & Consent App"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}"

    log_step "2. Configuring environment..."
    # Prompt for Hydra admin URL or use default
    if [[ -t 0 ]]; then
        read -rp "Hydra Admin URL [http://hydra:4445]: " HYDRA_ADMIN_URL
    fi
    HYDRA_ADMIN_URL="${HYDRA_ADMIN_URL:-http://hydra:4445}"

    cat > "${SECRETS_FILE}" <<EOF
HYDRA_ADMIN_URL=${HYDRA_ADMIN_URL}
EOF
    chmod 600 "${SECRETS_FILE}"

    log_step "3. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  login-consent:
    image: oryd/hydra-login-consent-node:v2.2.0
    container_name: login-consent
    ports:
      - "3000:3000"
    environment:
      - HYDRA_ADMIN_URL=${HYDRA_ADMIN_URL}
      - NODE_TLS_REJECT_UNAUTHORIZED=0
    restart: unless-stopped
    networks:
      - consent-net

networks:
  consent-net:
    driver: bridge
COMPOSE

    log_step "4. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Login & Consent App (Docker)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=${SERVICE_DIR}
ExecStart=/usr/bin/docker compose --env-file .env up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now "${SCRIPT_NAME}"

    echo ""
    log_success "Login & Consent App installed and running"
    log_info "UI: http://localhost:3000"
    log_info "Hydra redirects login/consent flows to this app"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Login & Consent App"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Login & Consent App uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
