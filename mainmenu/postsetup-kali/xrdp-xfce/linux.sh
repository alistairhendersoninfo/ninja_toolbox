#!/bin/bash
# Linux implementation — do NOT add YAML headers here (use meta.yaml)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"
exec > >(tee -a "$LOG_FILE") 2>&1

require_linux "XRDP requires Linux (Kali/Debian)"

install() {
    log_info "Installing XRDP with XFCE Desktop..."
    log_info "Log file: $LOG_FILE"
    echo ""

    log_step "Updating package list..."
    apt-get update -qq

    log_step "Installing XRDP and XFCE Desktop (this may take a while)..."
    apt-get install -y xrdp kali-desktop-xfce xfce4 xfce4-goodies

    log_step "Enabling XRDP service..."
    systemctl enable xrdp

    log_step "Configuring user session..."
    # Create user .xsession for XFCE
    echo "startxfce4" > ~/.xsession
    chmod +x ~/.xsession
    cp ~/.xsession /etc/skel/.xsession
    chmod +x /etc/skel/.xsession

    log_step "Configuring XRDP startwm.sh..."
    # Replace /etc/xrdp/startwm.sh
    cat > /etc/xrdp/startwm.sh << 'STARTWM'
#!/bin/bash
unset DBUS_SESSION_ADDRESS
unset XDG_RUNTIME_DIR

export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

exec startxfce4
STARTWM
    chmod +x /etc/xrdp/startwm.sh

    log_step "Configuring X11 wrapper..."
    # Allow Xwrapper non-console access
    if [[ -f /etc/X11/Xwrapper.config ]]; then
        nt_sed_i 's/^allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
    else
        echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
    fi

    log_step "Adding xrdp user to ssl-cert group..."
    usermod -a -G ssl-cert xrdp

    log_step "Setting graphical target as default..."
    systemctl set-default graphical.target

    log_step "Applying Proxmox DRI fixes..."
    # Patch XRDP xorg.conf to disable DRI (Proxmox fix)
    if [[ -f /etc/X11/xrdp/xorg.conf ]]; then
        nt_sed_i 's|Option "DRMDevice" "/dev/dri/renderD128"|Option "DRMDevice" ""|' /etc/X11/xrdp/xorg.conf 2>/dev/null || true
        nt_sed_i 's|Option "DRI3" "1"|Option "DRI3" "0"|' /etc/X11/xrdp/xorg.conf 2>/dev/null || true
    fi

    log_step "Restarting XRDP services..."
    systemctl restart xrdp xrdp-sesman

    echo ""
    log_success "XRDP with XFCE installed successfully!"
    echo ""
    echo "Connection details:"
    echo "  - Port: 3389 (default RDP port)"
    echo "  - Use any RDP client (Windows Remote Desktop, Remmina, etc.)"
    echo "  - Login with your system username and password"
    echo ""
    echo "To connect from Windows:"
    echo "  mstsc /v:$(hostname -I | awk '{print $1}')"
    echo ""

    read -p "Reboot now to complete installation? (y/N): " reboot_confirm
    if [[ "$reboot_confirm" == "y" || "$reboot_confirm" == "Y" ]]; then
        mark_installed true
        log_info "Rebooting..."
        reboot
    else
        log_info "Please reboot manually when ready"
    fi

    mark_installed true
}

uninstall() {
    log_info "Removing XRDP..."

    systemctl stop xrdp xrdp-sesman 2>/dev/null || true
    systemctl disable xrdp 2>/dev/null || true

    apt-get remove -y xrdp
    apt-get autoremove -y

    rm -f ~/.xsession
    rm -f /etc/skel/.xsession

    log_success "XRDP removed (XFCE desktop kept)"
    log_info "To remove XFCE desktop: apt remove kali-desktop-xfce xfce4"

    mark_installed false
}

ACTION="${1:-install}"
case "$ACTION" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
