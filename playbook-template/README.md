# playbook-template

Reusable starter template for new Ansible playbook projects in this repository.

## Purpose

Use this directory as a baseline when creating a new domain implementation.
It follows repository standards:

1. One top-level playbook entrypoint (`playbook.yml`)
2. Workflow logic in `tasks/`
3. User-editable settings in `vars/`
4. Standard `Makefile` with `make help` and `make ping`
5. `venv/` local environment path and optional `wheelhouse/` dependency cache

## How To Use

1. Copy this directory to your target location.
2. Rename copied directory using kebab-case.
3. Rename `vars/template-config.yml` to a domain-specific config filename.
4. Replace placeholder tasks in `tasks/provision.yml` and `tasks/cleanup.yml`.
5. Keep commands discoverable through `make help`.

## Security Note

This template ships with dummy credentials for onboarding.

- Password default is `changeme`.
- SSH public key is a placeholder string.

CHANGE THESE VALUES BEFORE PRODUCTION USE.

## Quick Start

```bash
make venv
make check
make ping
make provision
```
