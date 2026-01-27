#!/bin/bash
# ---
# name: "nmap"
# description: "Network scanner for port discovery and security auditing"
# type: install
# root: true
# order: 10
# check_command: "nmap --version"
# tags: "network, scanner, security"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y nmap
    echo "nmap installed! Run with: nmap <target>"
else
    apt-get remove -y nmap && apt-get autoremove -y
fi
