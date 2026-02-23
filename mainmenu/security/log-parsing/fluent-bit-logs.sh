#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="fluent-bit-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="fluent-bit"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

analyze() {
    log_info "Fluent Bit Service Log Analysis"
    echo ""

    # Collect Fluent Bit log entries from journal
    local TMPLOG
    TMPLOG=$(mktemp)
    journalctl -u fluent-bit --no-pager 2>/dev/null > "$TMPLOG" || true

    local TOTAL_ENTRIES
    TOTAL_ENTRIES=$(wc -l < "$TMPLOG")

    echo "============================================"
    echo " Fluent Bit Service Log Summary"
    echo "============================================"
    echo ""

    echo "Total log entries: $TOTAL_ENTRIES"
    echo ""

    if [[ "$TOTAL_ENTRIES" -eq 0 ]]; then
        log_info "No Fluent Bit log entries found in journal."
        log_info "Ensure Fluent Bit is running: systemctl status fluent-bit"
        rm -f "$TMPLOG"
        return
    fi

    # Service status
    echo "--- Service Status ---"
    systemctl is-active fluent-bit 2>/dev/null || echo "  Service not running"
    echo ""

    # Input plugin stats
    echo "--- Input Plugins ---"
    { grep -oP '\[input\] \K[^:]+' "$TMPLOG" | \
        sort | uniq -c | sort -rn; } || \
    { grep -i "input" "$TMPLOG" | grep -oP 'plugin:\K\S+' | \
        sort | uniq -c | sort -rn; } || echo "  No input plugin data found"
    echo ""

    # Output plugin stats
    echo "--- Output Plugins ---"
    { grep -oP '\[output\] \K[^:]+' "$TMPLOG" | \
        sort | uniq -c | sort -rn; } || \
    { grep -i "output" "$TMPLOG" | grep -oP 'plugin:\K\S+' | \
        sort | uniq -c | sort -rn; } || echo "  No output plugin data found"
    echo ""

    # Error count
    echo "--- Error Summary ---"
    local ERROR_COUNT WARN_COUNT
    ERROR_COUNT=$(grep -ci "error" "$TMPLOG" 2>/dev/null || echo "0")
    WARN_COUNT=$(grep -ci "warn" "$TMPLOG" 2>/dev/null || echo "0")
    echo "  Errors:   $ERROR_COUNT"
    echo "  Warnings: $WARN_COUNT"
    echo ""

    # Records processed (if available in logs)
    echo "--- Records Processed ---"
    { grep -oP 'records:\K\d+' "$TMPLOG" | \
        awk '{sum+=$1} END {print "  Total records: " sum}'; } || echo "  Record count not available in logs"
    echo ""

    # Recent log entries
    echo "--- Recent Log Entries (last 15) ---"
    tail -15 "$TMPLOG"
    echo ""

    rm -f "$TMPLOG"

    echo "============================================"
    log_success "Analysis complete"
    log_info "View full log: journalctl -u fluent-bit"
    log_info "Config: /etc/fluent-bit/fluent-bit.conf"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
