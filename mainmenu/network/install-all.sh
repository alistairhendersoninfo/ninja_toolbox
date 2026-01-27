#!/bin/bash
# ---
# name: "Install All Network Tools"
# description: "Install all 15 network tools in one go"
# type: install
# root: true
# order: 1
# check_command: "nmap --version && tcpdump --version"
# tags: "network, all, suite"
# ---
ACTION="${1:-install}"
PACKAGES=(net-tools iproute2 mtr traceroute dnsutils whois nmap masscan arp-scan netdiscover tcpdump wireshark tshark ngrep iftop nethogs bmon vnstat netcat-openbsd socat telnet curl wget httpie openssl sslscan)

if [ "$ACTION" = "install" ]; then
    apt-get update
    for pkg in "${PACKAGES[@]}"; do
        echo "Installing $pkg..."
        apt-get install -y "$pkg" 2>/dev/null || echo "Failed: $pkg"
    done
    echo "All network tools installed!"
else
    PRESERVE=(net-tools iproute2 curl wget openssl dnsutils)
    for pkg in "${PACKAGES[@]}"; do
        [[ " ${PRESERVE[*]} " =~ " ${pkg} " ]] && continue
        apt-get remove -y "$pkg" 2>/dev/null || true
    done
    apt-get autoremove -y
fi
