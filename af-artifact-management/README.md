# af-artifact-management

Domain for package and image caches.

## Implemented projects

- `nexus-repository-systemd/`
  - Nexus Repository Manager 3 as a systemd service (not Docker)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - APT reverse proxy for Debian and Ubuntu
  - Docker Hub reverse proxy
  - HTTP 8081 (UI and APT), 8082 (Docker)

## Alternatives

- Harbor, Pulp, and apt-cacher. A hosted Docker registry stays out. JFrog is paid, so it stays out.

## Scope decision

- This domain is `nexus-repository-systemd/` only.
- A hosted Docker registry stays out of scope.
- No apt-cacher, Harbor, or Pulp playbook.
- JFrog is the stronger paid product. It stays out. Nexus stays.
