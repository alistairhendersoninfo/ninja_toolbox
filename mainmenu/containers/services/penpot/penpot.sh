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

COMPOSE_DIR="/opt/app/docker/${SCRIPT_NAME}"
COMPOSE_FILE="${COMPOSE_DIR}/docker-compose.yaml"
PROJECT_NAME="penpot"

install() {
    log_info "Installing ${SCRIPT_NAME}"
    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    if ! docker compose version &>/dev/null; then
        log_error "Docker Compose plugin is required. Install Docker CE which includes it."
        exit 1
    fi

    mkdir -p "${COMPOSE_DIR}"

    # Generate a cryptographically secure secret key
    log_step "Generating secret key..."
    if command -v python3 &>/dev/null; then
        PENPOT_SECRET_KEY="$(python3 -c 'import secrets; print(secrets.token_urlsafe(64))')"
    else
        PENPOT_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')"
    fi

    # Auto-detect LAN IP for the public URI
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

    # Download official Penpot docker-compose.yaml and patch for LAN install
    # Source: https://help.penpot.app/technical-guide/getting-started/docker/
    COMPOSE_URL="https://raw.githubusercontent.com/penpot/penpot/main/docker/images/docker-compose.yaml"

    log_step "Downloading official Penpot docker-compose.yaml..."
    if command -v curl &>/dev/null; then
        curl -fsSL "${COMPOSE_URL}" -o "${COMPOSE_FILE}" || {
            log_error "Failed to download ${COMPOSE_URL}"
            exit 1
        }
    elif command -v wget &>/dev/null; then
        wget -qO "${COMPOSE_FILE}" "${COMPOSE_URL}" || {
            log_error "Failed to download ${COMPOSE_URL}"
            exit 1
        }
    else
        log_error "curl or wget is required to download the Penpot compose file"
        exit 1
    fi
    log_info "Downloaded: ${COMPOSE_FILE}"

    log_step "Patching docker-compose.yaml for LAN install..."

    # Patch 1 — Secret key (replaces placeholder in YAML anchor)
    sed -i "s|PENPOT_SECRET_KEY: change-this-insecure-key|PENPOT_SECRET_KEY: ${PENPOT_SECRET_KEY}|" "${COMPOSE_FILE}"

    # Patch 2 — Public URI (replaces localhost with LAN IP in YAML anchor)
    sed -i "s|PENPOT_PUBLIC_URI: http://localhost:9001|PENPOT_PUBLIC_URI: ${PENPOT_PUBLIC_URI}|" "${COMPOSE_FILE}"

    # Patch 3 — Registration flags (prepend to existing flags value)
    sed -i "s|PENPOT_FLAGS: disable-email-verification|PENPOT_FLAGS: enable-registration enable-login-with-password disable-email-verification|" "${COMPOSE_FILE}"

    # Verify all patches applied (fail-fast if upstream yaml format changed)
    grep -q "${PENPOT_SECRET_KEY}" "${COMPOSE_FILE}" || {
        log_error "Secret key patch failed — upstream yaml format may have changed"
        exit 1
    }
    grep -q "${LAN_IP}" "${COMPOSE_FILE}" || {
        log_error "Public URI patch failed — upstream yaml format may have changed"
        exit 1
    }
    grep -q "enable-registration" "${COMPOSE_FILE}" || {
        log_error "Flags patch failed — upstream yaml format may have changed"
        exit 1
    }
    log_info "All patches applied and verified"

    # Create systemd service for boot persistence
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Penpot (Docker Compose)
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=${COMPOSE_DIR}
ExecStart=/usr/bin/docker compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} up -d --remove-orphans
ExecStop=/usr/bin/docker compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable "${SCRIPT_NAME}"

    log_step "Pulling Penpot images (this may take a few minutes)..."
    docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" pull

    log_step "Starting Penpot containers..."
    if ! docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" up -d --remove-orphans; then
        log_error "Failed to start Penpot containers"
        log_info "Check: docker compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} logs"
        exit 1
    fi

    # Wait briefly then verify containers are up
    sleep 5
    if ! docker ps --filter name=penpot-frontend --format '{{.Names}}' | grep -q penpot-frontend; then
        log_error "penpot-frontend container is not running"
        log_info "Check: docker compose -p ${PROJECT_NAME} -f ${COMPOSE_FILE} logs"
        exit 1
    fi

    log_success "Penpot installed successfully"
    log_info "UI:          ${PENPOT_PUBLIC_URI}"
    log_info "Mail UI:     http://${LAN_IP}:1080  (catch all outgoing emails)"
    log_info "Compose:     ${COMPOSE_FILE}"
    log_info ""
    log_info "Register your first account at ${PENPOT_PUBLIC_URI}"
    log_info "(Registration is open — create an account to get started)"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling ${SCRIPT_NAME}"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -f "${COMPOSE_FILE}" ]]; then
        log_step "Stopping and removing containers..."
        docker compose -p "${PROJECT_NAME}" -f "${COMPOSE_FILE}" down 2>/dev/null || true
    fi

    log_warn "Docker volumes (database + assets) are preserved."
    log_info "To also delete all data run:"
    log_info "  docker volume rm penpot_postgres_v15 penpot_assets"
    log_info "Compose file preserved at: ${COMPOSE_FILE}"

    log_success "Penpot uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
