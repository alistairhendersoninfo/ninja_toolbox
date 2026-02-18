#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="wazuh"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"
LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/${SCRIPT_NAME}"

install() {
    log_info "Installing ${SCRIPT_NAME}"
    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    mkdir -p "${SERVICE_DIR}"/{data,logs,config}
    mkdir -p "${SERVICE_DIR}/data/ossec" "${SERVICE_DIR}/data/indexer" "${SERVICE_DIR}/data/dashboard"
    mkdir -p "${SERVICE_DIR}/logs/ossec"
    mkdir -p "${SERVICE_DIR}/config/ossec" "${SERVICE_DIR}/config/dashboard"

    # Generate SSL certificates directory
    mkdir -p "${SERVICE_DIR}/config/certs"

    # Generate self-signed certificates for inter-component communication
    log_step "Generating self-signed certificates..."
    openssl req -x509 -batch -nodes -days 3650 -newkey rsa:2048 \
        -keyout "${SERVICE_DIR}/config/certs/root-ca-key.pem" \
        -out "${SERVICE_DIR}/config/certs/root-ca.pem" \
        -subj "/C=US/ST=State/L=City/O=Wazuh/CN=wazuh-root-ca" 2>/dev/null

    for CERT_NAME in indexer manager dashboard admin; do
        openssl req -new -nodes -newkey rsa:2048 \
            -keyout "${SERVICE_DIR}/config/certs/${CERT_NAME}-key.pem" \
            -out "${SERVICE_DIR}/config/certs/${CERT_NAME}.csr" \
            -subj "/C=US/ST=State/L=City/O=Wazuh/CN=${CERT_NAME}" 2>/dev/null
        openssl x509 -req -days 3650 \
            -in "${SERVICE_DIR}/config/certs/${CERT_NAME}.csr" \
            -CA "${SERVICE_DIR}/config/certs/root-ca.pem" \
            -CAkey "${SERVICE_DIR}/config/certs/root-ca-key.pem" \
            -CAcreateserial \
            -out "${SERVICE_DIR}/config/certs/${CERT_NAME}.pem" 2>/dev/null
        rm -f "${SERVICE_DIR}/config/certs/${CERT_NAME}.csr"
    done
    chmod 400 "${SERVICE_DIR}/config/certs/"*-key.pem

    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  wazuh-manager:
    image: wazuh/wazuh-manager:4.8.2
    container_name: wazuh-manager
    hostname: wazuh-manager
    restart: unless-stopped
    ports:
      - "1514:1514"
      - "1515:1515"
      - "55000:55000"
    volumes:
      - ./data/ossec:/var/ossec/data
      - ./logs/ossec:/var/ossec/logs
      - ./config/ossec:/var/ossec/etc
      - ./config/certs/manager.pem:/etc/ssl/manager.pem:ro
      - ./config/certs/manager-key.pem:/etc/ssl/manager-key.pem:ro
      - ./config/certs/root-ca.pem:/etc/ssl/root-ca.pem:ro
    environment:
      INDEXER_URL: https://wazuh-indexer:9200
      INDEXER_USERNAME: admin
      INDEXER_PASSWORD: SecretPassword
      FILEBEAT_SSL_VERIFICATION_MODE: full
      SSL_CERTIFICATE_AUTHORITIES: /etc/ssl/root-ca.pem
      SSL_CERTIFICATE: /etc/ssl/manager.pem
      SSL_KEY: /etc/ssl/manager-key.pem
      API_USERNAME: wazuh-wui
      API_PASSWORD: MyS3cr37P450r.*-
    networks:
      - wazuh-net

  wazuh-indexer:
    image: wazuh/wazuh-indexer:4.8.2
    container_name: wazuh-indexer
    hostname: wazuh-indexer
    restart: unless-stopped
    ports:
      - "9200:9200"
    volumes:
      - ./data/indexer:/var/lib/wazuh-indexer
      - ./config/certs/indexer.pem:/usr/share/wazuh-indexer/certs/indexer.pem:ro
      - ./config/certs/indexer-key.pem:/usr/share/wazuh-indexer/certs/indexer-key.pem:ro
      - ./config/certs/root-ca.pem:/usr/share/wazuh-indexer/certs/root-ca.pem:ro
      - ./config/certs/admin.pem:/usr/share/wazuh-indexer/certs/admin.pem:ro
      - ./config/certs/admin-key.pem:/usr/share/wazuh-indexer/certs/admin-key.pem:ro
    environment:
      OPENSEARCH_JAVA_OPTS: "-Xms1g -Xmx1g"
      bootstrap.memory_lock: "true"
      discovery.type: single-node
      plugins.security.ssl.transport.pemcert_filepath: certs/indexer.pem
      plugins.security.ssl.transport.pemkey_filepath: certs/indexer-key.pem
      plugins.security.ssl.transport.pemtrustedcas_filepath: certs/root-ca.pem
      plugins.security.ssl.http.enabled: "true"
      plugins.security.ssl.http.pemcert_filepath: certs/indexer.pem
      plugins.security.ssl.http.pemkey_filepath: certs/indexer-key.pem
      plugins.security.ssl.http.pemtrustedcas_filepath: certs/root-ca.pem
      plugins.security.authcz.admin_dn: "CN=admin,O=Wazuh,L=City,ST=State,C=US"
      compatibility.override_main_response_version: "true"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    networks:
      - wazuh-net

  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.8.2
    container_name: wazuh-dashboard
    hostname: wazuh-dashboard
    restart: unless-stopped
    ports:
      - "443:5601"
    volumes:
      - ./config/dashboard:/usr/share/wazuh-dashboard/data/wazuh/config
      - ./config/certs/dashboard.pem:/usr/share/wazuh-dashboard/certs/dashboard.pem:ro
      - ./config/certs/dashboard-key.pem:/usr/share/wazuh-dashboard/certs/dashboard-key.pem:ro
      - ./config/certs/root-ca.pem:/usr/share/wazuh-dashboard/certs/root-ca.pem:ro
    environment:
      INDEXER_USERNAME: admin
      INDEXER_PASSWORD: SecretPassword
      WAZUH_API_URL: https://wazuh-manager
      DASHBOARD_USERNAME: kibanaserver
      DASHBOARD_PASSWORD: kibanaserver
      API_USERNAME: wazuh-wui
      API_PASSWORD: MyS3cr37P450r.*-
      SERVER_SSL_ENABLED: "true"
      SERVER_SSL_CERTIFICATE: /usr/share/wazuh-dashboard/certs/dashboard.pem
      SERVER_SSL_KEY: /usr/share/wazuh-dashboard/certs/dashboard-key.pem
      OPENSEARCH_SSL_CERTIFICATEAUTHORITIES: /usr/share/wazuh-dashboard/certs/root-ca.pem
    depends_on:
      - wazuh-indexer
      - wazuh-manager
    networks:
      - wazuh-net

networks:
  wazuh-net:
    driver: bridge
COMPOSE

    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=${SCRIPT_NAME} (Docker)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=${SERVICE_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now "${SCRIPT_NAME}"

    log_success "Wazuh SIEM stack installed"
    log_info "Dashboard: https://localhost:443 (admin/SecretPassword)"
    log_info "Manager API: https://localhost:55000 (wazuh-wui/MyS3cr37P450r.*-)"
    log_info "Indexer (OpenSearch): https://localhost:9200"
    log_info "Agent registration: port 1514/1515"
    log_info ""
    log_info "IMPORTANT: Change default passwords in ${SERVICE_DIR}/docker-compose.yml"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling ${SCRIPT_NAME}"
    require_root
    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload
    cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_success "Wazuh uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
