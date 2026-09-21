# af-artifact-management

Domain for local package and image caches.

## Implemented projects

- `nexus-repository-systemd/`
  - Nexus Repository Manager 3 as a systemd service (not Docker)
  - APT reverse proxy for Debian and Ubuntu
  - Docker Hub reverse proxy
  - HTTP on the lab LAN only (port 8081, plus 8082 for Docker)

## Dependencies

- Upstream: `ac-vm-provisioning`, `ag-os-baseline-and-hardening`
- Downstream: later guests can use this cache for APT (set URLs in a
  local settings file; internet mirrors stay the tracked default)
