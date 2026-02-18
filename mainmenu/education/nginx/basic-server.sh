#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

REQUIRED_BINARY="nginx"
if ! command -v "$REQUIRED_BINARY" &>/dev/null; then
    log_error "$REQUIRED_BINARY is not installed. Install it first from the menu."
    exit 1
fi

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

run() {
    log_info "Nginx — Basic Server Block Generator"
    log_info "Generates a standard server block config with virtual host, document root,"
    log_info "index files, logging, and a deny rule for dotfiles."
    echo ""

    # --- Prompt for values ---------------------------------------------------
    read -rp "Enter FQDN (e.g. example.com): " FQDN
    if [[ -z "$FQDN" ]]; then
        log_error "FQDN is required."
        exit 1
    fi

    read -rp "Enter document root [/var/www/${FQDN}/html]: " DOC_ROOT
    DOC_ROOT="${DOC_ROOT:-/var/www/${FQDN}/html}"

    read -rp "Enter listen port [80]: " LISTEN_PORT
    LISTEN_PORT="${LISTEN_PORT:-80}"

    # --- Generate config -----------------------------------------------------
    log_step "Generating server block for ${FQDN}"
    echo ""

    CONFIG=$(cat <<NGINX
server {
    listen ${LISTEN_PORT};
    listen [::]:${LISTEN_PORT};

    server_name ${FQDN} www.${FQDN};
    root ${DOC_ROOT};

    index index.html index.htm;

    # Logging
    access_log /var/log/nginx/${FQDN}.access.log;
    error_log  /var/log/nginx/${FQDN}.error.log warn;

    # Main location
    location / {
        try_files \$uri \$uri/ =404;
    }

    # Deny access to dotfiles (e.g. .git, .env, .htaccess)
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff2?|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
}
NGINX
)

    echo "# ------------------------------------------------------------------"
    echo "# Nginx server block — ${FQDN}"
    echo "# ------------------------------------------------------------------"
    echo ""
    echo "$CONFIG"
    echo ""
    echo "# ------------------------------------------------------------------"

    # --- Optionally write to sites-available ---------------------------------
    DEST="/etc/nginx/sites-available/${FQDN}"
    echo ""
    read -rp "Write config to ${DEST}? (requires sudo) [y/N]: " WRITE_CHOICE
    if [[ "${WRITE_CHOICE,,}" == "y" ]]; then
        echo "$CONFIG" | sudo tee "$DEST" > /dev/null
        log_success "Config written to ${DEST}"
        echo ""
        log_info "To enable the site, run:"
        echo "  sudo ln -s ${DEST} /etc/nginx/sites-enabled/"
        echo "  sudo mkdir -p ${DOC_ROOT}"
        echo "  sudo nginx -t && sudo systemctl reload nginx"
    else
        log_info "Config not written. Copy and paste the output above as needed."
    fi

    echo ""
    log_success "Basic server block generation complete."
}

run
