#!/bin/bash
# ---
# name: "duf"
# description: "Modern disk usage utility with colorful output"
# type: install
# root: true
# order: 18
# check_command: "duf --version"
# tags: "monitoring, disk, modern"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y duf
    echo "duf installed! Run with: duf"
else
    apt-get remove -y duf && apt-get autoremove -y
fi
