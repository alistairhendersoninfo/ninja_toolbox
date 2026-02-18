#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="security-onion"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/${SCRIPT_NAME}"
SO_REPO="https://github.com/Security-Onion-Solutions/securityonion"
SO_SETUP_SCRIPT="https://raw.githubusercontent.com/Security-Onion-Solutions/securityonion/2.4/main/setup/so-setup-network"

install() {
    log_info "Installing ${SCRIPT_NAME}"
    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    # Check minimum system requirements
    log_step "Checking system requirements..."

    # Check RAM (minimum 16GB)
    TOTAL_RAM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
    TOTAL_RAM_GB=$(( TOTAL_RAM_KB / 1024 / 1024 ))
    if [[ "${TOTAL_RAM_GB}" -lt 16 ]]; then
        log_error "Security Onion requires at least 16GB RAM. Detected: ${TOTAL_RAM_GB}GB"
        exit 1
    fi
    log_info "RAM check passed: ${TOTAL_RAM_GB}GB detected"

    # Check CPU cores (minimum 4)
    CPU_CORES=$(nproc 2>/dev/null || echo "0")
    if [[ "${CPU_CORES}" -lt 4 ]]; then
        log_error "Security Onion requires at least 4 CPU cores. Detected: ${CPU_CORES}"
        exit 1
    fi
    log_info "CPU check passed: ${CPU_CORES} cores detected"

    # Check disk space (minimum 200GB free on /opt or /)
    DISK_FREE_KB=$(df --output=avail /opt 2>/dev/null | tail -1 || df --output=avail / 2>/dev/null | tail -1 || echo "0")
    DISK_FREE_GB=$(( DISK_FREE_KB / 1024 / 1024 ))
    if [[ "${DISK_FREE_GB}" -lt 200 ]]; then
        log_error "Security Onion requires at least 200GB free disk. Detected: ${DISK_FREE_GB}GB on /opt"
        exit 1
    fi
    log_info "Disk check passed: ${DISK_FREE_GB}GB free"

    log_step "System requirements met. Proceeding with installation..."

    mkdir -p "${SERVICE_DIR}"/{data,logs,config}

    # Clone the Security Onion repository
    log_step "Cloning Security Onion repository..."
    if [[ -d "${SERVICE_DIR}/securityonion" ]]; then
        cd "${SERVICE_DIR}/securityonion" && git pull
    else
        git clone --depth 1 --branch 2.4/main "${SO_REPO}" "${SERVICE_DIR}/securityonion"
    fi

    # Download the network setup script
    log_step "Downloading Security Onion setup script..."
    curl -sSL "${SO_SETUP_SCRIPT}" -o "${SERVICE_DIR}/so-setup-network"
    chmod +x "${SERVICE_DIR}/so-setup-network"

    log_success "Security Onion files downloaded to ${SERVICE_DIR}"
    log_info ""
    log_info "============================================================"
    log_info "Security Onion uses its own installer and cannot be deployed"
    log_info "with a simple docker-compose. To complete installation:"
    log_info ""
    log_info "  cd ${SERVICE_DIR}"
    log_info "  sudo ./so-setup-network"
    log_info ""
    log_info "The setup wizard will guide you through:"
    log_info "  - Deployment type (standalone, distributed, etc.)"
    log_info "  - Network interface selection"
    log_info "  - Service configuration"
    log_info "  - Admin account creation"
    log_info ""
    log_info "Minimum requirements verified:"
    log_info "  RAM: ${TOTAL_RAM_GB}GB (min 16GB)"
    log_info "  CPU: ${CPU_CORES} cores (min 4)"
    log_info "  Disk: ${DISK_FREE_GB}GB free (min 200GB)"
    log_info "============================================================"

    mark_installed true
}

uninstall() {
    log_info "Uninstalling ${SCRIPT_NAME}"
    require_root

    # Security Onion has its own teardown if fully installed
    if [[ -x "/usr/sbin/so-uninstall" ]]; then
        log_info "Running Security Onion uninstaller..."
        /usr/sbin/so-uninstall --confirm || true
    fi

    # Clean up downloaded files
    if [[ -d "${SERVICE_DIR}" ]]; then
        log_info "Removing Security Onion files from ${SERVICE_DIR}..."
        rm -rf "${SERVICE_DIR}/securityonion"
        rm -f "${SERVICE_DIR}/so-setup-network"
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Security Onion uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
