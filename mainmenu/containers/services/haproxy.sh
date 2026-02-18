#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="haproxy"
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

    # Write default HAProxy configuration
    cat > "${SERVICE_DIR}/config/haproxy.cfg" <<'HAPCFG'
global
    log stdout format raw local0
    maxconn 4096
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms
    retries 3

frontend http_front
    bind *:80
    default_backend http_back
    stats uri /haproxy?stats

frontend https_front
    bind *:443
    mode tcp
    default_backend https_back

frontend stats_front
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10s
    stats show-legends
    stats admin if TRUE

backend http_back
    balance roundrobin
    option httpchk GET /
    # Add your backend servers here:
    # server web1 192.168.1.10:80 check
    # server web2 192.168.1.11:80 check

backend https_back
    mode tcp
    balance roundrobin
    # Add your HTTPS backend servers here:
    # server web1 192.168.1.10:443 check
    # server web2 192.168.1.11:443 check
HAPCFG

    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  haproxy:
    image: haproxy:2.9-alpine
    container_name: haproxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8404:8404"
    volumes:
      - ./config/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
      - ./logs:/var/log/haproxy
    sysctls:
      - net.ipv4.ip_unprivileged_port_start=0
    networks:
      - haproxy-net

networks:
  haproxy-net:
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

    log_success "HAProxy installed"
    log_info "Stats page: http://localhost:8404/stats"
    log_info "Config file: ${SERVICE_DIR}/config/haproxy.cfg"
    log_info "Edit the config to add your backend servers, then restart with: systemctl restart haproxy"
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
    log_success "HAProxy uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
