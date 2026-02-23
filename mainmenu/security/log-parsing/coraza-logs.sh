#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="coraza-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nginx"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

AUDIT_LOG="/var/log/nginx/modsec_audit.log"

analyze() {
    log_info "Coraza WAF / ModSecurity Audit Log Analysis"
    echo ""

    if [[ ! -f "$AUDIT_LOG" ]]; then
        log_error "Audit log not found: $AUDIT_LOG"
        log_info "Ensure Coraza WAF is installed and configured to log to this path."
        exit 1
    fi

    local TOTAL_ENTRIES
    TOTAL_ENTRIES=$(grep -c -- "^--[a-f0-9]*-A--$" "$AUDIT_LOG" 2>/dev/null || echo "0")

    echo "============================================"
    echo " Coraza WAF Audit Log Summary"
    echo "============================================"
    echo ""

    echo "Total requests logged: $TOTAL_ENTRIES"
    echo ""

    # Top 10 blocked source IPs (from section A headers)
    echo "--- Top 10 Source IPs ---"
    { grep -A1 -- "^--[a-f0-9]*-A--$" "$AUDIT_LOG" | \
        grep -oP '\d+\.\d+\.\d+\.\d+' | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No IP data found"
    echo ""

    # Top triggered rules (from section H messages)
    echo "--- Top Triggered Rules ---"
    { grep -oP 'id "\K[0-9]+' "$AUDIT_LOG" | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No rule data found"
    echo ""

    # Top matched messages
    echo "--- Top Rule Messages ---"
    { grep -oP 'msg "\K[^"]+' "$AUDIT_LOG" | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No message data found"
    echo ""

    # Recent blocks (last 10 entries)
    echo "--- Recent Log Entries (last 10) ---"
    { grep -B1 "^--[a-f0-9]*-H--$" "$AUDIT_LOG" | \
        grep -v "^--$" | tail -20; } || echo "  No recent entries found"
    echo ""

    echo "============================================"
    log_success "Analysis complete"
    log_info "Full log: $AUDIT_LOG"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
