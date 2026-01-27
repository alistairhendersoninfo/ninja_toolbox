#!/bin/bash
# ---
# name: "neofetch"
# description: "Display system info with ASCII art logo"
# type: install
# root: true
# order: 16
# check_command: "neofetch --version"
# tags: "monitoring, info, display"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y neofetch
    echo "neofetch installed! Run with: neofetch"
else
    apt-get remove -y neofetch && apt-get autoremove -y
fi
