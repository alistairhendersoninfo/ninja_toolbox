#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="postgresql"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

install() {
    log_info "Installing PostgreSQL"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    log_step "1. Installing PostgreSQL packages..."
    pkg_update
    pkg_install postgresql postgresql-client

    log_step "2. Starting and enabling PostgreSQL service..."
    systemctl enable --now postgresql

    log_step "3. Waiting for PostgreSQL to be ready..."
    local retries=0
    while ! su - postgres -c "pg_isready" &>/dev/null; do
        retries=$((retries + 1))
        if [[ $retries -ge 30 ]]; then
            log_error "PostgreSQL did not become ready in time"
            exit 1
        fi
        sleep 1
    done

    log_step "4. Creating default database and user..."
    # Prompt for credentials or use defaults
    DB_USER="ninja_user"
    DB_NAME="ninja_db"
    DB_PASS=""

    if [[ -t 0 ]]; then
        read -rp "Database username [${DB_USER}]: " input_user
        DB_USER="${input_user:-${DB_USER}}"
        read -rp "Database name [${DB_NAME}]: " input_db
        DB_NAME="${input_db:-${DB_NAME}}"
        read -rsp "Password (leave empty to generate): " input_pass
        echo ""
        DB_PASS="${input_pass}"
    fi

    if [[ -z "${DB_PASS}" ]]; then
        DB_PASS=$(openssl rand -hex 16)
        log_info "Generated password: ${DB_PASS}"
    fi

    # Create user and database (ignore errors if they already exist)
    su - postgres -c "psql -v ON_ERROR_STOP=0" <<EOSQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
        CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASS}';
    ELSE
        ALTER ROLE ${DB_USER} WITH PASSWORD '${DB_PASS}';
    END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}');
EOSQL

    # Create the database separately (CREATE DATABASE cannot run inside a transaction block via DO)
    su - postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname = '${DB_NAME}'\"" | \
        { grep -q 1 || su - postgres -c "createdb -O ${DB_USER} ${DB_NAME}"; }

    log_step "5. Verifying installation..."
    psql --version
    systemctl is-active postgresql

    echo ""
    log_success "PostgreSQL installed and running"
    log_info "User:     ${DB_USER}"
    log_info "Database: ${DB_NAME}"
    log_info "Connect:  psql -U ${DB_USER} -d ${DB_NAME} -h localhost"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling PostgreSQL"
    require_root

    systemctl stop postgresql 2>/dev/null || true
    systemctl disable postgresql 2>/dev/null || true
    pkg_remove postgresql postgresql-client
    apt-get autoremove -y 2>/dev/null || true

    log_info "Data directory preserved at /var/lib/postgresql/. Remove manually if desired."
    log_success "PostgreSQL uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
