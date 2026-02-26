#!/bin/bash
# Metadata lives in the companion .meta.yaml file (NOT inline).
# See: .docs/technical_manuals/os-modular-architecture.md for full reference.

#######################################
# RESET TIME SYNC
# Fix clock drift in UTM VM guests:
#   1. Prompt for current HH:MM
#   2. Hard-set system time
#   3. Install + configure chrony for aggressive VM clock correction
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"

source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Running: $SCRIPT_NAME"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    #######################################
    # STEP 1: Prompt for current time
    #######################################
    log_step "Step 1: Prompt for current time..."

    while true; do
        read -rp "Enter the current time (HH:MM, 24-hour): " USER_TIME
        if [[ "$USER_TIME" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            break
        fi
        echo "Invalid format. Please use HH:MM (e.g. 14:35)"
    done

    #######################################
    # STEP 2: Disable NTP and set timezone
    #######################################
    log_step "Step 2: Disabling NTP and setting timezone to Europe/London..."

    timedatectl set-ntp false
    systemctl stop systemd-timesyncd 2>/dev/null || true
    timedatectl set-timezone Europe/London

    #######################################
    # STEP 3: Hard-set system clock
    #######################################
    log_step "Step 3: Setting system clock to $(date +%F) ${USER_TIME}:00..."

    date -s "$(date +%F) ${USER_TIME}:00"
    hwclock --systohc

    #######################################
    # STEP 4: Refresh package lists
    #######################################
    log_step "Step 4: Refreshing package lists..."

    apt-get clean
    rm -rf /var/lib/apt/lists/*
    apt-get update
    apt-get -y upgrade

    #######################################
    # STEP 5: Install chrony
    #######################################
    log_step "Step 5: Installing chrony..."

    apt-get install -y chrony

    #######################################
    # STEP 6: Configure chrony for aggressive VM correction
    #######################################
    log_step "Step 6: Configuring chrony for aggressive VM clock correction..."

    CHRONY_CONF="/etc/chrony/chrony.conf"

    # Ensure makestep 0.1 -1 is set (replace existing makestep or append)
    if grep -q "^makestep" "$CHRONY_CONF"; then
        sed -i 's/^makestep.*/makestep 0.1 -1/' "$CHRONY_CONF"
    else
        echo "makestep 0.1 -1" >> "$CHRONY_CONF"
    fi

    # Ensure pool pool.ntp.org iburst is present
    if ! grep -q "^pool pool.ntp.org iburst" "$CHRONY_CONF"; then
        echo "pool pool.ntp.org iburst" >> "$CHRONY_CONF"
    fi

    #######################################
    # STEP 7: Switch from timesyncd to chrony
    #######################################
    log_step "Step 7: Disabling systemd-timesyncd, enabling chrony..."

    systemctl disable --now systemd-timesyncd 2>/dev/null || true

    # Enable chrony (service name varies by distro)
    if systemctl list-unit-files chrony.service &>/dev/null; then
        systemctl enable --now chrony
    else
        systemctl enable --now chronyd
    fi

    #######################################
    # STEP 8: Force immediate clock correction
    #######################################
    log_step "Step 8: Forcing immediate clock correction..."

    chronyc -a makestep

    #######################################
    # DONE: Print final status
    #######################################
    echo ""
    log_success "Complete: $SCRIPT_NAME"
    echo ""
    log_info "--- timedatectl status ---"
    timedatectl status
    echo ""
    log_info "--- chronyc tracking ---"
    chronyc tracking
    echo ""
    log_info "--- System time ---"
    date
    log_info "--- UTC time ---"
    date -u
}

# Uninstall is not applicable for this config script
uninstall() {
    log_info "This is a config/utility script - nothing to uninstall"
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
