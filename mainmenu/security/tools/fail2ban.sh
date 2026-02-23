#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="fail2ban"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing fail2ban"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing fail2ban..."
    pkg_install fail2ban

    log_step "2. Creating local jail config..."
    if [[ ! -f /etc/fail2ban/jail.local ]]; then
        cat > /etc/fail2ban/jail.local <<'JAIL'
[DEFAULT]
bantime  = 10m
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
JAIL
        log_info "Created /etc/fail2ban/jail.local with sshd jail enabled"
    else
        log_info "/etc/fail2ban/jail.local already exists — skipping"
    fi

    log_step "3. Starting fail2ban service..."
    systemctl enable --now fail2ban

    log_step "4. Verifying installation..."
    fail2ban-client version
    fail2ban-client status

    echo ""
    log_success "fail2ban installed and running"
    log_info "Check status:    fail2ban-client status"
    log_info "Check SSH jail:  fail2ban-client status sshd"
    log_info "Unban an IP:     fail2ban-client set sshd unbanip <IP>"
    log_info "Config file:     /etc/fail2ban/jail.local"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling fail2ban"
    require_root

    systemctl stop fail2ban 2>/dev/null || true
    systemctl disable fail2ban 2>/dev/null || true
    pkg_remove fail2ban
    apt-get autoremove -y 2>/dev/null || true

    log_success "fail2ban uninstalled"
    log_info "Config files in /etc/fail2ban/ were left intact"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
