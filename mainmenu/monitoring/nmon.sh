#!/bin/bash
# ---
# name: "nmon"
# description: "Performance monitor with keyboard shortcuts for different views"
# type: install
# root: true
# order: 21
# check_command: "which nmon"
# tags: "monitoring, performance, interactive"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y nmon
    echo "nmon installed! Run with: nmon"
else
    apt-get remove -y nmon && apt-get autoremove -y
fi
