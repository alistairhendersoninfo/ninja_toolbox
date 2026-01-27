#!/bin/bash
# ---
# name: "iftop"
# description: "Display bandwidth usage per network connection"
# type: install
# root: true
# order: 14
# check_command: "which iftop"
# tags: "monitoring, network, bandwidth"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y iftop
    echo "iftop installed! Run with: sudo iftop"
else
    apt-get remove -y iftop && apt-get autoremove -y
fi
