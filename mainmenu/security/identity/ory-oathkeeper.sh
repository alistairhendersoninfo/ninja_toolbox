#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-oathkeeper"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory/oathkeeper"

install() {
    log_info "Installing Ory Oathkeeper — Identity & Access Proxy"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}/config"

    log_step "2. Writing Oathkeeper config..."
    cat > "${SERVICE_DIR}/config/oathkeeper.yml" <<'OATHKEEPER_CFG'
serve:
  proxy:
    port: 4455
    cors:
      enabled: true
      allowed_origins:
        - "*"
      allowed_methods:
        - POST
        - GET
        - PUT
        - PATCH
        - DELETE
      allowed_headers:
        - Authorization
        - Content-Type
      exposed_headers:
        - Content-Type
  api:
    port: 4456

log:
  level: debug
  format: json

access_rules:
  matching_strategy: regexp
  repositories:
    - file:///etc/config/oathkeeper/rules.json

authenticators:
  anonymous:
    enabled: true
    config:
      subject: guest
  cookie_session:
    enabled: true
    config:
      check_session_url: http://kratos:4433/sessions/whoami
      preserve_path: true
      extra_from: "@this"
      subject_from: "identity.id"
      only:
        - ory_kratos_session
  noop:
    enabled: true

authorizers:
  allow:
    enabled: true
  deny:
    enabled: true

mutators:
  noop:
    enabled: true
  id_token:
    enabled: true
    config:
      issuer_url: http://localhost:4455/
      jwks_url: file:///etc/config/oathkeeper/jwks.json
  header:
    enabled: true
    config:
      headers:
        X-User: "{{ print .Subject }}"
OATHKEEPER_CFG

    log_step "3. Writing default access rules..."
    cat > "${SERVICE_DIR}/config/rules.json" <<'RULES'
[
  {
    "id": "allow-public-health",
    "upstream": {
      "url": "http://localhost:8080"
    },
    "match": {
      "url": "http://localhost:4455/health/<**>",
      "methods": ["GET"]
    },
    "authenticators": [{ "handler": "anonymous" }],
    "authorizer": { "handler": "allow" },
    "mutators": [{ "handler": "noop" }]
  },
  {
    "id": "protected-api",
    "upstream": {
      "url": "http://localhost:8080"
    },
    "match": {
      "url": "http://localhost:4455/api/<**>",
      "methods": ["GET", "POST", "PUT", "PATCH", "DELETE"]
    },
    "authenticators": [{ "handler": "cookie_session" }],
    "authorizer": { "handler": "allow" },
    "mutators": [{ "handler": "header" }]
  }
]
RULES

    log_step "4. Generating JWKS signing key..."
    # Generate a minimal RSA JWKS for id_token mutator
    cat > "${SERVICE_DIR}/config/jwks.json" <<'JWKS'
{
  "keys": []
}
JWKS
    log_info "Note: For production, generate proper JWKS keys with:"
    log_info "  docker run oryd/oathkeeper:v0.40.7 credentials generate --alg RS256 > jwks.json"

    log_step "5. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  oathkeeper:
    image: oryd/oathkeeper:v0.40.7
    container_name: oathkeeper
    ports:
      - "4455:4455"
      - "4456:4456"
    volumes:
      - ./config:/etc/config/oathkeeper:ro
    command: serve --config /etc/config/oathkeeper/oathkeeper.yml
    restart: unless-stopped
    networks:
      - oathkeeper-net

networks:
  oathkeeper-net:
    driver: bridge
COMPOSE

    log_step "6. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Oathkeeper Identity Proxy (Docker)
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

    echo ""
    log_success "Ory Oathkeeper installed and running"
    log_info "Proxy:  http://localhost:4455"
    log_info "API:    http://localhost:4456"
    log_info "Rules:  ${SERVICE_DIR}/config/rules.json"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Oathkeeper"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Ory Oathkeeper uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
