#!/bin/bash
# ---
# name: "glances"
# description: "Cross-platform system monitor with web interface support"
# type: install
# root: true
# order: 15
# check_command: "glances --version"
# tags: "monitoring, all-in-one, web"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y glances
    echo "glances installed! Run with: glances (or glances -w for web)"
else
    apt-get remove -y glances && apt-get autoremove -y
fi
