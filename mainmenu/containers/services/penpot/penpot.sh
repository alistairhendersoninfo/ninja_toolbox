#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="penpot"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/${SCRIPT_NAME}"

install() {
    log_info "Installing ${SCRIPT_NAME}"
    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    mkdir -p "${SERVICE_DIR}"/{data,config}
    mkdir -p "${SERVICE_DIR}/data/postgres"
    mkdir -p "${SERVICE_DIR}/data/assets"
    mkdir -p "${SERVICE_DIR}/data/valkey"

    # Generate secret key for Penpot
    log_step "Generating secret key..."
    PENPOT_SECRET_KEY="$(openssl rand -hex 32)"

    # Auto-detect LAN IP
    LAN_IP="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')"
    if [[ -z "$LAN_IP" ]]; then
        LAN_IP="$(hostname -I | awk '{print $1}')"
    fi
    if [[ -z "$LAN_IP" ]]; then
        LAN_IP="127.0.0.1"
        log_warn "Could not detect LAN IP, defaulting to 127.0.0.1"
    fi
    log_info "Detected LAN IP: ${LAN_IP}"

    PENPOT_PUBLIC_URI="http://${LAN_IP}:9001"
    log_info "Public URI: ${PENPOT_PUBLIC_URI}"

    cat > "${SERVICE_DIR}/docker-compose.yml" <<COMPOSE
version: "3.8"

services:
  penpot-frontend:
    image: penpotapp/frontend:latest
    container_name: penpot-frontend
    restart: unless-stopped
    ports:
      - "9001:8080"
    volumes:
      - ${SERVICE_DIR}/data/assets:/opt/data/assets
    depends_on:
      - penpot-backend
      - penpot-exporter
    environment:
      PENPOT_FLAGS: "enable-registration enable-login-with-password"
    networks:
      - penpot-net

  penpot-backend:
    image: penpotapp/backend:latest
    container_name: penpot-backend
    restart: unless-stopped
    volumes:
      - ${SERVICE_DIR}/data/assets:/opt/data/assets
    depends_on:
      - penpot-postgres
      - penpot-valkey
    environment:
      PENPOT_FLAGS: "enable-registration enable-login-with-password disable-email-verification enable-smtp disable-onboarding-questions"
      PENPOT_SECRET_KEY: ${PENPOT_SECRET_KEY}
      PENPOT_PUBLIC_URI: ${PENPOT_PUBLIC_URI}
      PENPOT_DATABASE_URI: postgresql://penpot-postgres/penpot
      PENPOT_DATABASE_USERNAME: penpot
      PENPOT_DATABASE_PASSWORD: penpot
      PENPOT_REDIS_URI: redis://penpot-valkey/0
      PENPOT_ASSETS_STORAGE_BACKEND: assets-fs
      PENPOT_STORAGE_ASSETS_FS_DIRECTORY: /opt/data/assets
      PENPOT_TELEMETRY_ENABLED: "false"
      PENPOT_SMTP_ENABLED: "false"
    networks:
      - penpot-net

  penpot-exporter:
    image: penpotapp/exporter:latest
    container_name: penpot-exporter
    restart: unless-stopped
    environment:
      PENPOT_PUBLIC_URI: http://penpot-frontend:8080
    depends_on:
      - penpot-frontend
    networks:
      - penpot-net

  penpot-postgres:
    image: postgres:16
    container_name: penpot-postgres
    restart: unless-stopped
    volumes:
      - ${SERVICE_DIR}/data/postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_INITDB_ARGS: --data-checksums
      POSTGRES_DB: penpot
      POSTGRES_USER: penpot
      POSTGRES_PASSWORD: penpot
    networks:
      - penpot-net

  penpot-valkey:
    image: valkey/valkey:8
    container_name: penpot-valkey
    restart: unless-stopped
    volumes:
      - ${SERVICE_DIR}/data/valkey:/data
    networks:
      - penpot-net

networks:
  penpot-net:
    driver: bridge
COMPOSE

    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=${SCRIPT_NAME} (Docker)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=${SERVICE_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now "${SCRIPT_NAME}"

    log_success "Penpot design platform installed"
    log_info "UI: ${PENPOT_PUBLIC_URI}"
    log_info "Data directory: ${SERVICE_DIR}/data"
    log_info ""
    log_info "Create your first account at ${PENPOT_PUBLIC_URI} (registration is enabled)"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling ${SCRIPT_NAME}"
    require_root
    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload
    cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Penpot uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
