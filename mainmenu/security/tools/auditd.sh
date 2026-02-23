#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="auditd"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

AUDIT_RULES="/etc/audit/rules.d/hardening.rules"

install() {
    log_info "Installing auditd with hardening rules"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing auditd and plugins..."
    pkg_install auditd audispd-plugins

    log_step "2. Writing hardening audit rules..."
    mkdir -p /etc/audit/rules.d

    cat > "$AUDIT_RULES" <<'RULES'
## Hardening audit rules — monitor critical files and syscalls

# Monitor user/group identity files
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity

# Monitor privilege escalation config
-w /etc/sudoers -p wa -k sudoers
-w /etc/sudoers.d/ -p wa -k sudoers

# Monitor authentication logs
-w /var/log/auth.log -p wa -k auth_log

# Monitor all program executions (execve syscalls)
-a always,exit -F arch=b64 -S execve -k exec_log
-a always,exit -F arch=b32 -S execve -k exec_log

# Monitor SSH config changes
-w /etc/ssh/sshd_config -p wa -k sshd_config

# Monitor cron changes
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

# Make the rules immutable (requires reboot to change)
-e 2
RULES

    log_step "3. Restarting auditd to apply rules..."
    systemctl enable auditd
    service auditd restart

    log_step "4. Verifying rules are loaded..."
    auditctl -l

    echo ""
    log_success "auditd installed with hardening rules"
    log_info "Rules file: $AUDIT_RULES"
    log_info "Use 'ausearch' and 'aureport' to query audit logs"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling auditd"
    require_root

    service auditd stop 2>/dev/null || true
    systemctl disable auditd 2>/dev/null || true
    rm -f "$AUDIT_RULES"
    pkg_remove auditd audispd-plugins
    apt-get autoremove -y 2>/dev/null || true

    log_success "auditd uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
