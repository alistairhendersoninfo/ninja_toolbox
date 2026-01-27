#!/bin/bash
# ---
# name: "vnstat"
# description: "Network traffic monitor with daily/monthly statistics"
# type: install
# root: true
# order: 21
# check_command: "vnstat --version"
# tags: "network, traffic, statistics"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y vnstat
    systemctl enable vnstat 2>/dev/null || true
    echo "vnstat installed! Run with: vnstat"
else
    apt-get remove -y vnstat && apt-get autoremove -y
fi
