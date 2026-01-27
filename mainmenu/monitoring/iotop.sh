#!/bin/bash
# ---
# name: "iotop"
# description: "Monitor disk I/O usage by process in real-time"
# type: install
# root: true
# order: 13
# check_command: "iotop --version"
# tags: "monitoring, io, disk"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y iotop
    echo "iotop installed! Run with: sudo iotop"
else
    apt-get remove -y iotop && apt-get autoremove -y
fi
