#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-hydra"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory/hydra"
SECRETS_FILE="/opt/app/docker/ory/hydra/.env"

install() {
    log_info "Installing Ory Hydra — OAuth2/OIDC provider"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}"

    log_step "2. Generating secrets..."
    SYSTEM_SECRET=$(openssl rand -hex 16)
    OIDC_SUBJECT_SALT=$(openssl rand -hex 16)

    # Prompt for PostgreSQL DSN or use default
    if [[ -t 0 ]]; then
        read -rp "PostgreSQL DSN [postgres://hydra:hydra@localhost:5432/hydra?sslmode=disable]: " PG_DSN
    fi
    PG_DSN="${PG_DSN:-postgres://hydra:hydra@localhost:5432/hydra?sslmode=disable}"

    cat > "${SECRETS_FILE}" <<EOF
SYSTEM_SECRET=${SYSTEM_SECRET}
OIDC_SUBJECT_SALT=${OIDC_SUBJECT_SALT}
DSN=${PG_DSN}
EOF
    chmod 600 "${SECRETS_FILE}"

    log_step "3. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  hydra-migrate:
    image: oryd/hydra:v2.2.0
    container_name: hydra-migrate
    environment:
      - DSN=${DSN}
    command: migrate sql -e --yes
    restart: "no"
    networks:
      - hydra-net

  hydra:
    image: oryd/hydra:v2.2.0
    container_name: hydra
    depends_on:
      hydra-migrate:
        condition: service_completed_successfully
    ports:
      - "4444:4444"
      - "4445:4445"
    environment:
      - DSN=${DSN}
      - SECRETS_SYSTEM=${SYSTEM_SECRET}
      - OIDC_SUBJECT_IDENTIFIERS_PAIRWISE_SALT=${OIDC_SUBJECT_SALT}
      - URLS_SELF_ISSUER=http://localhost:4444
      - URLS_CONSENT=http://localhost:3000/consent
      - URLS_LOGIN=http://localhost:3000/login
      - URLS_LOGOUT=http://localhost:3000/logout
      - SERVE_PUBLIC_CORS_ENABLED=true
      - SERVE_PUBLIC_CORS_ALLOWED_ORIGINS=http://localhost:4455
      - SERVE_ADMIN_CORS_ENABLED=true
      - LOG_LEVEL=debug
      - LOG_FORMAT=json
      - OAUTH2_EXPOSE_INTERNAL_ERRORS=true
    command: serve all --dev
    restart: unless-stopped
    networks:
      - hydra-net

networks:
  hydra-net:
    driver: bridge
COMPOSE

    log_step "4. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Hydra OAuth2 Server (Docker)
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
    log_success "Ory Hydra installed and running"
    log_info "Public API (OAuth2): http://localhost:4444"
    log_info "Admin API:           http://localhost:4445"
    log_info "Note: Hydra requires a Login & Consent App — install ory-login-consent next"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Hydra"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Ory Hydra uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
