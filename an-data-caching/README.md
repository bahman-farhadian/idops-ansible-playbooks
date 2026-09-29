# an-data-caching

Domain status: decision only (no playbook files yet)

## Purpose

An in-memory cache for applications.

## Playbook

- `redis/`
  - One guest
  - Redis as a systemd service
  - Kept because production here still runs Redis
  - Redis 8 is tri-licensed (AGPL, SSPL, or RSAL). AGPL is the open-source terms

## Alternatives

- Valkey and Memcached.

## Left out

- Valkey
- Memcached
- A Redis cluster, until a later change inside this playbook

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: applications that want a cache

## Status

- Playbook files: no
- Guest: one, created by `kvm-vm-provisioning`
