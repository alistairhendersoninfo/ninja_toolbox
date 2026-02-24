# Services

Dockerised application services deployed via `docker-compose` with systemd management. Each service is installed to `/opt/app/docker/<service>/` and registered as a systemd unit for automatic startup.

## Scripts

### Data Services

| Script | Description | Ports |
|--------|-------------|-------|
| [apache-doris.sh](apache-doris.sh) | Apache Doris real-time analytics database | 8030 (UI), 9030 (MySQL) |
| [iceberg.sh](iceberg.sh) | Apache Iceberg REST catalog | 8181 |
| [ozone.sh](ozone.sh) | Apache Ozone distributed object store | 9874 (OM UI) |
| [polaris.sh](polaris.sh) | Apache Polaris catalog service | 8181 |
| [atlas.sh](atlas.sh) | Apache Atlas data governance and metadata | 21000 |
| [superset.sh](superset.sh) | Apache Superset BI dashboards | 8088 |

### Security Services

| Script | Description | Ports |
|--------|-------------|-------|
| [haproxy.sh](haproxy.sh) | HAProxy load balancer with stats page | 80, 443, 8404 (stats) |
| [wazuh.sh](wazuh.sh) | Wazuh SIEM full stack (manager, indexer, dashboard) | 443 (dashboard), 1514/1515 (agents), 9200 (indexer), 55000 (API) |
| [security-onion.sh](security-onion.sh) | Security Onion network security monitoring | Configured during setup wizard |

### Design & Collaboration

| Submenu | Description |
|---------|-------------|
| [Penpot/](penpot/) | Self-hosted design and prototyping platform (guided 5-step workflow) |

## Common Operations

```bash
# Check service status
systemctl status <service-name>

# Restart a service
systemctl restart <service-name>

# View logs
journalctl -u <service-name>
docker compose -f /opt/app/docker/<service>/docker-compose.yml logs -f

# Stop a service
systemctl stop <service-name>
```

## Prerequisites

All services require Docker to be installed. Install it from **Containers > Runtime > Docker** in the menu.

## Documentation

- User Manual: [.docs/user_manuals/services.md](../../../.docs/user_manuals/services.md)
- Technical Manual: [.docs/technical_manuals/services.md](../../../.docs/technical_manuals/services.md)
