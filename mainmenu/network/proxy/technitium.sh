#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="technitium"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/technitium"

install() {
    log_info "Installing Technitium DNS Server"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}"/{config,logs}

    log_step "2. Writing docker-compose.yml..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  technitium:
    image: technitium/dns-server:latest
    container_name: technitium
    hostname: technitium-dns
    restart: unless-stopped
    ports:
      # Web management UI
      - "5380:5380"
      # DNS (TCP + UDP)
      - "53:53/udp"
      - "53:53/tcp"
      # DNS-over-HTTPS (optional)
      - "443:443/tcp"
      # DNS-over-TLS (optional)
      - "853:853/tcp"
    volumes:
      - ./config:/etc/dns/config
      - ./logs:/etc/dns/logs
    environment:
      - DNS_SERVER_DOMAIN=dns-server
      - DNS_SERVER_ADMIN_PASSWORD=
      - DNS_SERVER_PREFER_IPV6=false
      - DNS_SERVER_LOG_USING_LOCAL_TIME=true
    networks:
      - technitium-net

networks:
  technitium-net:
    driver: bridge
COMPOSE

    log_step "3. Checking for port 53 conflicts..."
    # systemd-resolved often binds port 53; disable its stub listener if present
    if systemctl is-active systemd-resolved &>/dev/null; then
        log_info "systemd-resolved detected. Disabling stub listener on port 53..."
        mkdir -p /etc/systemd/resolved.conf.d
        cat > /etc/systemd/resolved.conf.d/disable-stub.conf <<'RESOLVED'
[Resolve]
DNSStubListener=no
RESOLVED
        systemctl restart systemd-resolved
        # Update /etc/resolv.conf to point to real upstream
        if [[ -L /etc/resolv.conf ]]; then
            ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
        fi
        log_info "systemd-resolved stub listener disabled"
    fi

    log_step "4. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Technitium DNS Server (Docker)
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
    log_success "Technitium DNS Server installed and running"
    log_info "Web UI:  http://localhost:5380"
    log_info "DNS:     localhost:53 (TCP/UDP)"
    log_info "Config:  ${SERVICE_DIR}/config"
    log_info ""
    log_info "First login: set an admin password via the web UI"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Technitium DNS Server"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    # Re-enable systemd-resolved stub if we disabled it
    if [[ -f /etc/systemd/resolved.conf.d/disable-stub.conf ]]; then
        rm -f /etc/systemd/resolved.conf.d/disable-stub.conf
        systemctl restart systemd-resolved 2>/dev/null || true
        log_info "systemd-resolved stub listener re-enabled"
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Technitium DNS Server uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
