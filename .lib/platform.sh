#!/bin/bash
#######################################
# NinjaMenu Platform Library
# Source this file in every script for cross-platform support.
#
# Usage:
#   source "$MENU_ROOT/.lib/platform.sh"
#
# Provides:
#   Variables: NT_OS, NT_DISTRO, NT_ARCH, NT_HOMEBREW
#   Functions: pkg_install, pkg_remove, pkg_update, require_root,
#              require_linux, mark_installed, nt_sed_i,
#              log_info, log_success, log_warn, log_error, log_step
#######################################

# Guard against double-sourcing
[[ -n "${_NT_PLATFORM_LOADED:-}" ]] && return 0
_NT_PLATFORM_LOADED=1

#######################################
# COLORS
#######################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

#######################################
# LOGGING
#######################################
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

#######################################
# OS DETECTION
#######################################
NT_OS="unknown"
NT_DISTRO="unknown"
NT_ARCH="$(uname -m)"
NT_HOMEBREW=""

case "$(uname -s)" in
    Linux*)
        NT_OS="linux"
        if [[ -f /etc/os-release ]]; then
            # shellcheck source=/dev/null
            . /etc/os-release
            case "$ID" in
                debian|ubuntu|kali) NT_DISTRO="$ID" ;;
                *)                  NT_DISTRO="$ID" ;;
            esac
        fi
        ;;
    Darwin*)
        NT_OS="macos"
        NT_DISTRO="macos"
        if [[ "$NT_ARCH" == "arm64" ]]; then
            NT_HOMEBREW="/opt/homebrew"
        else
            NT_HOMEBREW="/usr/local"
        fi
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

#######################################
# PACKAGE NAME MAPPING (macOS overrides)
#
# Returns the macOS equivalent for a Linux package name.
# Return codes:
#   0 = mapped (check stdout for the brew package name)
#   1 = no mapping (use the original name as-is)
#   2 = not available on macOS (skip this package)
#
# Compatible with Bash 3.2 (macOS default).
#######################################
_pkg_map_macos() {
    case "$1" in
        # Cask installs (GUI apps)
        zenmap)         echo "--cask zenmap" ;;
        wireshark)      echo "--cask wireshark" ;;

        # Different package names
        net-tools)      echo "iproute2mac" ;;
        netcat-openbsd) echo "netcat" ;;
        xsltproc)       echo "libxslt" ;;
        dnsutils)       echo "bind" ;;
        iproute2)       echo "iproute2mac" ;;

        # Included in other packages on macOS (skip silently)
        python3-pip|python3-venv) return 2 ;;

        # Not available on macOS (skip with warning)
        whiptail|netdiscover|iotop|nmon|sysstat|nethogs) return 2 ;;

        # No mapping — use original name
        *)              return 1 ;;
    esac
    return 0
}

#######################################
# PACKAGE MANAGEMENT
#######################################

# pkg_update: refresh package index
pkg_update() {
    case "$NT_OS" in
        linux)  apt-get update -qq ;;
        macos)  brew update --quiet ;;
    esac
}

# pkg_install: install one or more packages
# Usage: pkg_install htop btop nmap
#        pkg_install zenmap  # auto-maps to 'brew install --cask zenmap' on macOS
pkg_install() {
    local pkg mapped rc
    for pkg in "$@"; do
        if [[ "$NT_OS" == "linux" ]]; then
            apt-get install -y "$pkg"
        elif [[ "$NT_OS" == "macos" ]]; then
            mapped=$(_pkg_map_macos "$pkg") && rc=0 || rc=$?
            if [[ $rc -eq 0 ]]; then
                # Mapped to a different brew package/cask name
                # shellcheck disable=SC2086
                brew install $mapped
            elif [[ $rc -eq 2 ]]; then
                log_warn "Package '$pkg' is not available on macOS — skipping"
                continue
            else
                # No mapping — use original name as-is
                brew install "$pkg"
            fi
        fi
    done
}

# pkg_remove: remove one or more packages
# Usage: pkg_remove htop btop
pkg_remove() {
    local pkg mapped rc
    for pkg in "$@"; do
        if [[ "$NT_OS" == "linux" ]]; then
            apt-get remove -y "$pkg"
        elif [[ "$NT_OS" == "macos" ]]; then
            mapped=$(_pkg_map_macos "$pkg") && rc=0 || rc=$?
            if [[ $rc -eq 0 ]]; then
                # shellcheck disable=SC2086
                brew uninstall $mapped 2>/dev/null || true
            elif [[ $rc -eq 2 ]]; then
                continue
            else
                brew uninstall "$pkg" 2>/dev/null || true
            fi
        fi
    done
}

#######################################
# PRIVILEGE HANDLING
#######################################

# require_root: OS-aware privilege check
# Linux: asserts running as root (EUID 0)
# macOS: asserts NOT running as root + checks Homebrew is available
require_root() {
    if [[ "$NT_OS" == "linux" ]]; then
        if [[ $EUID -ne 0 ]]; then
            log_error "This script must be run as root (use sudo)"
            exit 1
        fi
    elif [[ "$NT_OS" == "macos" ]]; then
        if [[ $EUID -eq 0 ]]; then
            log_error "Do not run this with sudo on macOS (Homebrew restriction)"
            exit 1
        fi
        if ! command -v brew &>/dev/null; then
            log_error "Homebrew is required on macOS. Install from https://brew.sh"
            exit 1
        fi
    fi
}

# require_linux: exit gracefully on non-Linux systems
# Usage: require_linux "XRDP requires Linux (Kali/Debian)"
require_linux() {
    if [[ "$NT_OS" != "linux" ]]; then
        log_warn "${1:-This script is Linux-only and cannot run on $NT_OS.}"
        exit 0
    fi
}

#######################################
# CROSS-PLATFORM UTILITIES
#######################################

# nt_sed_i: cross-platform in-place sed
# Usage: nt_sed_i 's/old/new/' file.txt
nt_sed_i() {
    if [[ "$NT_OS" == "macos" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# mark_installed: update YAML header installed field
# Usage: mark_installed true   (or: mark_installed false)
# Uses BASH_SOURCE[1] to find the calling script
mark_installed() {
    local status="${1:-true}"
    local script="${BASH_SOURCE[1]}"
    if [[ -z "$script" ]]; then
        log_warn "mark_installed: could not determine calling script"
        return 1
    fi
    nt_sed_i "s/^# installed: .*/# installed: $status/" "$script"
    log_info "Marked script as installed=$status"
}

# check_dependencies: verify required commands are available
# Usage: check_dependencies curl git wget
check_dependencies() {
    local deps=("$@")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        if [[ "$NT_OS" == "linux" ]]; then
            log_info "Install with: sudo apt-get install ${missing[*]}"
        elif [[ "$NT_OS" == "macos" ]]; then
            log_info "Install with: brew install ${missing[*]}"
        fi
        exit 1
    fi
}
