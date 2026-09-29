# an-data-applications

Domain status: decision only (no playbook files yet)

## Purpose

Internal data applications. Each application is its own playbook and its own guest.

## Playbook

- `metabase/`
  - One guest
  - Metabase as a systemd service
  - Its application database stays on that guest
- `superset/`
  - One guest
  - Apache Superset as a systemd service
  - Its metadata database stays on that guest

## Alternatives

- None named. Metabase and Superset are separate playbooks and can be used together.

## Left out

- A requirement that either guest use `ak-databases/postgresql`

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: people querying data through the web UI

## Status

- Playbook files: no
- Guests: one per playbook, created by `kvm-vm-provisioning`
