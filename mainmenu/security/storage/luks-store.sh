#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="luks-store"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

VAULT_DIR="/opt/secure-store"
VAULT_IMG="$VAULT_DIR/vault.img"
VAULT_NAME="secure-vault"
MOUNT_POINT="/mnt/secure-store"
VAULT_SIZE_MB="${VAULT_SIZE_MB:-1024}"

install() {
    log_info "Creating LUKS-encrypted file-backed volume"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    # Check for cryptsetup
    if ! command -v cryptsetup &>/dev/null; then
        log_step "Installing cryptsetup..."
        pkg_update
        pkg_install cryptsetup
    fi

    if [[ -f "$VAULT_IMG" ]]; then
        log_error "Vault image already exists: $VAULT_IMG"
        log_info "Run '$0 uninstall' first to remove the existing vault."
        exit 1
    fi

    log_step "1. Creating vault directory..."
    mkdir -p "$VAULT_DIR"
    mkdir -p "$MOUNT_POINT"

    log_step "2. Creating sparse file (${VAULT_SIZE_MB}MB)..."
    dd if=/dev/zero of="$VAULT_IMG" bs=1M count=0 seek="$VAULT_SIZE_MB" status=progress

    log_step "3. Setting up LUKS encryption on vault image..."
    log_info "You will be prompted to set a passphrase for the encrypted volume."
    echo ""
    cryptsetup luksFormat --type luks2 --hash sha256 --key-size 512 "$VAULT_IMG"

    log_step "4. Opening LUKS volume..."
    log_info "Enter your passphrase to open the volume."
    cryptsetup luksOpen "$VAULT_IMG" "$VAULT_NAME"

    log_step "5. Creating ext4 filesystem..."
    mkfs.ext4 -L secure-store "/dev/mapper/$VAULT_NAME"

    log_step "6. Mounting volume..."
    mount "/dev/mapper/$VAULT_NAME" "$MOUNT_POINT"

    # Set restrictive permissions
    chmod 700 "$MOUNT_POINT"

    log_step "7. Adding to /etc/crypttab for persistence..."
    # Add crypttab entry (noauto so it requires manual passphrase on boot)
    if ! grep -q "$VAULT_NAME" /etc/crypttab 2>/dev/null; then
        echo "$VAULT_NAME  $VAULT_IMG  none  luks,noauto" >> /etc/crypttab
        log_info "Added $VAULT_NAME to /etc/crypttab (noauto — requires manual open)"
    else
        log_info "crypttab entry already exists"
    fi

    log_step "8. Adding to /etc/fstab for mount persistence..."
    if ! grep -q "$VAULT_NAME" /etc/fstab 2>/dev/null; then
        echo "/dev/mapper/$VAULT_NAME  $MOUNT_POINT  ext4  defaults,noauto  0  2" >> /etc/fstab
        log_info "Added $VAULT_NAME to /etc/fstab (noauto — mount after open)"
    else
        log_info "fstab entry already exists"
    fi

    echo ""
    log_success "LUKS encrypted volume created and mounted"
    echo ""
    log_info "Volume:     $VAULT_IMG (${VAULT_SIZE_MB}MB)"
    log_info "Mapped to:  /dev/mapper/$VAULT_NAME"
    log_info "Mounted at: $MOUNT_POINT"
    echo ""
    log_info "After reboot, manually open and mount:"
    log_info "  sudo cryptsetup luksOpen $VAULT_IMG $VAULT_NAME"
    log_info "  sudo mount /dev/mapper/$VAULT_NAME $MOUNT_POINT"
    echo ""
    log_info "To close and unmount:"
    log_info "  sudo umount $MOUNT_POINT"
    log_info "  sudo cryptsetup luksClose $VAULT_NAME"

    mark_installed true
}

uninstall() {
    log_info "Removing LUKS encrypted volume"
    require_root

    log_step "Unmounting volume..."
    umount "$MOUNT_POINT" 2>/dev/null || true

    log_step "Closing LUKS volume..."
    cryptsetup luksClose "$VAULT_NAME" 2>/dev/null || true

    log_step "Removing vault image..."
    rm -f "$VAULT_IMG"
    rmdir "$VAULT_DIR" 2>/dev/null || true
    rmdir "$MOUNT_POINT" 2>/dev/null || true

    log_step "Removing crypttab entry..."
    if [[ -f /etc/crypttab ]]; then
        sed -i "\|$VAULT_NAME|d" /etc/crypttab
    fi

    log_step "Removing fstab entry..."
    if [[ -f /etc/fstab ]]; then
        sed -i "\|$VAULT_NAME|d" /etc/fstab
    fi

    log_success "LUKS encrypted volume removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
