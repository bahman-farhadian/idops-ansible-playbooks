# Contributor Guide - kvm-vm-provisioning

This project follows a strict structure for consistency across provider implementations.

## Non-Negotiable Rules

1. Use exactly one playbook entrypoint file: `site.yml`.
2. Put workflow logic in task files under `tasks/`.
3. Keep user-editable runtime variables in `vars/vms.yml`.
4. Keep environment path name as `venv/` (not `.venv`).
5. Keep automation entry commands in `Makefile`.
6. `Makefile` must include `make ping`.
7. Every user-facing Make target must be listed in `make help`.
8. Preserve idempotency and dry-run compatibility where practical.

## Required Layout

- `site.yml`
- `tasks/provision.yml`
- `tasks/cleanup.yml`
- `tasks/ping.yml`
- `vars/vms.yml`
- `inventory.ini`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `README.md`
- `CONTRIBUTOR-GUIDE.md`

## Workflow Contract

- Provision action: `kvm_action=provision`
- Cleanup action: `kvm_action=cleanup`
- Connectivity check action: `kvm_action=ping`
- `site.yml` must remain the single playbook used by Make targets.

## Change Policy

When adding features:

1. Extend `vars/vms.yml` first with defaults and comments.
2. Add/modify tasks in `tasks/provision.yml` or `tasks/cleanup.yml`.
3. Keep `site.yml` minimal and orchestration-only.
4. Update both `README.md` and this file for any contract changes.
5. Keep commit messages short and explicit.

## Style Expectations

- Use kebab-case in filenames and directories.
- Keep task names explicit and operational.
- Validate inputs early using `ansible.builtin.assert`.
- Avoid provider-specific hardcoding in user-facing variables.
