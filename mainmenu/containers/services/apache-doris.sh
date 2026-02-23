#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="apache-doris"
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

    # Check docker is available
    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    mkdir -p "${SERVICE_DIR}"/{data,logs,config}
    mkdir -p "${SERVICE_DIR}/data/fe" "${SERVICE_DIR}/data/be"
    mkdir -p "${SERVICE_DIR}/logs/fe" "${SERVICE_DIR}/logs/be"

    # Write docker-compose.yml
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  doris-fe:
    image: apache/doris:2.1.0-fe
    container_name: doris-fe
    hostname: doris-fe
    restart: unless-stopped
    ports:
      - "8030:8030"
      - "9030:9030"
    volumes:
      - ./data/fe:/opt/apache-doris/fe/doris-meta
      - ./logs/fe:/opt/apache-doris/fe/log
    environment:
      - FE_SERVERS=fe1:doris-fe:9010
      - FE_ID=1
    networks:
      - doris-net

  doris-be:
    image: apache/doris:2.1.0-be
    container_name: doris-be
    hostname: doris-be
    restart: unless-stopped
    depends_on:
      - doris-fe
    volumes:
      - ./data/be:/opt/apache-doris/be/storage
      - ./logs/be:/opt/apache-doris/be/log
    environment:
      - FE_SERVERS=doris-fe:9030
      - BE_ADDR=doris-be:9050
    networks:
      - doris-net

networks:
  doris-net:
    driver: bridge
COMPOSE

    # Create systemd unit
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

    log_success "Apache Doris installed"
    log_info "Frontend UI: http://localhost:8030"
    log_info "MySQL protocol: localhost:9030 (user: root, no password)"
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
    log_success "Apache Doris uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
