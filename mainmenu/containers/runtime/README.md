# Container Runtime

Container engines and management UIs.

## Scripts

| Script | Description | Type |
|--------|-------------|------|
| Docker CE | Full Docker Community Edition with Compose and Buildx plugins | install |
| Podman | Rootless container engine — daemonless Docker alternative | install |
| Portainer CE | Web-based Docker management UI running as a container | install |

## Quick Start

```bash
ninjamenu
# Navigate to: Containers -> Runtime -> pick a tool
```

## Included Tools

### Docker CE
Full Docker Community Edition installation including:
- Docker engine, CLI, containerd
- Buildx and Compose plugins
- Docker group configuration
- Custom data directory at `/opt/app/docker`

### Podman
Rootless container engine as a Docker alternative:
- Daemonless architecture
- Rootless container support with slirp4netns
- Custom storage at `/opt/app/podman`
- User socket for API compatibility

### Portainer CE
Web-based management UI for Docker:
- Runs as a Docker container on port 9443
- Persistent data volume
- Optional systemd service integration
- Manages containers, images, volumes, networks

## Requirements

- Root access for Docker and Podman installation
- Docker must be installed before Portainer
- Debian/Ubuntu-based distributions

## Documentation

- [User Guide](../../../.docs/user_manuals/containers.md) - Usage instructions
- [Technical Manual](../../../.docs/technical_manuals/containers.md) - Developer docs

## Tags

`containers` `docker` `podman` `portainer` `runtime`
