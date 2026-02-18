# Identity

Identity and access management using the Ory open-source stack. All services run as Docker containers with systemd management.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Ory Full Stack | Complete Ory stack (Kratos + Hydra + Oathkeeper + Keto + PostgreSQL) | install |
| Ory Kratos | Identity management — login, registration, WebAuthn/passkeys, sessions | install |
| Ory Hydra | OAuth2 and OpenID Connect provider | install |
| Ory Login Consent App | Login and consent UI for Hydra authentication flows | install |
| Ory Oathkeeper | Identity and Access Proxy — zero-trust API gateway | install |
| Ory Keto | Fine-grained authorization — Zanzibar/ReBAC permission system | install |

## Quick Start

```bash
ninjamenu
# Navigate to: Security -> Identity -> Ory Full Stack
```

The **Ory Full Stack** script deploys all components in a single docker-compose with shared PostgreSQL and internal networking. Use the individual scripts if you only need specific components.

## Architecture

```
Oathkeeper (4455) ──> Kratos (4433/4434)  ──> PostgreSQL (5432)
        │               │
        └──> Hydra (4444/4445) ──> Login/Consent (3000)
        │
        └──> Keto (4466/4467)
```

## Requirements

- Docker and Docker Compose
- Root/sudo access (for systemd and /opt/app/docker)
- PostgreSQL (bundled in full-stack, or provide DSN for individual installs)

## Documentation

- [User Guide](../../../.docs/user_manuals/security.md) - How to use these tools
- [Technical Manual](../../../.docs/technical_manuals/security.md) - Developer documentation

## Tags

`security` `identity` `ory` `oauth2` `oidc` `docker` `authorization`
