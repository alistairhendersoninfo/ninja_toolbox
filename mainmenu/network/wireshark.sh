#!/bin/bash
# ---
# name: "wireshark"
# description: "GUI and CLI packet analyzer for deep network inspection"
# type: install
# root: true
# order: 13
# check_command: "wireshark --version"
# tags: "network, packet, gui"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y wireshark tshark
    echo "wireshark installed! Run with: wireshark (GUI) or tshark (CLI)"
else
    apt-get remove -y wireshark tshark && apt-get autoremove -y
fi
