#!/bin/bash
# ---
# name: "sysstat (sar, iostat)"
# description: "System performance tools for CPU, memory, I/O statistics"
# type: install
# root: true
# order: 20
# check_command: "sar -V"
# tags: "monitoring, performance, statistics"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y sysstat
    echo "sysstat installed! Run with: sar, iostat, mpstat"
else
    apt-get remove -y sysstat && apt-get autoremove -y
fi
