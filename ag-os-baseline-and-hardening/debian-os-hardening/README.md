# debian-os-hardening

Debian/Ubuntu hardening project migrated from:
`old_playbooks/debian-based-hardening-ansible`

This project follows repository standards:

- Single top-level entrypoint: `playbook.yml`
- Workflow logic in `tasks/`
- User-editable settings in `vars/debian-hardening.yml`
- One Makefile UX with `make help` and `make ping`

## Supported Targets

- Debian 12
- Debian 13
- Ubuntu 22.04
- Ubuntu 24.04

## Project Layout

- `playbook.yml`
- `tasks/` (`preflight.yml`, `ping.yml`, `scan.yml`, `harden.yml`, `reboot.yml`)
- `roles/` (migrated hardening and Lynis roles)
- `vars/debian-hardening.yml`
- `vars/local-secrets.yml.example`
- `host.yml`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`

## Quick Start

```bash
cd ag-os-baseline-and-hardening/debian-os-hardening
make venv
make check
make ping
make harden
```

## Inventory

Edit `host.yml` and place targets under `hardening_targets`.

## Main Commands

```bash
make ping
make scan
make harden
make reboot
```

`scan` and `harden` are explicit, separate workflows.

## Offline Lynis Bundle Mode

For targets without internet access, enable offline Lynis delivery in `vars/debian-hardening.yml`:

- `lynis_offline_bundle_from_control_node: true`
- `lynis_control_cache_dir: "/tmp/idops-lynis-cache"`

Behavior in offline mode:

- Control node clones/updates Lynis from `lynis_repo_url`.
- Control node creates commit-tagged tarball bundles in temp cache:
  - `lynis-<commit>.tar.gz`
- Bundle is copied to each target under `/tmp/` and extracted to `lynis_install_path`.
- Existing bundles are reused by commit name, so unchanged commits are not re-bundled.

## Artifacts

Lynis reports are collected under:

- `artifacts/lynis/<hostname>/`

## Secrets

Copy and edit local secrets (git-ignored):

```bash
cp vars/local-secrets.yml.example vars/local-secrets.yml
```

Use `vars/local-secrets.yml` for sensitive values (for example GRUB password).
