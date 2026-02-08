#!/bin/bash
# ---
# name: "zenmap"
# description: "GUI front-end for Nmap network scanner"
# type: install
# root: true
# order: 11
# check_command: "zenmap --version"
# tags: "network, scanner, gui, nmap"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y zenmap
    echo "zenmap installed! Run with: zenmap"
else
    apt-get remove -y zenmap && apt-get autoremove -y
fi
