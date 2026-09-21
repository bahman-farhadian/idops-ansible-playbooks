# af-artifact-management

Domain for local package and image caches.

## Implemented projects

- `nexus-repository-systemd/`
  - Nexus Repository Manager 3 as a systemd service (not Docker)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - APT reverse proxy for Debian and Ubuntu
  - Docker Hub reverse proxy
  - HTTP on the lab LAN only (port 8081, plus 8082 for Docker)

## Dependencies

- Upstream: `ac-vm-provisioning`, `ag-os-baseline-and-hardening`
- Downstream: later guests can use this cache for APT (set URLs in a
  local settings file; internet mirrors stay the tracked default)
