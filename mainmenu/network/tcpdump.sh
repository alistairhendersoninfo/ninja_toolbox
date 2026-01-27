#!/bin/bash
# ---
# name: "tcpdump"
# description: "Command-line packet analyzer for network troubleshooting"
# type: install
# root: true
# order: 12
# check_command: "tcpdump --version"
# tags: "network, packet, capture"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y tcpdump
    echo "tcpdump installed! Run with: sudo tcpdump -i <interface>"
else
    apt-get remove -y tcpdump && apt-get autoremove -y
fi
