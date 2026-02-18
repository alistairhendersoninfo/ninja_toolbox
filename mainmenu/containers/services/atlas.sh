#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="atlas"
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

    mkdir -p "${SERVICE_DIR}"/{data,logs,config}
    mkdir -p "${SERVICE_DIR}/data/hbase" "${SERVICE_DIR}/data/solr"

    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  atlas:
    image: apache/atlas:2.3.0
    container_name: atlas
    hostname: atlas
    restart: unless-stopped
    ports:
      - "21000:21000"
    volumes:
      - ./data:/opt/apache-atlas/data
      - ./logs:/opt/apache-atlas/logs
      - ./config:/opt/apache-atlas/conf
    environment:
      - ATLAS_SERVER_HEAP=-Xms1024m -Xmx2048m
      - MANAGE_LOCAL_HBASE=true
      - MANAGE_LOCAL_SOLR=true
    depends_on:
      - atlas-hbase
      - atlas-solr
    networks:
      - atlas-net

  atlas-hbase:
    image: apache/atlas:2.3.0
    container_name: atlas-hbase
    hostname: atlas-hbase
    restart: unless-stopped
    command: ["/opt/apache-atlas/bin/atlas_start_hbase.sh"]
    volumes:
      - ./data/hbase:/opt/apache-atlas/data/hbase
    networks:
      - atlas-net

  atlas-solr:
    image: apache/atlas:2.3.0
    container_name: atlas-solr
    hostname: atlas-solr
    restart: unless-stopped
    command: ["/opt/apache-atlas/bin/atlas_start_solr.sh"]
    volumes:
      - ./data/solr:/opt/apache-atlas/data/solr
    networks:
      - atlas-net

networks:
  atlas-net:
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

    log_success "Apache Atlas installed"
    log_info "Atlas UI: http://localhost:21000 (default: admin/admin)"
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
    log_success "Apache Atlas uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
