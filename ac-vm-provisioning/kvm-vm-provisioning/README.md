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

## Hypervisor Prerequisites

Required commands on the KVM host:

- `virsh`
- `qemu-img`
- `cloud-localds`
- `virt-install`
- `setfacl` (required when `kvm_auto_fix_runtime_pool_access=true`)

Debian/Ubuntu install command:

```bash
sudo apt update
sudo apt install -y libvirt-clients qemu-utils cloud-image-utils virtinst acl
```

Package mapping:

- `virsh` -> `libvirt-clients`
- `qemu-img` -> `qemu-utils`
- `cloud-localds` -> `cloud-image-utils`
- `virt-install` -> `virtinst`
- `setfacl` -> `acl`

Before first provisioning run, edit `vars/kvm-provisioning.yml`:

1. Set `kvm_hypervisor_host`.
2. Set `kvm_image_cache_path` and `kvm_instance_disk_pool_path`.
3. Set a valid libvirt network (`kvm_default_libvirt_network_name` or per-instance `libvirt_network_name`).
4. Confirm official checksum manifest URLs under `kvm_cloud_image_catalog[*].image_checksum_manifest_url`.
5. Set cloud-init access defaults (including plain password) and instance definitions.

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

`make image-cache` resolves checksums from official Debian manifests and stores
images using checksum-versioned filenames. When Debian `latest` changes, a new
versioned file is downloaded and old cached files are preserved.

If provisioning fails with `Network not found`, run on hypervisor:

```bash
virsh net-list --all
```

Then set `kvm_default_libvirt_network_name` (or per-instance `libvirt_network_name`)
to one of those network names.

Optional runtime flag to auto-start inactive required networks:

```bash
make provision EXTRA_ARGS="-e kvm_auto_start_required_libvirt_networks=true"
```

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
