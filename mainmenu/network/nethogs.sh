#!/bin/bash
# ---
# name: "nethogs"
# description: "Monitor bandwidth usage per process in real-time"
# type: install
# root: true
# order: 16
# check_command: "which nethogs"
# tags: "network, bandwidth, per-process"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y nethogs
    echo "nethogs installed! Run with: sudo nethogs"
else
    apt-get remove -y nethogs && apt-get autoremove -y
fi
