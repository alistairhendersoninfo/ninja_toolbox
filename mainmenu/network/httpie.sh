#!/bin/bash
# ---
# name: "httpie"
# description: "User-friendly HTTP client with JSON support and syntax highlighting"
# type: install
# root: true
# order: 23
# check_command: "http --version"
# tags: "network, http, client"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y httpie
    echo "httpie installed! Run with: http <url>"
else
    apt-get remove -y httpie && apt-get autoremove -y
fi
