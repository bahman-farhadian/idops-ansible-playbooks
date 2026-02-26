# kvm-vm-provisioning

Production-oriented KVM provisioning for the `ac-vm-provisioning` domain.

This project now uses **cloud-image provisioning** (Debian 12/13 cloud images + cloud-init), not template cloning.

## What This Provides

- Image-cache workflow with checksum verification (`make image-cache`)
- Explicit operator-controlled paths:
  - `kvm_image_cache_path` for downloaded base images
  - `kvm_instance_disk_pool_path` for per-instance VM disks
- Per-instance provisioning from cached cloud images (no `virt-clone`)
- Cloud-init seed generation per instance (user-data, meta-data, network-config)
- VM domain definition via `virt-install --import`
- Runtime workflow for start + SSH checks + optional snapshots
- Strict cleanup scope to declared instance names only

## Directory Layout

- `playbook.yml` (single playbook entrypoint)
- `tasks/provision.yml` (stage orchestrator)
- `tasks/provision-preflight.yml`
- `tasks/provision-image-cache.yml`
- `tasks/provision-instances.yml`
- `tasks/provision-runtime.yml`
- `tasks/cleanup.yml`
- `tasks/ping.yml`
- `vars/kvm-provisioning.yml`
- `inventory.ini`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`

## Quick Start

```bash
cd ac-vm-provisioning/kvm-vm-provisioning
make venv
make check
make ping
```

Before first provisioning run, edit `vars/kvm-provisioning.yml`:

1. Set `kvm_hypervisor_host`.
2. Set `kvm_image_cache_path` and `kvm_instance_disk_pool_path`.
3. Set valid SHA256 checksums in `kvm_cloud_image_catalog[*].image_sha256`.
4. Set SSH key/password defaults and instance definitions.

Then run:

```bash
make image-cache
make provision
```

## Stage Model

`kvm_provision_stage` controls stage execution:

- `full`: preflight -> image-cache -> provision -> runtime
- `preflight`: validation only
- `image-cache`: download/verify cache only
- `provision`: create missing domains/disks only
- `runtime`: start/wait/snapshot workflow only

Important: stage mode is **selected-stage-only** when not `full`.

## Make Targets

```bash
make help
make image-cache
make provision
make provision-stage STAGE=image-cache
make provision-check
make cleanup
make cleanup-force
make cleanup-force-disks
```

`make provision-check` runs `preflight` in Ansible check mode.

## Cleanup Safety Rules

Cleanup is strict by design:

1. Scope is exact-name from `kvm_instance_definitions[*].instance_name` only.
2. If a declared name does not exist in libvirt, it is skipped.
3. Non-declared instances are never touched.
4. Disk deletion is opt-in (`kvm_cleanup_remove_instance_disks=true` or `make cleanup-force-disks`).
5. Base image cache files are not removed by cleanup.

## Variable Model Highlights

All user-editable settings are in `vars/kvm-provisioning.yml`.

Core interface keys:

- `kvm_provision_stage`
- `kvm_image_cache_path`
- `kvm_instance_disk_pool_path`
- `kvm_image_cache_verify_on_run`
- `kvm_cloud_image_catalog`
- `kvm_instance_definitions`
- `kvm_cleanup_confirmed`
- `kvm_cleanup_remove_instance_disks`

## Notes

- This project intentionally uses `venv/` (not `.venv`).
- Contributor standards are defined in `CONTRIBUTOR-GUIDE.md`.
