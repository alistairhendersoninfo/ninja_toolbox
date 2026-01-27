#!/bin/bash
# ---
# name: "ncdu"
# description: "NCurses disk usage analyzer - find large files interactively"
# type: install
# root: true
# order: 17
# check_command: "ncdu --version"
# tags: "monitoring, disk, usage"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y ncdu
    echo "ncdu installed! Run with: ncdu /"
else
    apt-get remove -y ncdu && apt-get autoremove -y
fi
