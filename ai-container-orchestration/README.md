# ai-container-orchestration

Domain status: in use

## Purpose

Docker Swarm on guests that already run Docker Engine.

## Implemented projects

- `docker-swarm/`
  - Initialize an odd set of managers and join workers
  - Optional node labels and overlay networks
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04, x86_64
  - Does not install the engine and does not open firewall ports

## Dependencies

- Upstream: `ah-container-runtime/docker-engine` with `live_restore: false`
  on every member, and a host firewall that already allows TCP 2377,
  TCP 7946, UDP 7946, and UDP 4789 between members
- Downstream: workloads that schedule onto the cluster

## Execution Notes

Install the engine first. Then run `docker-swarm`. A later engine
deploy on a member keeps the Swarm membership if live-restore stays
false.
