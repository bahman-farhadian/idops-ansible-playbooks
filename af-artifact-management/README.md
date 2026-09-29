# af-artifact-management

Domain for package and image caches.

## Implemented projects

- `nexus-repository-systemd/`
  - Nexus Repository Manager 3 as a systemd service (not Docker)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - APT reverse proxy for Debian and Ubuntu
  - Docker Hub reverse proxy
  - HTTP 8081 (UI and APT), 8082 (Docker)
  - More repository types are added later in this same playbook, one type at a time, when a project needs that cache

## Alternatives

- Harbor, Pulp, and apt-cacher. A hosted Docker registry stays out. JFrog is paid, so it stays out.

## Scope decision

- This domain is `nexus-repository-systemd/` only.
- A hosted Docker registry stays out of scope.
- No apt-cacher, Harbor, or Pulp playbook.
- JFrog is the stronger paid product. It stays out. Nexus stays.
- PyPI, npm, Maven, Helm, raw, and further repository types are later additions in this playbook. They are not created by the current deploy.
