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
    log_info "Nginx — Security Headers Snippet Generator"
    log_info "Generates a reusable snippet with industry-standard security headers."
    log_info "Include this file from any server block: include /etc/nginx/snippets/security-headers.conf;"
    echo ""

    # --- Prompt for values ---------------------------------------------------
    read -rp "Enter FQDN (e.g. example.com): " FQDN
    if [[ -z "$FQDN" ]]; then
        log_error "FQDN is required."
        exit 1
    fi

    echo ""
    log_step "Content-Security-Policy level"
    echo "  basic  — allows inline styles, images from anywhere, scripts from self"
    echo "  strict — no inline, no eval, only same-origin resources"
    read -rp "Choose CSP level [basic/strict]: " CSP_LEVEL
    CSP_LEVEL="${CSP_LEVEL:-basic}"

    if [[ "$CSP_LEVEL" == "strict" ]]; then
        CSP_VALUE="default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self'; font-src 'self'; connect-src 'self'; frame-ancestors 'none'; form-action 'self'; base-uri 'self'; object-src 'none'"
    else
        CSP_VALUE="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' https: data:; connect-src 'self'; frame-ancestors 'self'; form-action 'self'; base-uri 'self'; object-src 'none'"
    fi

    # --- Generate config -----------------------------------------------------
    log_step "Generating security headers snippet (${CSP_LEVEL} CSP)"
    echo ""

    CONFIG=$(cat <<NGINX
# ------------------------------------------------------------------
# Security Headers Snippet — ${FQDN}
# CSP level: ${CSP_LEVEL}
#
# Usage: include this file from your server block:
#   include /etc/nginx/snippets/security-headers.conf;
#
# Test your headers: https://securityheaders.com/?q=${FQDN}
# ------------------------------------------------------------------

# Prevent the site from being embedded in iframes (clickjacking protection)
add_header X-Frame-Options "SAMEORIGIN" always;

# Stop browsers from MIME-type sniffing (prevents MIME confusion attacks)
add_header X-Content-Type-Options "nosniff" always;

# Legacy XSS filter — modern browsers use CSP instead, but this helps older ones
add_header X-XSS-Protection "1; mode=block" always;

# Control how much referrer information is sent with requests
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Content Security Policy — controls which resources the browser may load
add_header Content-Security-Policy "${CSP_VALUE}" always;

# HTTP Strict Transport Security — force HTTPS for 2 years, include subdomains
# WARNING: Only enable preload once you are certain ALL subdomains support HTTPS
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# Permissions Policy — restrict browser features your site does not need
add_header Permissions-Policy "accelerometer=(), autoplay=(), camera=(), cross-origin-isolated=(), display-capture=(), encrypted-media=(), fullscreen=(self), geolocation=(), gyroscope=(), keyboard-map=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(), screen-wake-lock=(), sync-xhr=(self), usb=(), xr-spatial-tracking=()" always;

# Prevent search engines from indexing internal/staging sites (remove for production)
# add_header X-Robots-Tag "noindex, nofollow" always;

# Cross-Origin policies — uncomment if your site serves cross-origin content
# add_header Cross-Origin-Embedder-Policy "require-corp" always;
# add_header Cross-Origin-Opener-Policy "same-origin" always;
# add_header Cross-Origin-Resource-Policy "same-origin" always;
NGINX
)

    echo "$CONFIG"
    echo ""

    # --- Example server block showing include --------------------------------
    echo "# ------------------------------------------------------------------"
    echo "# Example: using this snippet in a server block"
    echo "# ------------------------------------------------------------------"
    echo ""
    cat <<EXAMPLE
server {
    listen 443 ssl;
    server_name ${FQDN};

    # ... SSL config ...

    include /etc/nginx/snippets/security-headers.conf;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EXAMPLE
    echo ""

    # --- Optionally write to snippets ----------------------------------------
    DEST="/etc/nginx/snippets/security-headers.conf"
    echo ""
    read -rp "Write snippet to ${DEST}? (requires sudo) [y/N]: " WRITE_CHOICE
    if [[ "${WRITE_CHOICE,,}" == "y" ]]; then
        echo "$CONFIG" | sudo tee "$DEST" > /dev/null
        log_success "Snippet written to ${DEST}"
        echo ""
        log_info "Add this line inside each server block that should use these headers:"
        echo "  include /etc/nginx/snippets/security-headers.conf;"
        echo ""
        echo "  sudo nginx -t && sudo systemctl reload nginx"
    else
        log_info "Snippet not written. Copy and paste the output above as needed."
    fi

    echo ""
    log_success "Security headers snippet generation complete."
}

run
