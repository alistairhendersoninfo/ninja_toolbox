#!/bin/bash
# ---
# name: "mtr"
# description: "Network diagnostic combining ping and traceroute"
# type: install
# root: true
# order: 15
# check_command: "mtr --version"
# tags: "network, diagnostic, traceroute"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y mtr
    echo "mtr installed! Run with: mtr <host>"
else
    apt-get remove -y mtr && apt-get autoremove -y
fi
