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
    log_info "Nginx — SSL/TLS Termination Generator"
    log_info "Generates a production-grade HTTPS config with TLS 1.2+, strong ciphers,"
    log_info "OCSP stapling, HSTS, session caching, and an HTTP->HTTPS redirect block."
    echo ""

    # --- Prompt for values ---------------------------------------------------
    read -rp "Enter FQDN (e.g. example.com): " FQDN
    if [[ -z "$FQDN" ]]; then
        log_error "FQDN is required."
        exit 1
    fi

    DEFAULT_CERT="/etc/letsencrypt/live/${FQDN}/fullchain.pem"
    read -rp "SSL certificate path [${DEFAULT_CERT}]: " SSL_CERT
    SSL_CERT="${SSL_CERT:-$DEFAULT_CERT}"

    DEFAULT_KEY="/etc/letsencrypt/live/${FQDN}/privkey.pem"
    read -rp "SSL private key path [${DEFAULT_KEY}]: " SSL_KEY
    SSL_KEY="${SSL_KEY:-$DEFAULT_KEY}"

    read -rp "Let's Encrypt email (for comments/renewal notices): " LE_EMAIL
    LE_EMAIL="${LE_EMAIL:-admin@${FQDN}}"

    echo ""
    log_step "Backend configuration"
    echo "  1) Serve static files from a document root"
    echo "  2) Reverse proxy to a backend service"
    read -rp "Choose [1/2]: " BACKEND_MODE
    BACKEND_MODE="${BACKEND_MODE:-1}"

    if [[ "$BACKEND_MODE" == "2" ]]; then
        read -rp "Enter backend address (e.g. 127.0.0.1:3000): " BACKEND
        if [[ -z "$BACKEND" ]]; then
            log_error "Backend address is required for proxy mode."
            exit 1
        fi
        LOCATION_BLOCK=$(cat <<'BLOCK'
        proxy_pass http://BACKEND_PLACEHOLDER;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";
BLOCK
)
        LOCATION_BLOCK="${LOCATION_BLOCK//BACKEND_PLACEHOLDER/$BACKEND}"
    else
        read -rp "Document root [/var/www/${FQDN}/html]: " DOC_ROOT
        DOC_ROOT="${DOC_ROOT:-/var/www/${FQDN}/html}"
        LOCATION_BLOCK="        try_files \$uri \$uri/ =404;"
    fi

    # --- Generate config -----------------------------------------------------
    log_step "Generating SSL termination config for ${FQDN}"
    echo ""

    # Build root directive only for static mode
    ROOT_LINE=""
    INDEX_LINE=""
    if [[ "$BACKEND_MODE" != "2" ]]; then
        ROOT_LINE="    root ${DOC_ROOT};"
        INDEX_LINE="    index index.html index.htm;"
    fi

    CONFIG=$(cat <<NGINX
# ------------------------------------------------------------------
# SSL/TLS termination for ${FQDN}
# Certificate: ${SSL_CERT}
# Key:         ${SSL_KEY}
# Let's Encrypt email: ${LE_EMAIL}
#
# To obtain a certificate:
#   sudo certbot certonly --nginx -d ${FQDN} -d www.${FQDN} -m ${LE_EMAIL} --agree-tos
# ------------------------------------------------------------------

# HTTP -> HTTPS redirect
server {
    listen 80;
    listen [::]:80;

    server_name ${FQDN} www.${FQDN};

    # Let's Encrypt challenge directory
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;

    server_name ${FQDN} www.${FQDN};
${ROOT_LINE:+
$ROOT_LINE}${INDEX_LINE:+
$INDEX_LINE}

    # --- TLS certificates ---------------------------------------------------
    ssl_certificate     ${SSL_CERT};
    ssl_certificate_key ${SSL_KEY};

    # --- Protocol & cipher settings -----------------------------------------
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # --- Session caching ----------------------------------------------------
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # --- OCSP stapling ------------------------------------------------------
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 5s;

    # --- Security headers ---------------------------------------------------
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    # --- Logging ------------------------------------------------------------
    access_log /var/log/nginx/${FQDN}.access.log;
    error_log  /var/log/nginx/${FQDN}.error.log warn;

    # --- Main location ------------------------------------------------------
    location / {
${LOCATION_BLOCK}
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

    echo "$CONFIG"
    echo ""

    # --- Optionally write to sites-available ---------------------------------
    DEST="/etc/nginx/sites-available/${FQDN}-ssl"
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
    log_success "SSL termination config generation complete."
}

run
