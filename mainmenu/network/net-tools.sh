#!/bin/bash
# ---
# name: "net-tools (netstat, ifconfig)"
# description: "Classic network utilities - netstat, ifconfig, route, arp"
# type: install
# root: true
# order: 19
# check_command: "netstat --version"
# tags: "network, legacy, utilities"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y net-tools
    echo "net-tools installed! Run with: netstat, ifconfig, route"
else
    apt-get remove -y net-tools && apt-get autoremove -y
fi
