#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="nftables"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

NFTABLES_CONF="/etc/nftables.conf"
NFTABLES_BACKUP="/etc/nftables.conf.bak.$(date +%Y%m%d_%H%M%S)"

install() {
    log_info "Installing nftables with deny-all + SSH-only ruleset"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing nftables..."
    pkg_install nftables

    log_step "2. Backing up existing nftables configuration..."
    if [[ -f "$NFTABLES_CONF" ]]; then
        cp "$NFTABLES_CONF" "$NFTABLES_BACKUP"
        log_info "Backup saved to $NFTABLES_BACKUP"
    else
        log_info "No existing nftables.conf found, skipping backup"
    fi

    log_step "3. Writing deny-all + allow-SSH ruleset..."
    cat > "$NFTABLES_CONF" <<'NFT'
#!/usr/sbin/nft -f

flush ruleset

table inet filter {

    chain input {
        type filter hook input priority 0; policy drop;

        # Allow loopback traffic
        iif "lo" accept

        # Allow established and related connections
        ct state established,related accept

        # Allow SSH from any source
        tcp dport 22 accept

        # Log and drop everything else
        log prefix "nftables-input-drop: " counter drop
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy drop;

        # Allow loopback traffic
        oif "lo" accept

        # Allow established and related connections
        ct state established,related accept

        # Allow DNS queries (UDP and TCP)
        tcp dport 53 accept
        udp dport 53 accept

        # Allow HTTP outbound
        tcp dport 80 accept

        # Allow HTTPS outbound
        tcp dport 443 accept

        # Allow NTP outbound
        udp dport 123 accept

        # Log and drop everything else
        log prefix "nftables-output-drop: " counter drop
    }
}
NFT

    log_step "4. Enabling and starting nftables service..."
    systemctl enable --now nftables

    log_step "5. Verifying ruleset..."
    echo ""
    nft list ruleset
    echo ""

    log_success "nftables installed with deny-all + SSH-only ruleset"
    log_info "Inbound: only SSH (tcp/22) and established connections allowed"
    log_info "Outbound: only DNS, HTTP, HTTPS, NTP and established connections allowed"
    log_info "Backup: $NFTABLES_BACKUP"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling nftables"
    require_root

    log_step "Stopping nftables service..."
    systemctl stop nftables 2>/dev/null || true
    systemctl disable nftables 2>/dev/null || true

    log_step "Restoring backup configuration..."
    # Find the most recent backup
    local LATEST_BACKUP
    LATEST_BACKUP=$(ls -t /etc/nftables.conf.bak.* 2>/dev/null | head -1 || true)
    if [[ -n "$LATEST_BACKUP" ]]; then
        cp "$LATEST_BACKUP" "$NFTABLES_CONF"
        log_info "Restored from $LATEST_BACKUP"
    else
        log_info "No backup found, removing nftables.conf"
        rm -f "$NFTABLES_CONF"
    fi

    log_step "Removing nftables package..."
    pkg_remove nftables
    apt-get autoremove -y 2>/dev/null || true

    log_success "nftables uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
