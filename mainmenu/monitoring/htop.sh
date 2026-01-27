#!/bin/bash
# ---
# name: "htop"
# description: "Interactive process viewer with color display and mouse support"
# type: install
# root: true
# order: 10
# check_command: "htop --version"
# tags: "monitoring, process, interactive"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y htop
    echo "htop installed! Run with: htop"
else
    apt-get remove -y htop && apt-get autoremove -y
fi
