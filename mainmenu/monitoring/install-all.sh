#!/bin/bash
# ---
# name: "Install All Monitoring Tools"
# description: "Install all 12 monitoring tools in one go"
# type: install
# root: true
# order: 1
# check_command: "htop --version && btop --version && glances --version"
# tags: "monitoring, all, suite"
# ---
ACTION="${1:-install}"
PACKAGES=(htop atop btop iotop iftop dstat neofetch inxi lshw hwinfo ncdu duf smem sysstat nmon glances)

if [ "$ACTION" = "install" ]; then
    apt-get update
    for pkg in "${PACKAGES[@]}"; do
        echo "Installing $pkg..."
        apt-get install -y "$pkg" 2>/dev/null || echo "Failed: $pkg"
    done
    echo "All monitoring tools installed!"
else
    for pkg in "${PACKAGES[@]}"; do
        apt-get remove -y "$pkg" 2>/dev/null || true
    done
    apt-get autoremove -y
    echo "All monitoring tools removed."
fi
