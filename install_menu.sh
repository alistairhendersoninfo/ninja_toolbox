#!/bin/bash
# ---
# name: "Install Menu System"
# description: "Installs menu system dependencies and creates ninjamenu command"
# version: "1.1.0"
# author: "System"
# root: true
# order: 0
# hidden: true
# installed: true
# dependencies: []
# tags:
#   - system
#   - core
# ---

#######################################
# MENU SYSTEM INSTALLER
# Installs: Python3, pip, textual, gum, whiptail, dialog
#######################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="$SCRIPT_DIR"

# Setup logging
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

#######################################
# OS DETECTION
#######################################
OS_TYPE="unknown"
ARCH="$(uname -m)"

case "$(uname -s)" in
    Linux*)  OS_TYPE="linux" ;;
    Darwin*) OS_TYPE="macos" ;;
    *)
        log_error "Unsupported operating system: $(uname -s)"
        exit 1
        ;;
esac

if [[ "$OS_TYPE" == "macos" ]]; then
    if [[ "$ARCH" == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
    BIN_DIR="$HOMEBREW_PREFIX/bin"
    REINSTALL_HINT="$MENU_ROOT/install_menu.sh"
else
    BIN_DIR="/usr/bin"
    REINSTALL_HINT="sudo $MENU_ROOT/install_menu.sh"
fi

echo ""
echo "=============================================="
echo "       MENU SYSTEM INSTALLER"
echo "=============================================="
echo ""
log_info "Detected OS: $OS_TYPE ($ARCH)"
log_info "Log file: $LOG_FILE"
echo ""

# Check privileges
if [[ "$OS_TYPE" == "linux" ]]; then
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
elif [[ "$OS_TYPE" == "macos" ]]; then
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this script with sudo on macOS"
        log_error "Homebrew must be run as a normal user"
        exit 1
    fi
    if ! command -v brew &>/dev/null; then
        log_warn "Homebrew is not installed"
        log_info "Install Homebrew from https://brew.sh"
        read -rp "Would you like to install Homebrew now? (y/n) " answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
        else
            log_error "Homebrew is required on macOS. Aborting."
            exit 1
        fi
    fi
    log_success "Homebrew found: $(brew --prefix)"
fi

#######################################
# STEP 1: System packages
#######################################
log_step "Installing system packages..."

if [[ "$OS_TYPE" == "linux" ]]; then
    apt-get update -qq

    apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        whiptail \
        dialog \
        jq \
        curl \
        wget \
        git \
        unzip \
        tree
elif [[ "$OS_TYPE" == "macos" ]]; then
    brew update --quiet

    # python3 includes pip and venv on macOS
    # whiptail not available via Homebrew; gum is the primary TUI
    brew install python3 dialog jq curl wget git unzip tree
fi

log_success "System packages installed"

#######################################
# STEP 2: Install Gum (Modern TUI)
#######################################
log_step "Installing Gum (Charm.sh)..."

# Check if gum is already installed
if command -v gum &>/dev/null; then
    log_info "Gum already installed: $(gum --version)"
else
    if [[ "$OS_TYPE" == "linux" ]]; then
        # Add Charm repository
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list
        apt-get update -qq
        apt-get install -y gum
    elif [[ "$OS_TYPE" == "macos" ]]; then
        brew install gum
    fi
    log_success "Gum installed"
fi

#######################################
# STEP 3: Python virtual environment
#######################################
log_step "Setting up Python virtual environment..."

VENV_DIR="$MENU_ROOT/.venv"

if [[ -d "$VENV_DIR" ]]; then
    log_info "Virtual environment already exists"
else
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created"
fi

# Activate and install packages
source "$VENV_DIR/bin/activate"

log_step "Installing Python packages..."

pip install --upgrade pip
pip install \
    textual \
    pyyaml \
    rich \
    typer \
    click

log_success "Python packages installed"

deactivate

#######################################
# STEP 4: Create launcher script
#######################################
log_step "Creating launcher script..."

mkdir -p "$MENU_ROOT/.app"

cat > "$MENU_ROOT/.app/menu" << 'LAUNCHER'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU_ROOT="$(dirname "$SCRIPT_DIR")"
source "$MENU_ROOT/.venv/bin/activate"
python3 "$SCRIPT_DIR/menu.py" "$@"
deactivate
LAUNCHER

chmod +x "$MENU_ROOT/.app/menu"

log_success "Launcher script created"

#######################################
# STEP 5: Set permissions
#######################################
log_step "Setting permissions..."

# Get the actual user (not root)
ACTUAL_USER="${SUDO_USER:-$USER}"

if [[ "$OS_TYPE" == "linux" ]]; then
    ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
    ACTUAL_GROUP="$ACTUAL_USER"
elif [[ "$OS_TYPE" == "macos" ]]; then
    ACTUAL_HOME=$(eval echo "~$ACTUAL_USER")
    ACTUAL_GROUP="staff"
fi

# Make all scripts executable
find "$MENU_ROOT" -name "*.sh" -exec chmod +x {} \;
chmod +x "$MENU_ROOT/.app/menu.py" 2>/dev/null || true
chmod +x "$MENU_ROOT/.app/menu"

# Set ownership to actual user
chown -R "$ACTUAL_USER:$ACTUAL_GROUP" "$MENU_ROOT"

log_success "Permissions set"

#######################################
# STEP 6: Create system-wide ninjamenu command
#######################################
log_step "Creating ninjamenu command in $BIN_DIR..."

if [[ "$OS_TYPE" == "macos" && ! -d "$BIN_DIR" ]]; then
    mkdir -p "$BIN_DIR"
fi

cat > "$BIN_DIR/ninjamenu" << NINJAMENU
#!/bin/bash
#
# NinjaMenu - Installer Menu System
# Launches the menu-installer TUI
#

MENU_ROOT="$MENU_ROOT"

# Check if menu exists
if [[ ! -f "\$MENU_ROOT/.app/menu.py" ]]; then
    echo "Error: Menu system not found at \$MENU_ROOT"
    echo "Please reinstall with: $REINSTALL_HINT"
    exit 1
fi

# Activate venv and run menu
source "\$MENU_ROOT/.venv/bin/activate"
python3 "\$MENU_ROOT/.app/menu.py" "\$@"
deactivate
NINJAMENU

chmod +x "$BIN_DIR/ninjamenu"

log_success "ninjamenu command installed at $BIN_DIR/ninjamenu"

#######################################
# STEP 7: Update installed status
#######################################
if [[ "$OS_TYPE" == "macos" ]]; then
    sed -i '' 's/^# installed: .*/# installed: true/' "${BASH_SOURCE[0]}"
else
    sed -i 's/^# installed: .*/# installed: true/' "${BASH_SOURCE[0]}"
fi

#######################################
# COMPLETE
#######################################
echo ""
echo "=============================================="
echo -e "${GREEN}MENU SYSTEM INSTALLATION COMPLETE${NC}"
echo "=============================================="
echo ""
echo "Installed components:"
echo "  - Python 3 with venv"
echo "  - Textual TUI framework"
echo "  - Gum (Charm.sh) for beautiful prompts"
if [[ "$OS_TYPE" == "linux" ]]; then
    echo "  - whiptail/dialog fallback"
else
    echo "  - dialog fallback"
fi
echo "  - PyYAML for header parsing"
echo "  - Rich for terminal formatting"
echo "  - ninjamenu command ($BIN_DIR/ninjamenu)"
echo ""
echo "To launch the menu, run:"
echo ""
echo -e "  ${CYAN}ninjamenu${NC}"
echo ""
echo "Or with options:"
echo "  ninjamenu --list          # List all scripts"
echo "  ninjamenu --submenu llm   # Start at submenu"
echo "  ninjamenu --tui gum       # Force TUI backend"
echo ""
