#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="nftables-logs"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nft"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

analyze() {
    log_info "nftables Firewall Log Analysis"
    echo ""

    # Pull nftables log entries from the journal
    local TMPLOG
    TMPLOG=$(mktemp)
    journalctl --no-pager -k 2>/dev/null | { grep "nftables" || true; } > "$TMPLOG"

    local TOTAL_ENTRIES
    TOTAL_ENTRIES=$(wc -l < "$TMPLOG")

    echo "============================================"
    echo " nftables Firewall Log Summary"
    echo "============================================"
    echo ""

    echo "Total logged packets: $TOTAL_ENTRIES"
    echo ""

    if [[ "$TOTAL_ENTRIES" -eq 0 ]]; then
        log_info "No nftables log entries found in journal."
        log_info "Ensure your nftables rules include 'log prefix' directives."
        rm -f "$TMPLOG"
        return
    fi

    # Top source IPs
    echo "--- Top 10 Source IPs ---"
    { grep -oP 'SRC=\K[\d.]+' "$TMPLOG" | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No source IP data found"
    echo ""

    # Top destination ports
    echo "--- Top 10 Blocked Destination Ports ---"
    { grep -oP 'DPT=\K\d+' "$TMPLOG" | \
        sort | uniq -c | sort -rn | head -10; } || echo "  No port data found"
    echo ""

    # Inbound vs outbound breakdown
    echo "--- Direction Breakdown ---"
    local INPUT_COUNT OUTPUT_COUNT
    INPUT_COUNT=$(grep -c "input-drop" "$TMPLOG" 2>/dev/null || echo "0")
    OUTPUT_COUNT=$(grep -c "output-drop" "$TMPLOG" 2>/dev/null || echo "0")
    echo "  Inbound blocked:  $INPUT_COUNT"
    echo "  Outbound blocked: $OUTPUT_COUNT"
    echo ""

    # Protocol breakdown
    echo "--- Protocol Breakdown ---"
    { grep -oP 'PROTO=\K\w+' "$TMPLOG" | \
        sort | uniq -c | sort -rn; } || echo "  No protocol data found"
    echo ""

    # Recent blocked entries
    echo "--- Recent Blocked Packets (last 10) ---"
    tail -10 "$TMPLOG"
    echo ""

    rm -f "$TMPLOG"

    echo "============================================"
    log_success "Analysis complete"
    log_info "View full log: journalctl -k | grep nftables"
}

case "${1:-install}" in
    install) analyze ;;
    *) echo "Usage: $0 {install}"; exit 1 ;;
esac
