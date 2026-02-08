#!/bin/bash
# ---
# name: "nmap-unleashed"
# description: "Enhanced Nmap wrapper with automated scanning and reporting"
# type: install
# root: false
# order: 12
# check_command: "nu --help"
# tags: "network, scanner, nmap, automation"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    # Ensure dependencies are present
    apt-get update && apt-get install -y xsltproc pipx
    pipx ensurepath
    pipx install "git+https://github.com/Sharkeonix/nmap-unleashed.git"
    echo "nmap-unleashed installed! Run with: nu --help"
    echo "NOTE: Open a new terminal if 'nu' is not found (pipx PATH update)."
else
    pipx uninstall nmap-unleashed
fi
