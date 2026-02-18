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
    log_info "Nginx — Reverse Proxy Generator"
    log_info "Generates a reverse-proxy config with standard proxy headers,"
    log_info "WebSocket upgrade support, connection keep-alive, and buffering tuning."
    echo ""

    # --- Prompt for values ---------------------------------------------------
    read -rp "Enter FQDN (e.g. app.example.com): " FQDN
    if [[ -z "$FQDN" ]]; then
        log_error "FQDN is required."
        exit 1
    fi

    read -rp "Enter backend address (e.g. 127.0.0.1:3000): " BACKEND
    if [[ -z "$BACKEND" ]]; then
        log_error "Backend address is required."
        exit 1
    fi

    read -rp "Enter listen port [80]: " LISTEN_PORT
    LISTEN_PORT="${LISTEN_PORT:-80}"

    # --- Generate config -----------------------------------------------------
    log_step "Generating reverse proxy config for ${FQDN} -> ${BACKEND}"
    echo ""

    CONFIG=$(cat <<NGINX
upstream backend_${FQDN//[.-]/_} {
    server ${BACKEND};

    # Add more servers for load balancing:
    # server 127.0.0.1:3001;
    # server 127.0.0.1:3002;

    keepalive 32;
}

server {
    listen ${LISTEN_PORT};
    listen [::]:${LISTEN_PORT};

    server_name ${FQDN};

    # Logging
    access_log /var/log/nginx/${FQDN}.access.log;
    error_log  /var/log/nginx/${FQDN}.error.log warn;

    # Max upload size — adjust as needed
    client_max_body_size 50m;

    location / {
        proxy_pass http://backend_${FQDN//[.-]/_};

        # Standard proxy headers
        proxy_set_header Host              \$host;
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host  \$host;
        proxy_set_header X-Forwarded-Port  \$server_port;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 16k;
        proxy_buffers 4 64k;
        proxy_busy_buffers_size 128k;
    }

    # Health check endpoint (optional — adjust to your app)
    location /health {
        proxy_pass http://backend_${FQDN//[.-]/_}/health;
        access_log off;
    }

    # Deny dotfiles
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX
)

    echo "# ------------------------------------------------------------------"
    echo "# Nginx reverse proxy — ${FQDN} -> ${BACKEND}"
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
        echo "  sudo nginx -t && sudo systemctl reload nginx"
    else
        log_info "Config not written. Copy and paste the output above as needed."
    fi

    echo ""
    log_success "Reverse proxy generation complete."
}

run
