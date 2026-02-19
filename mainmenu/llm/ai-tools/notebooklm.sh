#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

APP_NAME="Google NotebookLM"
APP_URL="https://notebooklm.google"
APP_DIR="$HOME/Applications"
APP_PATH="$APP_DIR/${APP_NAME}.app"
DESKTOP_FILE="$HOME/.local/share/applications/google-notebooklm.desktop"

install_macos() {
    log_step "Creating macOS app wrapper for ${APP_NAME}..."
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/Resources"

    # Create the launcher script
    cat > "$APP_PATH/Contents/MacOS/launch" <<'LAUNCHER'
#!/bin/bash
APP_URL="https://notebooklm.google"

# Prefer Chrome --app mode for standalone window experience
if [[ -d "/Applications/Google Chrome.app" ]]; then
    open -na "Google Chrome" --args --app="$APP_URL"
elif [[ -d "/Applications/Chromium.app" ]]; then
    open -na "Chromium" --args --app="$APP_URL"
elif [[ -d "/Applications/Microsoft Edge.app" ]]; then
    open -na "Microsoft Edge" --args --app="$APP_URL"
elif [[ -d "/Applications/Brave Browser.app" ]]; then
    open -na "Brave Browser" --args --app="$APP_URL"
else
    # Fallback to default browser
    open "$APP_URL"
fi
LAUNCHER
    chmod +x "$APP_PATH/Contents/MacOS/launch"

    # Create Info.plist
    cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.google.notebooklm.webapp</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>launch</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
</dict>
</plist>
PLIST

    log_success "${APP_NAME} app created at: $APP_PATH"
    echo ""
    echo "You can find it in ~/Applications or search Spotlight for '${APP_NAME}'"
    echo "The app opens NotebookLM in a standalone browser window"
    echo ""
}

install_linux() {
    log_step "Creating Linux desktop entry for ${APP_NAME}..."
    mkdir -p "$(dirname "$DESKTOP_FILE")"

    # Detect browser for --app mode
    local browser_exec="xdg-open"
    local browser_args=""
    if command -v google-chrome &>/dev/null; then
        browser_exec="google-chrome"
        browser_args="--app=${APP_URL}"
    elif command -v chromium-browser &>/dev/null; then
        browser_exec="chromium-browser"
        browser_args="--app=${APP_URL}"
    elif command -v chromium &>/dev/null; then
        browser_exec="chromium"
        browser_args="--app=${APP_URL}"
    elif command -v microsoft-edge &>/dev/null; then
        browser_exec="microsoft-edge"
        browser_args="--app=${APP_URL}"
    else
        browser_exec="xdg-open"
        browser_args="${APP_URL}"
    fi

    cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Name=${APP_NAME}
Comment=Google's AI-powered research and note-taking tool
Exec=${browser_exec} ${browser_args}
Type=Application
Categories=Network;Education;
StartupNotify=true
DESKTOP

    # Update desktop database if available
    { update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null; } || true

    log_success "${APP_NAME} desktop entry created"
    echo ""
    echo "You can find it in your application menu or launch with:"
    echo "  ${browser_exec} ${browser_args}"
    echo ""
}

install() {
    log_info "Installing ${APP_NAME}..."
    log_info "Log file: $LOG_FILE"
    echo ""

    case "${NT_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}" in
        macos|darwin)
            install_macos
            ;;
        *)
            install_linux
            ;;
    esac

    mark_installed true
}

uninstall() {
    log_info "Removing ${APP_NAME}..."

    if [[ -d "$APP_PATH" ]]; then
        rm -rf "$APP_PATH"
        log_info "Removed $APP_PATH"
    fi

    if [[ -f "$DESKTOP_FILE" ]]; then
        rm -f "$DESKTOP_FILE"
        { update-desktop-database "$(dirname "$DESKTOP_FILE")" 2>/dev/null; } || true
        log_info "Removed desktop entry"
    fi

    log_success "${APP_NAME} removed"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
