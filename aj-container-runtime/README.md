# aj-container-runtime

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

- Upstream: a Debian or Ubuntu host. Docker CE package URLs stay in local settings. This playbook does not call provisioning or hardening
- Downstream: `ak-container-orchestration/docker-swarm` on hosts that
  were installed with live-restore off

## Execution Notes

Run `docker-engine` after the guest exists and the apt proxies answer.
A Swarm member is installed here first, then joined from
`ak-container-orchestration`.

## Alternatives

- Podman, and a containerd-only playbook.

## Scope decision

- This domain is `docker-engine/` only.
- Podman and a containerd-only playbook are left out.
