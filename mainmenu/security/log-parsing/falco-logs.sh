#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="falco-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="falco"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

analyze() {
    log_info "Falco Runtime Security Log Analysis"
    echo ""

    # Collect Falco log entries from journal or syslog
    local TMPLOG
    TMPLOG=$(mktemp)

    if journalctl -u falco --no-pager 2>/dev/null | { grep -i "falco" || true; } > "$TMPLOG" && [[ -s "$TMPLOG" ]]; then
        log_info "Reading from journalctl -u falco"
    elif [[ -f /var/log/syslog ]]; then
        { grep -i "falco" /var/log/syslog || true; } > "$TMPLOG"
        log_info "Reading from /var/log/syslog"
    else
        log_error "No Falco log entries found in journal or syslog"
        rm -f "$TMPLOG"
        exit 1
    fi

    local TOTAL_ENTRIES
    TOTAL_ENTRIES=$(wc -l < "$TMPLOG")

    echo "============================================"
    echo " Falco Runtime Security Alert Summary"
    echo "============================================"
    echo ""

    echo "Total log entries: $TOTAL_ENTRIES"
    echo ""

    if [[ "$TOTAL_ENTRIES" -eq 0 ]]; then
        log_info "No Falco alerts found. The system may be clean or Falco is not generating output."
        rm -f "$TMPLOG"
        return
    fi

    # Alerts by priority level
    echo "--- Alerts by Priority ---"
    for priority in Emergency Alert Critical Error Warning Notice Informational Debug; do
        local COUNT
        COUNT=$(grep -ci "$priority" "$TMPLOG" 2>/dev/null || echo "0")
        if [[ "$COUNT" -gt 0 ]]; then
            printf "  %-15s %s\n" "$priority:" "$COUNT"
        fi
    done
    echo ""

    # Top triggered rules
    echo "--- Top 10 Triggered Rules ---"
    { grep -oP '(?:Rule|rule)\s*[=:]\s*\K[^,]+' "$TMPLOG" | \
        sort | uniq -c | sort -rn | head -10; } || \
    { grep -oP 'Notice\s+\K[^(]+' "$TMPLOG" | \
        sort | uniq -c | sort -rn | head -10; } || \
    echo "  No rule data found"
    echo ""

    # Recent alerts (last 15 lines)
    echo "--- Recent Alerts (last 15) ---"
    tail -15 "$TMPLOG"
    echo ""

    rm -f "$TMPLOG"

    echo "============================================"
    log_success "Analysis complete"
    log_info "View full log: journalctl -u falco"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
