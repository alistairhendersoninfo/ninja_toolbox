#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "menu.py" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

ACTION="${1:-install}"
PACKAGES=(net-tools mtr whois nmap masscan arp-scan netdiscover tcpdump wireshark nethogs vnstat netcat-openbsd socat curl wget httpie sslscan)

if [ "$ACTION" = "install" ]; then
    require_root
    pkg_update
    for pkg in "${PACKAGES[@]}"; do
        log_info "Installing $pkg..."
        pkg_install "$pkg" 2>/dev/null || log_warn "Failed: $pkg"
    done
    log_success "All network tools installed!"
else
    require_root
    PRESERVE=(net-tools curl wget)
    for pkg in "${PACKAGES[@]}"; do
        skip=false
        for p in "${PRESERVE[@]}"; do
            [[ "$pkg" == "$p" ]] && skip=true && break
        done
        $skip && continue
        pkg_remove "$pkg" 2>/dev/null || true
    done
    log_success "Network tools removed (core utilities preserved)."
fi
