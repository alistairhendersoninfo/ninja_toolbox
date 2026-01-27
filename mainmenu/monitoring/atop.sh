#!/bin/bash
# ---
# name: "atop"
# description: "Advanced system monitor with logging and historical playback"
# type: install
# root: true
# order: 12
# check_command: "atop -V"
# tags: "monitoring, advanced, logging"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y atop
    echo "atop installed! Run with: atop"
else
    apt-get remove -y atop && apt-get autoremove -y
fi
