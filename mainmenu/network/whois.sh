#!/bin/bash
# ---
# name: "whois"
# description: "Query domain registration and IP ownership information"
# type: install
# root: true
# order: 22
# check_command: "whois --version"
# tags: "network, dns, lookup"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y whois
    echo "whois installed! Run with: whois <domain>"
else
    apt-get remove -y whois && apt-get autoremove -y
fi
