#!/bin/bash
# ---
# name: "netcat (nc)"
# description: "TCP/UDP Swiss Army knife - read/write network connections"
# type: install
# root: true
# order: 14
# check_command: "nc -h"
# tags: "network, connection, swiss-army"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y netcat-openbsd
    echo "netcat installed! Run with: nc <host> <port>"
else
    apt-get remove -y netcat-openbsd && apt-get autoremove -y
fi
