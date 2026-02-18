#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ozone"
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
    mkdir -p "${SERVICE_DIR}/data/om" "${SERVICE_DIR}/data/scm" "${SERVICE_DIR}/data/datanode"

    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  ozone-om:
    image: apache/ozone:1.4.0
    container_name: ozone-om
    hostname: ozone-om
    restart: unless-stopped
    command: ["ozone", "om"]
    ports:
      - "9874:9874"
      - "9862:9862"
    volumes:
      - ./data/om:/data
    environment:
      OZONE-SITE.XML_ozone.om.address: ozone-om
      OZONE-SITE.XML_ozone.scm.names: ozone-scm
      OZONE-SITE.XML_ozone.scm.datanode.id: /data
      OZONE-SITE.XML_ozone.om.http-address: ozone-om:9874
      OZONE-SITE.XML_hdds.datanode.dir: /data/datanode
    networks:
      - ozone-net

  ozone-scm:
    image: apache/ozone:1.4.0
    container_name: ozone-scm
    hostname: ozone-scm
    restart: unless-stopped
    command: ["ozone", "scm"]
    volumes:
      - ./data/scm:/data
    environment:
      OZONE-SITE.XML_ozone.scm.names: ozone-scm
      OZONE-SITE.XML_ozone.om.address: ozone-om
      OZONE-SITE.XML_hdds.datanode.dir: /data/datanode
      OZONE-SITE.XML_ozone.scm.datanode.id: /data
    networks:
      - ozone-net

  ozone-datanode:
    image: apache/ozone:1.4.0
    container_name: ozone-datanode
    hostname: ozone-datanode
    restart: unless-stopped
    command: ["ozone", "datanode"]
    depends_on:
      - ozone-scm
    volumes:
      - ./data/datanode:/data
    environment:
      OZONE-SITE.XML_ozone.scm.names: ozone-scm
      OZONE-SITE.XML_ozone.om.address: ozone-om
      OZONE-SITE.XML_hdds.datanode.dir: /data/datanode
    networks:
      - ozone-net

networks:
  ozone-net:
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

    log_success "Apache Ozone installed"
    log_info "OzoneManager UI: http://localhost:9874"
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
    log_success "Apache Ozone uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
