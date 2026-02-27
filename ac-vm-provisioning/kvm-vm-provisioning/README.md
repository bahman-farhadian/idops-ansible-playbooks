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
- Seed content configuration via `vars/kvm-provisioning.yml` (timezone, apt, packages, bootcmd/runcmd)
- Optional multi-disk provisioning (disabled by default) with per-disk mount targets
  such as `/data` or `/var/lib/<service>`
- Deterministic per-instance MAC assignment (or optional explicit `instance_mac_address`)
  for reliable cloud-init network matching
- Configurable firmware mode per profile/instance (`bios` or `uefi`)
- VM domain definition via `virt-install --import`
- Runtime workflow for start + TCP port checks + optional snapshots
- Optional CPU topology policy to force `sockets=1,threads=1` per instance
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
- `callback_plugins/idops_task_timing.py`
- `scripts/benchmark_report.py`
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
6. Set cloud-init access defaults (plain user password, sudo policy, optional root password)
   and instance definitions.
7. Optional: set `kvm_guest_network_interface_fallbacks` to expand NIC-name fallbacks
   (defaults to `['ens3', 'enp1s0', 'eth0']`).
8. Use `*-genericcloud-amd64.qcow2` images for this workflow.
   `nocloud` is blocked by default; override only if intentional with
   `kvm_allow_nocloud_images=true`.
9. Root-disk repartitioning on `genericcloud` images is intentionally not supported
   in this playbook. Use installer-based provisioning or a custom image pipeline
   if you require custom root partition layout.
10. Set per-profile `firmware_boot_mode` in `kvm_cloud_image_catalog`.
    If unset, playbook fallback is `uefi`. On this stack, Debian 13 `genericcloud`
    requires `uefi`.
11. Add or remove Debian variants in `kvm_cloud_image_catalog`.
   `make image-cache` processes all catalog profiles, while instance creation
   still follows `kvm_instance_definitions`.
12. Default demo password is `changeme`; CHANGE THIS PASSWORD BEFORE PRODUCTION.
13. CPU topology default is single-socket/single-thread policy enabled
    (`kvm_force_single_socket_vcpu_topology=true`). Set it to `false`
    if you want libvirt to use plain `vcpu_count` topology.

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
make benchmark-cold
make benchmark-report
```

Difference between `make provision-stage` and `make provision`:

- `make provision` always runs the full workflow (`kvm_provision_stage=full`):
  preflight -> image-cache -> provision -> runtime.
- `make provision-stage STAGE=<stage>` runs only one selected stage
  (`preflight` | `image-cache` | `provision` | `runtime` | `full`).
- Use `make provision-stage` for targeted debugging or partial operations,
  and `make provision` for normal end-to-end provisioning.

`make provision-check` runs `preflight` in Ansible check mode.

`make image-cache` resolves checksums from official Debian manifests and stores
images using checksum-versioned filenames. When Debian `latest` changes, a new
versioned file is downloaded and old cached files are preserved.
By design, it caches all profiles defined in `kvm_cloud_image_catalog`.

## Safety And Performance Policy

Default policy is safety-first:

- checksum verification remains enabled by default (`kvm_image_cache_verify_on_run=true`)
- snapshot behavior remains enabled by default
- cleanup scope remains exact-name and opt-in for disk deletion

Performance tuning is applied internally without removing those safety defaults.

## Benchmarking

Use benchmark targets only when you intentionally want destructive cold-run measurements:

```bash
make benchmark-cold
make benchmark-report
```

`make benchmark-cold` does:

1. cleanup with `kvm_cleanup_confirmed=true` and disk removal enabled
2. timed full provision with shell `time`
3. cloud-init apt update/upgrade disabled only for benchmark comparability

Benchmark artifacts are written to `logs/benchmark/<timestamp>/`:

- `time.txt` (wall clock and CPU timing data from shell `time`)
- `task_timings.jsonl`
- `task_timings.csv`
- `timing_summary.json`

`make benchmark-report` prints wall-time, stage totals, and top slow tasks.
Note: benchmark metrics explicitly exclude apt update/upgrade time.

When snapshot is enabled, runtime stage waits for TCP port readiness first and
then actively waits for cloud-init completion (`cloud-init status --wait` or
`/var/lib/cloud/instance/boot-finished`) before shutdown/snapshot. This is an
active readiness gate, not a fixed sleep.
Maximum wait is controlled by `kvm_wait_for_cloud_init_timeout_seconds`.

Developer note: Debian `nocloud` artifacts were rejected for this workflow after
testing because they did not provide reliable cloud-init behavior in this stack.
Use Debian `genericcloud` artifacts.

Developer note: Debian 13 `genericcloud` booted reliably only with UEFI firmware
(`firmware_boot_mode: uefi`) on this hypervisor.

Developer note: UEFI provisioning uses secure-boot OVMF paths internally
(`OVMF_CODE_4M.ms.fd` + `OVMF_VARS_4M.ms.fd`) and does not expose secure-boot
toggles in user variables.

Developer note: machine/firmware are aligned across Debian variants
(`virt_install_machine_type: q35`, `firmware_boot_mode: uefi`).
For seed media, both profiles use `seed_device_bus: scsi` to avoid Debian 12
genericcloud cases where SATA seed media is not detected early at boot.

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

If TCP port wait times out, pre-collected `virsh domiflist/domifaddr` diagnostics are
shown in the failure message to speed up root-cause analysis.
Use the same URI configured in `kvm_libvirt_connection_uri` when checking manually.
For static-IP guests, `virsh domifaddr` can be empty with default source; also check:
`virsh -c qemu:///system domifaddr <instance> --source arp` and `--source agent`.

Debian 12 note:

- The playbook avoids forced interface `set-name` during Debian 12 network rendering.
- Runtime waits use `kvm_debian12_network_boot_wait_timeout_seconds` for Debian 12
  instances to absorb slower first-boot network initialization.
- If needed, increase `kvm_debian12_network_boot_wait_timeout_seconds` before
  increasing global SSH wait values.

## Cleanup Safety Rules

Cleanup is strict by design:

1. Scope is exact-name from `kvm_instance_definitions[*].instance_name` only.
2. If a declared name does not exist in libvirt, it is skipped.
3. Non-declared instances are never touched.
4. Disk deletion is opt-in (`kvm_cleanup_remove_instance_disks=true` or `make cleanup-force-disks`).
5. Base image cache files are not removed by cleanup.

`make cleanup-force-disks` also removes declared instance root disk, optional
additional disks, and seed files when a
domain does not exist (stale disk cleanup), while still never touching
non-declared names.

## Variable Model Highlights

All user-editable settings are in `vars/kvm-provisioning.yml`.

Core interface keys:

- `kvm_provision_stage`
- `kvm_image_cache_path`
- `kvm_instance_disk_pool_path`
- `kvm_image_cache_verify_on_run`
- `kvm_image_manifest_refresh_policy`
- `kvm_force_manifest_refresh`
- `kvm_cloud_image_catalog`
- `kvm_instance_definitions`
- `kvm_parallel_instance_workers`
- `kvm_skip_pre_snapshot_port_recheck`
- `kvm_debian12_network_boot_wait_timeout_seconds`
- `kvm_wait_for_cloud_init_timeout_seconds`
- `kvm_force_single_socket_vcpu_topology`
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
- `kvm_default_cloud_init_user_sudo_rule`
- `kvm_default_cloud_init_root_plain_password` (optional)

Default APT mirror is `deb.debian.org` via `kvm_default_cloud_init_apt_config`.

## Additional Disks

Root-disk partition customization is not applied on Debian `genericcloud` images
in this playbook. Use optional extra disks instead.

Global defaults:

- `kvm_default_instance_extra_disks_enabled` (default `false`)
- `kvm_default_instance_extra_disks` (default `[]`)

Per-instance overrides in `kvm_instance_definitions[]`:

- `instance_extra_disks_enabled`
- `instance_extra_disks`

`instance_extra_disks` item fields:

- `guest_device` (required, `vd[b-z]`, example: `vdb`)
- `size_gb` (required, integer > 0)
- `mount_point` (required, absolute path, example: `/data`, `/var/lib/app`)
- `filesystem` (optional, `ext4` or `xfs`, default: `ext4`)
- `mount_options` (optional, default: `defaults,nofail`)
- `disk_extension` (optional, default: `instance_disk_extension`)
- `filesystem_label` (optional)

Safety note:

- Mounting a fresh extra disk directly on `/var` is blocked by default because it
  can break boot on cloud images. Override only if you intentionally handle
  `/var` migration in your image pipeline:
  `kvm_allow_mount_var_on_extra_disk=true`.

Example:

```yaml
kvm_instance_definitions:
  - instance_name: "debian-13-a"
    image_profile_id: "debian-13"
    instance_ipv4_address: "192.168.24.131"
    vcpu_count: 2
    memory_mb: 2048
    root_disk_size_gb: 20
    instance_extra_disks_enabled: true
    instance_extra_disks:
      - guest_device: "vdb"
        size_gb: 40
        mount_point: "/data"
        filesystem: "ext4"
      - guest_device: "vdc"
        size_gb: 100
        mount_point: "/data"
        filesystem: "xfs"
        mount_options: "defaults,nofail"
```

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
`cloud_init_apt_config`, `instance_extra_disks`).

## Notes

- This project intentionally uses `venv/` (not `.venv`).
- Contributor standards are defined in `CONTRIBUTOR-GUIDE.md`.
