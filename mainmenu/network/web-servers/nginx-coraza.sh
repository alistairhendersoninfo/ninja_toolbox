#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="nginx-coraza"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

CORAZA_CONF="/etc/nginx/modsecurity/coraza.conf"
CRS_DIR="/etc/nginx/modsecurity/coreruleset"

install() {
    log_info "Installing Nginx with Coraza WAF"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root
    pkg_update

    log_step "1. Installing Nginx and build dependencies..."
    pkg_install nginx libtool autoconf automake build-essential \
        libcurl4-openssl-dev libgeoip-dev liblmdb-dev \
        libpcre2-dev libyajl-dev pkgconf libxml2-dev git

    log_step "2. Installing libmodsecurity3..."
    pkg_install libmodsecurity3 libmodsecurity-dev

    log_step "3. Building Coraza Nginx connector..."
    local BUILD_DIR
    BUILD_DIR=$(mktemp -d)
    cd "$BUILD_DIR"

    # Get nginx version for module compatibility
    local NGINX_VER
    NGINX_VER=$(nginx -v 2>&1 | grep -oP '\d+\.\d+\.\d+')

    git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git
    wget -q "https://nginx.org/download/nginx-${NGINX_VER}.tar.gz"
    tar xzf "nginx-${NGINX_VER}.tar.gz"

    cd "nginx-${NGINX_VER}"
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx
    make modules

    cp objs/ngx_http_modsecurity_module.so /usr/lib/nginx/modules/
    rm -rf "$BUILD_DIR"

    log_step "4. Configuring ModSecurity module..."
    mkdir -p /etc/nginx/modsecurity

    # Load module in nginx
    if ! grep -q "modsecurity_module" /etc/nginx/modules-enabled/*.conf 2>/dev/null; then
        echo 'load_module modules/ngx_http_modsecurity_module.so;' > /etc/nginx/modules-enabled/50-mod-modsecurity.conf
    fi

    # Base modsecurity config
    cat > "$CORAZA_CONF" <<'MODSEC'
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog /var/log/nginx/modsec_audit.log
SecTmpDir /tmp/modsecurity/tmp
SecDataDir /tmp/modsecurity/data
MODSEC

    mkdir -p /tmp/modsecurity/tmp /tmp/modsecurity/data

    log_step "5. Installing OWASP Core Rule Set (CRS)..."
    if [[ -d "$CRS_DIR" ]]; then
        cd "$CRS_DIR" && git pull
    else
        git clone --depth 1 https://github.com/coreruleset/coreruleset.git "$CRS_DIR"
    fi
    cp "$CRS_DIR/crs-setup.conf.example" "$CRS_DIR/crs-setup.conf"

    # Include CRS in modsecurity config
    cat >> "$CORAZA_CONF" <<INCLUDE
Include $CRS_DIR/crs-setup.conf
Include $CRS_DIR/rules/*.conf
INCLUDE

    log_step "6. Testing nginx configuration..."
    nginx -t

    log_step "7. Restarting nginx..."
    systemctl restart nginx

    echo ""
    log_success "Nginx + Coraza WAF installed with OWASP CRS"
    log_info "Audit log: /var/log/nginx/modsec_audit.log"
    log_info "To enable per-site, add to server block:"
    log_info "  modsecurity on;"
    log_info "  modsecurity_rules_file $CORAZA_CONF;"
    mark_installed true
}

uninstall() {
    log_info "Removing Coraza WAF module"
    require_root

    rm -f /usr/lib/nginx/modules/ngx_http_modsecurity_module.so
    rm -f /etc/nginx/modules-enabled/50-mod-modsecurity.conf
    rm -rf /etc/nginx/modsecurity
    rm -rf /tmp/modsecurity

    nginx -t 2>/dev/null && systemctl restart nginx

    log_success "Coraza WAF module removed (nginx still installed)"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
