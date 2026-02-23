#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="apparmor-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="aa-status"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install AppArmor first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

analyze() {
    log_info "AppArmor Log Analysis"
    echo ""

    # Collect AppArmor log entries
    local TMPLOG
    TMPLOG=$(mktemp)

    if [[ -f /var/log/syslog ]]; then
        { grep "apparmor" /var/log/syslog || true; } > "$TMPLOG"
    elif [[ -f /var/log/kern.log ]]; then
        { grep "apparmor" /var/log/kern.log || true; } > "$TMPLOG"
    else
        journalctl -k --no-pager 2>/dev/null | { grep "apparmor" || true; } > "$TMPLOG"
    fi

    local TOTAL_ENTRIES
    TOTAL_ENTRIES=$(wc -l < "$TMPLOG")

    echo "============================================"
    echo " AppArmor Log Summary"
    echo "============================================"
    echo ""

    # Current AppArmor status
    echo "--- Current Profile Status ---"
    aa-status 2>/dev/null | head -20 || echo "  Unable to read aa-status (may need root)"
    echo ""

    echo "Total log entries: $TOTAL_ENTRIES"
    echo ""

    if [[ "$TOTAL_ENTRIES" -eq 0 ]]; then
        log_info "No AppArmor log entries found."
        log_info "This may mean no denials have occurred (good!) or logging is elsewhere."
        rm -f "$TMPLOG"
        return
    fi

    # DENIED events by profile
    echo "--- DENIED Events by Profile ---"
    { grep "DENIED" "$TMPLOG" | \
        grep -oP 'profile="\K[^"]+' | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No DENIED events found"
    echo ""

    # Operation type breakdown
    echo "--- Operation Type Breakdown ---"
    { grep "DENIED" "$TMPLOG" | \
        grep -oP 'operation="\K[^"]+' | \
        sort | uniq -c | sort -rn; } || echo "  No operation data found"
    echo ""

    # ALLOWED events count
    local ALLOWED_COUNT DENIED_COUNT
    DENIED_COUNT=$(grep -c "DENIED" "$TMPLOG" 2>/dev/null || echo "0")
    ALLOWED_COUNT=$(grep -c "ALLOWED" "$TMPLOG" 2>/dev/null || echo "0")
    echo "--- Event Summary ---"
    echo "  DENIED:  $DENIED_COUNT"
    echo "  ALLOWED: $ALLOWED_COUNT"
    echo ""

    # Recent denials
    echo "--- Recent Denials (last 10) ---"
    { grep "DENIED" "$TMPLOG" | tail -10; } || echo "  No recent denials"
    echo ""

    rm -f "$TMPLOG"

    echo "============================================"
    log_success "Analysis complete"
    log_info "View full log: grep apparmor /var/log/syslog"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
