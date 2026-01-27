#!/bin/bash
# ---
# name: "netdiscover"
# description: "Active/passive network discovery using ARP requests"
# type: install
# root: true
# order: 18
# check_command: "which netdiscover"
# tags: "network, discovery, passive"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y netdiscover
    echo "netdiscover installed! Run with: sudo netdiscover"
else
    apt-get remove -y netdiscover && apt-get autoremove -y
fi
