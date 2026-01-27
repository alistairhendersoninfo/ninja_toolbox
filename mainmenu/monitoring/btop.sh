#!/bin/bash
# ---
# name: "btop"
# description: "Modern resource monitor with beautiful graphs and themes"
# type: install
# root: true
# order: 11
# check_command: "btop --version"
# tags: "monitoring, modern, beautiful"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y btop
    echo "btop installed! Run with: btop"
else
    apt-get remove -y btop && apt-get autoremove -y
fi
