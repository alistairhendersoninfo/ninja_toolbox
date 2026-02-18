#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="ory-full-stack"
MENU_ROOT="${MENU_ROOT:-$(cd "$SCRIPT_DIR" && while [[ ! -f "install_menu.sh" ]] && [[ "$PWD" != "/" ]]; do cd ..; done; pwd)}"
source "$MENU_ROOT/.lib/platform.sh"

LOG_DIR="$MENU_ROOT/.docs/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

SERVICE_DIR="/opt/app/docker/ory"
SECRETS_FILE="/opt/app/docker/ory/.env"

install() {
    log_info "Installing Ory Full Stack — Kratos, Hydra, Oathkeeper, Keto + PostgreSQL"
    log_info "Log file: $LOG_FILE"
    echo ""

    require_root

    if ! command -v docker &>/dev/null; then
        log_error "Docker is required. Install it first from Containers > Runtime > Docker"
        exit 1
    fi

    log_step "1. Creating directory structure..."
    mkdir -p "${SERVICE_DIR}"/{kratos/config,oathkeeper/config}

    log_step "2. Generating secrets..."
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    KRATOS_SECRET=$(openssl rand -hex 16)
    KRATOS_COOKIE_SECRET=$(openssl rand -hex 16)
    HYDRA_SYSTEM_SECRET=$(openssl rand -hex 16)
    HYDRA_OIDC_SALT=$(openssl rand -hex 16)
    ORY_USER_PASSWORD=$(openssl rand -hex 16)

    cat > "${SECRETS_FILE}" <<EOF
# Ory Full Stack — generated secrets
# Keep this file secure; chmod 600 is applied automatically.

POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ORY_USER_PASSWORD=${ORY_USER_PASSWORD}

KRATOS_SECRET=${KRATOS_SECRET}
KRATOS_COOKIE_SECRET=${KRATOS_COOKIE_SECRET}

HYDRA_SYSTEM_SECRET=${HYDRA_SYSTEM_SECRET}
HYDRA_OIDC_SALT=${HYDRA_OIDC_SALT}

KRATOS_DSN=postgres://ory_user:${ORY_USER_PASSWORD}@ory-postgres:5432/kratos?sslmode=disable
HYDRA_DSN=postgres://ory_user:${ORY_USER_PASSWORD}@ory-postgres:5432/hydra?sslmode=disable
KETO_DSN=postgres://ory_user:${ORY_USER_PASSWORD}@ory-postgres:5432/keto?sslmode=disable
EOF
    chmod 600 "${SECRETS_FILE}"

    log_step "3. Writing Kratos identity schema config..."
    cat > "${SERVICE_DIR}/kratos/config/kratos.yml" <<'KRATOS_CFG'
version: v0.13.0

dsn: __DSN_REPLACED_BY_ENV__

serve:
  public:
    base_url: http://localhost:4433/
    cors:
      enabled: true
  admin:
    base_url: http://localhost:4434/

selfservice:
  default_browser_return_url: http://localhost:4455/
  allowed_return_urls:
    - http://localhost:4455

  methods:
    password:
      enabled: true
    webauthn:
      enabled: true
      config:
        rp:
          id: localhost
          display_name: NinjaMenu
          origin: http://localhost:4455
    totp:
      enabled: true

  flows:
    error:
      ui_url: http://localhost:4455/error
    settings:
      ui_url: http://localhost:4455/settings
    recovery:
      enabled: true
      ui_url: http://localhost:4455/recovery
    verification:
      enabled: true
      ui_url: http://localhost:4455/verification
    logout:
      after:
        default_browser_return_url: http://localhost:4455/login
    login:
      ui_url: http://localhost:4455/login
      lifespan: 10m
    registration:
      ui_url: http://localhost:4455/registration
      lifespan: 10m
      after:
        password:
          hooks:
            - hook: session

identity:
  default_schema_id: default
  schemas:
    - id: default
      url: file:///etc/config/kratos/identity.schema.json

hashers:
  argon2:
    parallelism: 1
    memory: 128MB
    iterations: 2
    salt_length: 16
    key_length: 16
KRATOS_CFG

    cat > "${SERVICE_DIR}/kratos/config/identity.schema.json" <<'SCHEMA'
{
  "$id": "https://schemas.ory.sh/presets/kratos/quickstart/email-password/identity.schema.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Person",
  "type": "object",
  "properties": {
    "traits": {
      "type": "object",
      "properties": {
        "email": {
          "type": "string",
          "format": "email",
          "title": "E-Mail",
          "minLength": 3,
          "ory.sh/kratos": {
            "credentials": {
              "password": { "identifier": true },
              "webauthn": { "identifier": true }
            },
            "recovery": { "via": "email" },
            "verification": { "via": "email" }
          }
        },
        "name": {
          "type": "object",
          "properties": {
            "first": { "title": "First Name", "type": "string" },
            "last": { "title": "Last Name", "type": "string" }
          }
        }
      },
      "required": ["email"],
      "additionalProperties": false
    }
  }
}
SCHEMA

    log_step "4. Writing Oathkeeper config..."
    cat > "${SERVICE_DIR}/oathkeeper/config/oathkeeper.yml" <<'OATHKEEPER_CFG'
serve:
  proxy:
    port: 4455
    cors:
      enabled: true
      allowed_origins:
        - "*"
  api:
    port: 4456

log:
  level: debug
  format: json

access_rules:
  matching_strategy: regexp
  repositories:
    - file:///etc/config/oathkeeper/rules.json

authenticators:
  anonymous:
    enabled: true
    config:
      subject: guest
  cookie_session:
    enabled: true
    config:
      check_session_url: http://ory-kratos:4433/sessions/whoami
      preserve_path: true
      extra_from: "@this"
      subject_from: "identity.id"
      only:
        - ory_kratos_session
  noop:
    enabled: true

authorizers:
  allow:
    enabled: true
  deny:
    enabled: true

mutators:
  noop:
    enabled: true
  header:
    enabled: true
    config:
      headers:
        X-User: "{{ print .Subject }}"
OATHKEEPER_CFG

    cat > "${SERVICE_DIR}/oathkeeper/config/rules.json" <<'RULES'
[
  {
    "id": "public-health",
    "upstream": { "url": "http://localhost:8080" },
    "match": {
      "url": "http://localhost:4455/health/<**>",
      "methods": ["GET"]
    },
    "authenticators": [{ "handler": "anonymous" }],
    "authorizer": { "handler": "allow" },
    "mutators": [{ "handler": "noop" }]
  },
  {
    "id": "kratos-public",
    "upstream": { "url": "http://ory-kratos:4433" },
    "match": {
      "url": "http://localhost:4455/self-service/<**>",
      "methods": ["GET", "POST", "PUT"]
    },
    "authenticators": [{ "handler": "anonymous" }],
    "authorizer": { "handler": "allow" },
    "mutators": [{ "handler": "noop" }]
  },
  {
    "id": "protected-api",
    "upstream": { "url": "http://localhost:8080" },
    "match": {
      "url": "http://localhost:4455/api/<**>",
      "methods": ["GET", "POST", "PUT", "PATCH", "DELETE"]
    },
    "authenticators": [{ "handler": "cookie_session" }],
    "authorizer": { "handler": "allow" },
    "mutators": [{ "handler": "header" }]
  }
]
RULES

    log_step "5. Writing PostgreSQL init script..."
    cat > "${SERVICE_DIR}/init-databases.sh" <<INITDB
#!/bin/bash
set -e
# Create databases for each Ory component
psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "\$POSTGRES_DB" <<-EOSQL
    CREATE USER ory_user WITH PASSWORD '${ORY_USER_PASSWORD}';
    CREATE DATABASE kratos OWNER ory_user;
    CREATE DATABASE hydra OWNER ory_user;
    CREATE DATABASE keto OWNER ory_user;
    GRANT ALL PRIVILEGES ON DATABASE kratos TO ory_user;
    GRANT ALL PRIVILEGES ON DATABASE hydra TO ory_user;
    GRANT ALL PRIVILEGES ON DATABASE keto TO ory_user;
EOSQL
INITDB
    chmod +x "${SERVICE_DIR}/init-databases.sh"

    log_step "6. Writing docker-compose.yml (full stack)..."
    cat > "${SERVICE_DIR}/docker-compose.yml" <<'COMPOSE'
version: "3.8"

services:
  # --- PostgreSQL ---
  ory-postgres:
    image: postgres:16-alpine
    container_name: ory-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=postgres
    volumes:
      - ory-pg-data:/var/lib/postgresql/data
      - ./init-databases.sh:/docker-entrypoint-initdb.d/init-databases.sh:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 10
    restart: unless-stopped
    networks:
      - ory-net

  # --- Kratos (Identity) ---
  ory-kratos-migrate:
    image: oryd/kratos:v1.1.0
    container_name: ory-kratos-migrate
    depends_on:
      ory-postgres:
        condition: service_healthy
    environment:
      - DSN=${KRATOS_DSN}
    volumes:
      - ./kratos/config:/etc/config/kratos:ro
    command: migrate sql -e --yes
    restart: "no"
    networks:
      - ory-net

  ory-kratos:
    image: oryd/kratos:v1.1.0
    container_name: ory-kratos
    depends_on:
      ory-kratos-migrate:
        condition: service_completed_successfully
    ports:
      - "4433:4433"
      - "4434:4434"
    environment:
      - DSN=${KRATOS_DSN}
      - SECRETS_COOKIE=${KRATOS_COOKIE_SECRET}
      - SECRETS_CIPHER=${KRATOS_SECRET}
    volumes:
      - ./kratos/config:/etc/config/kratos:ro
    command: serve -c /etc/config/kratos/kratos.yml --dev --watch-courier
    restart: unless-stopped
    networks:
      - ory-net

  # --- Hydra (OAuth2/OIDC) ---
  ory-hydra-migrate:
    image: oryd/hydra:v2.2.0
    container_name: ory-hydra-migrate
    depends_on:
      ory-postgres:
        condition: service_healthy
    environment:
      - DSN=${HYDRA_DSN}
    command: migrate sql -e --yes
    restart: "no"
    networks:
      - ory-net

  ory-hydra:
    image: oryd/hydra:v2.2.0
    container_name: ory-hydra
    depends_on:
      ory-hydra-migrate:
        condition: service_completed_successfully
    ports:
      - "4444:4444"
      - "4445:4445"
    environment:
      - DSN=${HYDRA_DSN}
      - SECRETS_SYSTEM=${HYDRA_SYSTEM_SECRET}
      - OIDC_SUBJECT_IDENTIFIERS_PAIRWISE_SALT=${HYDRA_OIDC_SALT}
      - URLS_SELF_ISSUER=http://localhost:4444
      - URLS_CONSENT=http://localhost:3000/consent
      - URLS_LOGIN=http://localhost:3000/login
      - URLS_LOGOUT=http://localhost:3000/logout
      - SERVE_PUBLIC_CORS_ENABLED=true
      - LOG_LEVEL=debug
    command: serve all --dev
    restart: unless-stopped
    networks:
      - ory-net

  # --- Login & Consent App ---
  ory-login-consent:
    image: oryd/hydra-login-consent-node:v2.2.0
    container_name: ory-login-consent
    depends_on:
      - ory-hydra
    ports:
      - "3000:3000"
    environment:
      - HYDRA_ADMIN_URL=http://ory-hydra:4445
      - NODE_TLS_REJECT_UNAUTHORIZED=0
    restart: unless-stopped
    networks:
      - ory-net

  # --- Oathkeeper (Access Proxy) ---
  ory-oathkeeper:
    image: oryd/oathkeeper:v0.40.7
    container_name: ory-oathkeeper
    depends_on:
      - ory-kratos
      - ory-hydra
    ports:
      - "4455:4455"
      - "4456:4456"
    volumes:
      - ./oathkeeper/config:/etc/config/oathkeeper:ro
    command: serve --config /etc/config/oathkeeper/oathkeeper.yml
    restart: unless-stopped
    networks:
      - ory-net

  # --- Keto (Authorization) ---
  ory-keto-migrate:
    image: oryd/keto:v0.12.0
    container_name: ory-keto-migrate
    depends_on:
      ory-postgres:
        condition: service_healthy
    environment:
      - DSN=${KETO_DSN}
    command: migrate up --yes
    restart: "no"
    networks:
      - ory-net

  ory-keto:
    image: oryd/keto:v0.12.0
    container_name: ory-keto
    depends_on:
      ory-keto-migrate:
        condition: service_completed_successfully
    ports:
      - "4466:4466"
      - "4467:4467"
    environment:
      - DSN=${KETO_DSN}
    command: serve
    restart: unless-stopped
    networks:
      - ory-net

volumes:
  ory-pg-data:

networks:
  ory-net:
    driver: bridge
COMPOSE

    log_step "7. Creating systemd service..."
    cat > "/etc/systemd/system/${SCRIPT_NAME}.service" <<UNIT
[Unit]
Description=Ory Full Identity Stack (Docker)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=root
WorkingDirectory=${SERVICE_DIR}
ExecStart=/usr/bin/docker compose --env-file .env up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now "${SCRIPT_NAME}"

    echo ""
    log_success "Ory Full Stack installed and running"
    echo ""
    log_info "Service endpoints:"
    log_info "  PostgreSQL:      localhost:5432"
    log_info "  Kratos Public:   http://localhost:4433"
    log_info "  Kratos Admin:    http://localhost:4434"
    log_info "  Hydra Public:    http://localhost:4444"
    log_info "  Hydra Admin:     http://localhost:4445"
    log_info "  Login/Consent:   http://localhost:3000"
    log_info "  Oathkeeper:      http://localhost:4455 (proxy) / :4456 (API)"
    log_info "  Keto Read:       http://localhost:4466"
    log_info "  Keto Write:      http://localhost:4467"
    echo ""
    log_info "Secrets stored at: ${SECRETS_FILE}"
    log_info "Config dir:        ${SERVICE_DIR}/"
    mark_installed true
}

uninstall() {
    log_info "Uninstalling Ory Full Stack"
    require_root

    systemctl stop "${SCRIPT_NAME}" 2>/dev/null || true
    systemctl disable "${SCRIPT_NAME}" 2>/dev/null || true
    rm -f "/etc/systemd/system/${SCRIPT_NAME}.service"
    systemctl daemon-reload

    if [[ -d "${SERVICE_DIR}" ]]; then
        cd "${SERVICE_DIR}" && docker compose down --volumes 2>/dev/null || true
    fi

    log_info "Data preserved at ${SERVICE_DIR}. Remove manually if desired."
    log_info "To fully purge: rm -rf ${SERVICE_DIR}"
    log_success "Ory Full Stack uninstalled"
    mark_installed false
}

case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    *) echo "Usage: $0 {install|uninstall}"; exit 1 ;;
esac
