#!/bin/bash
# ---
# name: "sslscan"
# description: "Test SSL/TLS enabled services for security vulnerabilities"
# type: install
# root: true
# order: 24
# check_command: "sslscan --version"
# tags: "network, ssl, security"
# ---
ACTION="${1:-install}"
if [ "$ACTION" = "install" ]; then
    apt-get update && apt-get install -y sslscan
    echo "sslscan installed! Run with: sslscan <host>"
else
    apt-get remove -y sslscan && apt-get autoremove -y
fi
