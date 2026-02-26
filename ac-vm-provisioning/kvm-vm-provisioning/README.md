# kvm-vm-provisioning

Production-oriented KVM provisioning for the `ac-vm-provisioning` domain.

This project now uses **cloud-image provisioning** (Debian 12/13 genericcloud images + cloud-init), not template cloning.
Scope: this playbook supports **Debian images only**.

## What This Provides

- Image-cache workflow with checksum verification (`make image-cache`)
- Explicit operator-controlled paths:
  - `kvm_image_cache_path` for downloaded base images
  - `kvm_instance_disk_pool_path` for per-instance VM disks
- Per-instance provisioning from cached cloud images (no `virt-clone`)
- Cloud-init seed generation per instance (user-data, meta-data, network-config)
- Seed content configuration via `vars/kvm-provisioning.yml` (timezone, apt, packages, bootcmd/runcmd, storage map)
- Deterministic per-instance MAC assignment (or optional explicit `instance_mac_address`)
  for reliable cloud-init network matching
- Configurable firmware mode per profile/instance (`bios` or `uefi`)
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
- `host.yml`
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
2. Set `kvm_libvirt_connection_uri` (`qemu:///system` is the default and recommended value).
3. Set `kvm_image_cache_path` and `kvm_instance_disk_pool_path`.
4. Set a valid libvirt network (`kvm_default_libvirt_network_name` or per-instance `libvirt_network_name`).
5. Confirm official checksum manifest URLs under `kvm_cloud_image_catalog[*].image_checksum_manifest_url`.
6. Set cloud-init access defaults (including plain password) and instance definitions.
7. Optional: set `kvm_guest_network_interface_fallbacks` to expand NIC-name fallbacks
   (defaults to `['ens3', 'enp1s0', 'eth0']`).
8. Use `*-genericcloud-amd64.qcow2` images for this workflow.
   `nocloud` is blocked by default; override only if intentional with
   `kvm_allow_nocloud_images=true`.
9. Set firmware mode with `kvm_default_firmware_boot_mode` (global default) and/or
   per-profile `firmware_boot_mode` in `kvm_cloud_image_catalog`.
   If unset, playbook fallback is `uefi`. On this stack, Debian 13 `genericcloud`
   requires `uefi`.
10. Add or remove Debian variants in `kvm_cloud_image_catalog`.
   `make image-cache` processes all catalog profiles, while instance creation
   still follows `kvm_instance_definitions`.
11. Default demo password is `changeme`; CHANGE THIS PASSWORD BEFORE PRODUCTION.

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
By design, it caches all profiles defined in `kvm_cloud_image_catalog`.

Developer note: Debian `nocloud` artifacts were rejected for this workflow after
testing because they did not provide reliable cloud-init behavior in this stack.
Use Debian `genericcloud` artifacts.

Developer note: Debian 13 `genericcloud` booted reliably only with UEFI firmware
(`firmware_boot_mode: uefi`) on this hypervisor.

If provisioning fails with `Network not found`, run on hypervisor:

```bash
virsh -c qemu:///system net-list --all
```

Then set `kvm_default_libvirt_network_name` (or per-instance `libvirt_network_name`)
to one of those network names.

Optional runtime flag to auto-start inactive required networks:

```bash
make provision EXTRA_ARGS="-e kvm_auto_start_required_libvirt_networks=true"
```

If SSH wait times out, pre-collected `virsh domiflist/domifaddr` diagnostics are
shown in the failure message to speed up root-cause analysis.
Use the same URI configured in `kvm_libvirt_connection_uri` when checking manually.
For static-IP guests, `virsh domifaddr` can be empty with default source; also check:
`virsh -c qemu:///system domifaddr <instance> --source arp` and `--source agent`.

## Cleanup Safety Rules

Cleanup is strict by design:

1. Scope is exact-name from `kvm_instance_definitions[*].instance_name` only.
2. If a declared name does not exist in libvirt, it is skipped.
3. Non-declared instances are never touched.
4. Disk deletion is opt-in (`kvm_cleanup_remove_instance_disks=true` or `make cleanup-force-disks`).
5. Base image cache files are not removed by cleanup.

`make cleanup-force-disks` also removes declared instance disk/seed files when a
domain does not exist (stale disk cleanup), while still never touching
non-declared names.

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

## Seed Configuration

Seed/user-data defaults are centralized in `vars/kvm-provisioning.yml`:

- `kvm_default_cloud_init_timezone`
- `kvm_default_cloud_init_locale`
- `kvm_default_cloud_init_apt_config`
- `kvm_default_cloud_init_packages`
- `kvm_default_cloud_init_bootcmd`
- `kvm_default_cloud_init_runcmd`
- `kvm_default_cloud_init_write_files`
- `kvm_default_cloud_init_storage_layout_enabled`
- `kvm_default_cloud_init_storage_config`

Default APT mirror is `deb.debian.org` via `kvm_default_cloud_init_apt_config`.
Default storage map targets a 20GiB disk layout: 1GiB `/boot/efi`, 2GiB `/boot`,
10GiB `/`, and 7GiB `/var`.

Nexus/local apt cache example:

```yaml
kvm_default_cloud_init_apt_config:
  preserve_sources_list: true
  primary:
    - arches: [default]
      uri: "http://nexus.internal/repository/debian-proxy/"
  security:
    - arches: [default]
      uri: "http://nexus.internal/repository/debian-security-proxy/"
```

Per-instance overrides are supported by setting equivalent keys inside each
`kvm_instance_definitions[]` item (for example `cloud_init_timezone`,
`cloud_init_apt_config`, `cloud_init_storage_config`).

## Notes

- This project intentionally uses `venv/` (not `.venv`).
- Contributor standards are defined in `CONTRIBUTOR-GUIDE.md`.
