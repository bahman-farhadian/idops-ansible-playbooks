# Contributor Guide - ab-hypervisor-host-platform

## Mandatory Rules

1. Keep exactly one playbook entrypoint: `site.yml`.
2. Do not add extra top-level playbooks (for example `clone-vms.yml`, `cleanup-vms.yml`).
3. Put workflow logic under `tasks/` and include from `site.yml`.
4. Keep Makefile commands listed in `make help`.
5. `make ping` is required and must remain operational.

## Workflow Contract

- `hypervisor_action=ping`: connectivity and readiness checks
- `hypervisor_action=configure`: hypervisor platform configuration
