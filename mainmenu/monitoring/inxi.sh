#!/bin/bash
# ---
# name: "inxi"
# description: "Full system information tool - hardware, software, network"
# type: install
# root: true
# order: 19
# check_command: "inxi --version"
# tags: "monitoring, system, info"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y inxi
    echo "inxi installed! Run with: inxi -F"
else
    apt-get remove -y inxi && apt-get autoremove -y
fi
