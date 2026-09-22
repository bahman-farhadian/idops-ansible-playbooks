# ah-container-runtime

Domain status: in use

## Purpose

Docker Engine on a guest, with Swarm left off.

## Implemented projects

- `docker-engine/`
  - Docker Engine on Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04
  - CPU must be x86_64
  - Dedicated XFS data-root, pinned Docker CE packages from a Nexus apt proxy
  - Does not initialize Swarm

## Dependencies

- Upstream: guest provisioning, OS hardening, and Nexus apt proxies for
  Docker CE stable (bookworm, trixie, noble, resolute)
- Downstream: `ai-container-orchestration/docker-swarm` on hosts that
  were installed with live-restore off

## Execution Notes

Run `docker-engine` after the guest exists and the apt proxies answer.
A Swarm member is installed here first, then joined from
`ai-container-orchestration`.
