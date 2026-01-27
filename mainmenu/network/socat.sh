#!/bin/bash
# ---
# name: "socat"
# description: "Multipurpose relay for bidirectional data transfer"
# type: install
# root: true
# order: 20
# check_command: "socat -V"
# tags: "network, relay, multipurpose"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y socat
    echo "socat installed! Run with: socat"
else
    apt-get remove -y socat && apt-get autoremove -y
fi
