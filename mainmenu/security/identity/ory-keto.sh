#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-keto"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory/keto"
SECRETS_FILE="/opt/app/docker/ory/keto/.env"

install() {
    log_info "Installing Ory Keto — fine-grained authorization (Zanzibar/ReBAC)"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}/config"

    log_step "2. Configuring database connection..."
    # Prompt for PostgreSQL DSN or use default
    if [[ -t 0 ]]; then
        read -rp "PostgreSQL DSN [postgres://keto:keto@localhost:5432/keto?sslmode=disable]: " PG_DSN
    fi
    PG_DSN="${PG_DSN:-postgres://keto:keto@localhost:5432/keto?sslmode=disable}"

    cat > "${SECRETS_FILE}" <<EOF
DSN=${PG_DSN}
EOF
    chmod 600 "${SECRETS_FILE}"

    log_step "3. Writing Keto config..."
    cat > "${SERVICE_DIR}/config/keto.yml" <<'KETO_CFG'
version: v0.12.0

dsn: memory

log:
  level: debug
  format: json

serve:
  read:
    host: 0.0.0.0
    port: 4466
  write:
    host: 0.0.0.0
    port: 4467
  metrics:
    host: 0.0.0.0
    port: 4468

namespaces:
  - id: 0
    name: resources
  - id: 1
    name: groups
  - id: 2
    name: objects
KETO_CFG

    log_step "4. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  keto-migrate:
    image: oryd/keto:v0.12.0
    container_name: keto-migrate
    environment:
      - DSN=${DSN}
    volumes:
      - ./config:/etc/config/keto:ro
    command: migrate up --yes --config /etc/config/keto/keto.yml
    restart: "no"
    networks:
      - keto-net

  keto:
    image: oryd/keto:v0.12.0
    container_name: keto
    depends_on:
      keto-migrate:
        condition: service_completed_successfully
    ports:
      - "4466:4466"
      - "4467:4467"
    environment:
      - DSN=${DSN}
    volumes:
      - ./config:/etc/config/keto:ro
    command: serve --config /etc/config/keto/keto.yml
    restart: unless-stopped
    networks:
      - keto-net

networks:
  keto-net:
    driver: bridge
COMPOSE

    log_step "5. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Keto Authorization Server (Docker)
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
    log_success "Ory Keto installed and running"
    log_info "Read API:  http://localhost:4466"
    log_info "Write API: http://localhost:4467"
    log_info "Config:    ${SERVICE_DIR}/config/keto.yml"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Keto"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Ory Keto uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
