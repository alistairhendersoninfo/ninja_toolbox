# Penpot

Self-hosted open-source design and prototyping platform deployed via Docker Compose with nginx reverse proxy.

## Guided Workflow

The scripts are ordered as a step-by-step installation workflow:

| # | Script | Type | Description |
|---|--------|------|-------------|
| 1 | [docker-ce.sh](docker-ce.sh) | install | Install Docker CE container runtime (prerequisite) |
| 2 | [penpot.sh](penpot.sh) | install | Deploy Penpot via Docker Compose (frontend, backend, exporter, postgres, valkey) |
| 3 | [reverse-proxy.sh](reverse-proxy.sh) | install | Install nginx reverse proxy |
| 4 | [penpot-proxy.sh](penpot-proxy.sh) | config | Configure nginx site for Penpot (port 80 proxy to 9001, WebSocket support) |
| 5 | [portainer.sh](portainer.sh) | install | Install Portainer CE for container management |

## Architecture

- **Penpot Frontend** — UI on port 9001 (mapped from container 8080)
- **Penpot Backend** — API server
- **Penpot Exporter** — PDF/SVG export service
- **PostgreSQL 16** — Database
- **Valkey 8** — Cache (Redis-compatible)

All services run on a `penpot-net` bridge network. Data is stored at `/opt/app/docker/penpot/data/`.

## Quick Start

```bash
ninjamenu
# Navigate to: Containers > Services > Penpot
# Follow items 1-4 in order
```

## Documentation

- User Manual: [.docs/user_manuals/services.md](../../../../.docs/user_manuals/services.md)
- Technical Manual: [.docs/technical_manuals/services.md](../../../../.docs/technical_manuals/services.md)
