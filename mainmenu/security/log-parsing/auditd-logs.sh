#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="auditd-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="ausearch"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install auditd first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

AUDIT_LOG="/var/log/audit/audit.log"

analyze() {
    log_info "auditd Log Analysis"
    echo ""

    if [[ ! -f "$AUDIT_LOG" ]]; then
        log_error "Audit log not found: $AUDIT_LOG"
        log_info "Ensure auditd is installed and running."
        exit 1
    fi

    echo "============================================"
    echo " auditd Log Summary"
    echo "============================================"
    echo ""

    # Overall summary using aureport
    echo "--- General Summary ---"
    aureport --summary 2>/dev/null || echo "  aureport summary unavailable"
    echo ""

    # Failed syscalls
    echo "--- Failed Syscalls (top 10) ---"
    { aureport --syscall --failed --summary 2>/dev/null | head -15; } || echo "  No failed syscall data"
    echo ""

    # File access events (identity key from our hardening rules)
    echo "--- File Access Events (identity monitoring) ---"
    { ausearch -k identity --interpret 2>/dev/null | grep "type=SYSCALL" | wc -l | \
        xargs -I{} echo "  Total identity-related events: {}"; } || echo "  No identity events found"
    echo ""

    # User authentication events
    echo "--- Authentication Events ---"
    { aureport --auth --summary 2>/dev/null | head -15; } || echo "  No auth data"
    echo ""

    # Executable runs (from exec_log key)
    echo "--- Program Executions (last 10) ---"
    { ausearch -k exec_log --interpret 2>/dev/null | \
        grep "type=EXECVE" | tail -10; } || echo "  No execve data found"
    echo ""

    # Sudoers changes
    echo "--- Sudoers Config Changes ---"
    local SUDOERS_COUNT
    SUDOERS_COUNT=$(ausearch -k sudoers 2>/dev/null | grep -c "type=SYSCALL" || echo "0")
    echo "  Total sudoers-related events: $SUDOERS_COUNT"
    echo ""

    # Recent events (last 10 from any key)
    echo "--- Recent Audit Events (last 10) ---"
    { ausearch --start recent --interpret 2>/dev/null | \
        grep "type=SYSCALL" | tail -10; } || echo "  No recent events"
    echo ""

    echo "============================================"
    log_success "Analysis complete"
    log_info "Full log: $AUDIT_LOG"
    log_info "Interactive search: ausearch -i -k <key>"
    log_info "Full report: aureport"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
