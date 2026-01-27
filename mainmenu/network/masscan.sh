#!/bin/bash
# ---
# name: "masscan"
# description: "Fastest port scanner - scan entire internet in minutes"
# type: install
# root: true
# order: 11
# check_command: "masscan --version"
# tags: "network, scanner, fast"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y masscan
    echo "masscan installed! Run with: sudo masscan <target> -p<ports>"
else
    apt-get remove -y masscan && apt-get autoremove -y
fi
