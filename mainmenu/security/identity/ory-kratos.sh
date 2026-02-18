#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-kratos"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory/kratos"
SECRETS_FILE="/opt/app/docker/ory/kratos/.env"

install() {
    log_info "Installing Ory Kratos — identity management"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}"/{config,data}

    log_step "2. Generating secrets..."
    KRATOS_SECRET=$(openssl rand -hex 16)
    COOKIE_SECRET=$(openssl rand -hex 16)

    # Prompt for PostgreSQL DSN or use default
    if [[ -t 0 ]]; then
        read -rp "PostgreSQL DSN [postgres://kratos:kratos@localhost:5432/kratos?sslmode=disable]: " PG_DSN
    fi
    PG_DSN="${PG_DSN:-postgres://kratos:kratos@localhost:5432/kratos?sslmode=disable}"

    cat > "${SECRETS_FILE}" <<EOF
KRATOS_SECRET=${KRATOS_SECRET}
COOKIE_SECRET=${COOKIE_SECRET}
DSN=${PG_DSN}
EOF
    chmod 600 "${SECRETS_FILE}"

    log_step "3. Writing Kratos identity schema config..."
    cat > "${SERVICE_DIR}/config/kratos.yml" <<'KRATOS_CFG'
version: v0.13.0

dsn: __DSN_PLACEHOLDER__

serve:
  public:
    base_url: http://localhost:4433/
    cors:
      enabled: true
  admin:
    base_url: http://localhost:4434/

selfservice:
  default_browser_return_url: http://localhost:4455/
  allowed_return_urls:
    - http://localhost:4455

  methods:
    password:
      enabled: true
    webauthn:
      enabled: true
      config:
        rp:
          id: localhost
          display_name: NinjaMenu
          origin: http://localhost:4455
    totp:
      enabled: true

  flows:
    error:
      ui_url: http://localhost:4455/error
    settings:
      ui_url: http://localhost:4455/settings
    recovery:
      enabled: true
      ui_url: http://localhost:4455/recovery
    verification:
      enabled: true
      ui_url: http://localhost:4455/verification
    logout:
      after:
        default_browser_return_url: http://localhost:4455/login
    login:
      ui_url: http://localhost:4455/login
      lifespan: 10m
    registration:
      ui_url: http://localhost:4455/registration
      lifespan: 10m
      after:
        password:
          hooks:
            - hook: session

identity:
  default_schema_id: default
  schemas:
    - id: default
      url: file:///etc/config/kratos/identity.schema.json

secrets:
  cookie:
    - __COOKIE_SECRET_PLACEHOLDER__
  cipher:
    - __KRATOS_SECRET_PLACEHOLDER__

hashers:
  argon2:
    parallelism: 1
    memory: 128MB
    iterations: 2
    salt_length: 16
    key_length: 16
KRATOS_CFG

    # Write the default identity schema
    cat > "${SERVICE_DIR}/config/identity.schema.json" <<'SCHEMA'
{
  "$id": "https://schemas.ory.sh/presets/kratos/quickstart/email-password/identity.schema.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Person",
  "type": "object",
  "properties": {
    "traits": {
      "type": "object",
      "properties": {
        "email": {
          "type": "string",
          "format": "email",
          "title": "E-Mail",
          "minLength": 3,
          "ory.sh/kratos": {
            "credentials": {
              "password": { "identifier": true },
              "webauthn": { "identifier": true }
            },
            "recovery": { "via": "email" },
            "verification": { "via": "email" }
          }
        },
        "name": {
          "type": "object",
          "properties": {
            "first": { "title": "First Name", "type": "string" },
            "last": { "title": "Last Name", "type": "string" }
          }
        }
      },
      "required": ["email"],
      "additionalProperties": false
    }
  }
}
SCHEMA

    log_step "4. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  kratos-migrate:
    image: oryd/kratos:v1.1.0
    container_name: kratos-migrate
    environment:
      - DSN=${DSN}
    volumes:
      - ./config:/etc/config/kratos:ro
    command: migrate sql -e --yes
    restart: "no"
    networks:
      - kratos-net

  kratos:
    image: oryd/kratos:v1.1.0
    container_name: kratos
    depends_on:
      kratos-migrate:
        condition: service_completed_successfully
    ports:
      - "4433:4433"
      - "4434:4434"
    environment:
      - DSN=${DSN}
      - SECRETS_COOKIE=${COOKIE_SECRET}
      - SECRETS_CIPHER=${KRATOS_SECRET}
    volumes:
      - ./config:/etc/config/kratos:ro
    command: serve -c /etc/config/kratos/kratos.yml --dev --watch-courier
    restart: unless-stopped
    networks:
      - kratos-net

networks:
  kratos-net:
    driver: bridge
COMPOSE

    log_step "5. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Kratos Identity Server (Docker)
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
    log_success "Ory Kratos installed and running"
    log_info "Public API: http://localhost:4433"
    log_info "Admin API:  http://localhost:4434"
    log_info "Config dir: ${SERVICE_DIR}/config"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Kratos"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Ory Kratos uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
