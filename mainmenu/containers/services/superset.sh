#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="superset"
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
    mkdir -p "${SERVICE_DIR}/data/postgres" "${SERVICE_DIR}/data/redis"

    # Generate a random secret key
    SUPERSET_SECRET_KEY=$(openssl rand -base64 42 | tr -d '=+/' | head -c 64)

    cat > "${SERVICE_DIR}/docker-compose.yml" <<COMPOSE
version: "3.8"

x-superset-common: &superset-common
  image: apache/superset:3.1.0
  environment: &superset-env
    SUPERSET_SECRET_KEY: "${SUPERSET_SECRET_KEY}"
    REDIS_HOST: redis
    REDIS_PORT: 6379
    POSTGRES_HOST: postgres
    POSTGRES_PORT: 5432
    POSTGRES_DB: superset
    POSTGRES_USER: superset
    POSTGRES_PASSWORD: superset
    SQLALCHEMY_DATABASE_URI: "postgresql+psycopg2://superset:superset@postgres:5432/superset"
    CELERY_BROKER_URL: "redis://redis:6379/0"
    CELERY_RESULT_BACKEND: "redis://redis:6379/1"
  depends_on:
    redis:
      condition: service_healthy
    postgres:
      condition: service_healthy
  networks:
    - superset-net

services:
  redis:
    image: redis:7-alpine
    container_name: superset-redis
    restart: unless-stopped
    volumes:
      - ./data/redis:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - superset-net

  postgres:
    image: postgres:15-alpine
    container_name: superset-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: superset
      POSTGRES_USER: superset
      POSTGRES_PASSWORD: superset
    volumes:
      - ./data/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U superset"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - superset-net

  superset-init:
    <<: *superset-common
    container_name: superset-init
    command:
      - /bin/sh
      - -c
      - |
        superset db upgrade &&
        superset fab create-admin --username admin --firstname Admin --lastname User --email admin@localhost --password admin || true &&
        superset init
    restart: "no"

  superset-app:
    <<: *superset-common
    container_name: superset-app
    restart: unless-stopped
    ports:
      - "8088:8088"
    volumes:
      - ./config:/app/superset_home
    depends_on:
      superset-init:
        condition: service_completed_successfully
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy

  superset-worker:
    <<: *superset-common
    container_name: superset-worker
    restart: unless-stopped
    command: ["celery", "--app=superset.tasks.celery_app:app", "worker", "--pool=prefork", "-O", "fair", "-c", "4"]
    depends_on:
      superset-init:
        condition: service_completed_successfully
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy

networks:
  superset-net:
    driver: bridge
COMPOSE

    log_info "Secret key saved in docker-compose.yml at ${SERVICE_DIR}"

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

    log_success "Apache Superset installed"
    log_info "Superset UI: http://localhost:8088 (default: admin/admin)"
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
    log_success "Apache Superset uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
