#!/bin/bash
# ---
# name: "arp-scan"
# description: "Discover hosts on local network using ARP"
# type: install
# root: true
# order: 17
# check_command: "arp-scan --version"
# tags: "network, discovery, arp"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y arp-scan
    echo "arp-scan installed! Run with: sudo arp-scan -l"
else
    apt-get remove -y arp-scan && apt-get autoremove -y
fi
