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
- UEFI firmware enforced for every guest
- Inactive VM domain definition from `virt-install --import --print-xml`, with all
  declared disks attached before the first cloud-init boot
- Observed-state runtime reconciliation with mandatory external snapshots
- Optional CPU topology policy to force `sockets=1,threads=1` per instance
- Strict cleanup scope to declared instance names only

## Directory Layout

- `playbook.yml` (single playbook entrypoint)
- `tasks/provision.yml` (stage orchestrator)
- `tasks/provision-preflight.yml`
- `tasks/provision-resolve-checksum-cache.yml`
- `tasks/provision-image-cache.yml`
- `tasks/provision-instances.yml`
- `tasks/provision-instances-batch-*.yml` (bounded parallel helpers)
- `tasks/provision-runtime-readiness.yml`
- `tasks/provision-runtime.yml`
- `tasks/cleanup.yml`
- `tasks/ping.yml`
- `vars/kvm-provisioning.yml`
- `host.yml`
- `ansible.cfg`
- `Makefile`
- `<repository-root>/requirements.txt` (shared pinned dependencies)

## Quick Start

```bash
cd ac-vm-provisioning/kvm-vm-provisioning
make venv
make check
make ping
```

`make venv` delegates to the repository root and creates the single shared
`<repository-root>/venv/` environment from `<repository-root>/requirements.txt`.
It does not create a project-local virtual environment.

## Hypervisor Prerequisites

Required commands on the KVM host:

- `virsh`
- `qemu-img`
- `cloud-localds`
- `virt-install`
- `runuser`
- `setfacl` (required when `kvm_auto_fix_runtime_pool_access=true`)

Debian/Ubuntu install command:

```bash
sudo apt update
sudo apt install -y libvirt-clients qemu-utils cloud-image-utils virtinst acl util-linux
```

Package mapping:

- `virsh` -> `libvirt-clients`
- `qemu-img` -> `qemu-utils`
- `cloud-localds` -> `cloud-image-utils`
- `virt-install` -> `virtinst`
- `runuser` -> `util-linux`
- `setfacl` -> `acl`

Before first provisioning run, edit `vars/kvm-provisioning.yml`:

1. Set `kvm_hypervisor_host`.
2. Set `kvm_libvirt_connection_uri` (`qemu:///system` is the default and recommended value).
3. Set `kvm_image_cache_path` and `kvm_instance_disk_pool_path`.
4. Set a valid libvirt network (`kvm_default_libvirt_network_name` or per-instance `libvirt_network_name`).
5. Pin each profile in `kvm_cloud_image_catalog` to an explicit `image_version`
   (Debian build token, e.g. `20260706-2531`). URLs, filenames, and the checksum
   manifest are derived automatically from `image_codename` + `image_major` +
   `image_variant` + `image_version`. Optionally set `image_checksum` per profile
   to enable fully offline acquisition (one-time double-check only).
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
10. Keep `firmware_boot_mode: uefi` for every image profile. BIOS is not
    supported by this project. On this stack, Debian 13 `genericcloud` requires
    UEFI.
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

## Make Targets

```bash
make help
make venv
make deps-bundle
make lint
make check
make ping
make image-cache
make checksum-refresh
make provision
make provision-check
make cleanup
make cleanup-force
make cleanup-force-disks
```

`make provision-check` runs `preflight` in Ansible check mode.

`make image-cache` pins each profile to an explicit `image_version` (a Debian
build token, e.g. `20260706-2531`) and resolves a **trusted checksum** for it.

The trusted checksum is resolved **once per version** and stored locally as an
**immutable file** (`chattr +i`) under `kvm_image_checksum_cache_path`. Later runs
read that local file and verify the cached image against it **without any web
access** — this is required on servers that are not always online. The web
manifest is only fetched the first time a version is seen, or when you force a
refresh.

If `image_checksum` is set for a profile, it is used as the expected checksum for
a one-time double-check, but the locally computed checksum becomes the trusted
source going forward. To re-seed a version's trusted checksum, run
`make checksum-refresh` (sets `kvm_force_manifest_refresh=true`).

By design, it caches all profiles defined in `kvm_cloud_image_catalog`.

## Safety And Performance Policy

Default policy is safety-first:

- checksum verification remains enabled by default (`kvm_image_cache_verify_on_run=true`)
- external `snapshot-a` reconciliation remains mandatory for every declared guest
- cleanup scope remains exact-name and opt-in for disk deletion

Performance tuning is applied internally without removing those safety defaults.

The runtime stage discovers snapshot metadata and the active disk chain for
every declared domain. Domains missing `snapshot-a` resume the completion flow,
including after an interrupted earlier run. Visible QEMU Guest Agent checkpoints
verify `/var/lib/cloud/instance/boot-finished`, that `ssh.service` is active,
and that TCP/22 is listening inside the guest. It then creates
the mandatory `snapshot-a` as an external disk snapshot and verifies its
libvirt metadata before restarting the guest. This is an active readiness gate,
not a fixed sleep.
Maximum active readiness wait is currently 600 seconds per checkpoint.

Each readiness checkpoint prints its instance name, retry state, and final error.
No guest SSH connection or guest credential is used by provisioning.

Developer note: Debian `nocloud` artifacts were rejected for this workflow after
testing because they did not provide reliable cloud-init behavior in this stack.
Use Debian `genericcloud` artifacts.

Developer note: Debian 13 `genericcloud` booted reliably only with UEFI firmware
(`firmware_boot_mode: uefi`) on this hypervisor.

Developer note: UEFI provisioning uses secure-boot OVMF paths internally
(`OVMF_CODE_4M.ms.fd` + `OVMF_VARS_4M.ms.fd`) and does not expose secure-boot
toggles in user variables.

Developer note: libvirt internal snapshots are not supported for pflash UEFI
guests on this host. The playbook uses an external disk snapshot instead. The
base disks remain in `kvm_instance_disk_pool_path`; writable overlays are
created in `kvm_snapshot_overlay_path` (default: `<instance-pool>/snapshots`).
Cloud-init seed media and UEFI NVRAM are deliberately excluded. After cloud-init
completion, the seed device is detached from the persistent domain definition
and its seed image is removed before snapshot creation.

The QEMU Guest Agent is installed and started by cloud-init for every guest and
is mandatory for the snapshot readiness gate. Domain XML explicitly declares
the `org.qemu.guest_agent.0` virtio channel, which is validated before the wait
begins. `openssh-server` is also installed and started for every guest. The gate
does not connect to guest SSH or perform TCP probing from the Ansible runner,
and does not use a configured public key, private key, or password.

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

If readiness fails, the task identifies the QEMU Guest Agent or in-guest
checkpoint that timed out. Use the configured `kvm_libvirt_connection_uri` when
checking `virsh dumpxml`, `domblklist`, or the QEMU domain log manually.
`virsh domifaddr --source agent` is available only after the guest agent connects.

Debian 12 note: the playbook avoids forced interface `set-name` during Debian 12
network rendering. Guest readiness uses the same QEMU Guest Agent checkpoints
and timeout policy for all supported Debian releases.

## Cleanup Safety Rules

Cleanup is strict by design:

1. Scope is exact-name from `kvm_instance_definitions[*].instance_name` only.
2. If a declared name does not exist in libvirt, it is skipped.
3. Non-declared instances are never touched.
4. Disk deletion is opt-in (`kvm_cleanup_remove_instance_disks=true` or `make cleanup-force-disks`).
5. Base image cache files are not removed by cleanup.

`make cleanup-force-disks` also removes declared instance root disk, optional
additional disks, and any stale seed files when a domain does not exist, while
still never touching non-declared names. Successful provisioning removes its
seed image after cloud-init completion, before snapshot creation.

It also removes the matching `snapshot-a` external overlays and generated
snapshot XML from `kvm_snapshot_overlay_path`. It never scans or removes
snapshot artifacts for undeclared instance names.

## Snapshot Lifecycle

Each successful full provisioning run ensures every declared instance has a
clean-shutdown external disk snapshot named `snapshot-a`. It covers `vda` and
every configured extra disk. Cloud-init seed media is detached and deleted after
initialization, so it is neither attached to the running domain nor part of the
snapshot. The active domain is restarted on the new qcow2 overlays. Interrupted
runs resume domains that exist but still lack the mandatory snapshot.

Disk creation uses a per-instance `.provisioning` ownership marker. A rerun may
resume exact, validated partial disks only when that marker exists. Unmarked
pre-existing disks and unexpected libvirt disk sources fail closed rather than
being overwritten or silently reused.

Instance disk filenames include their guest device: the root disk is
`<instance>-vda.qcow2`, and an extra disk is, for example,
`<instance>-vdb.qcow2`. Cleanup also removes the legacy root filename
`<instance>.qcow2` for instances created before this naming convention.

Inspect a snapshot on the hypervisor:

```bash
virsh -c qemu:///system snapshot-list <instance> --tree
virsh -c qemu:///system snapshot-dumpxml <instance> snapshot-a
virsh -c qemu:///system domblklist <instance>
```

Direct `virsh snapshot-revert` of this external disk-only snapshot is not
supported by the target libvirt 9.0 stack. Do not delete or rename an overlay
while `virsh domblklist <instance>` references it. Restoring the preserved base
disk chain requires an offline, manually verified domain XML recovery and is
deliberately not automated by this project. See libvirt's
[external snapshot management guidance](https://wiki.libvirt.org/I_created_an_external_snapshot_but_libvirt_will_not_let_me_delete_or_revert_to_it.html)
before attempting that recovery.

For the supported full rebuild path, `make cleanup-force-disks` removes only the
declared instance's base disks, seed image, `snapshot-a` overlays, snapshot XML,
and ownership marker before `make provision` creates a new baseline.

## Variable Model Highlights

All user-editable settings are in `vars/kvm-provisioning.yml`.

Core interface keys:

- `kvm_image_cache_path`
- `kvm_instance_disk_pool_path`
- `kvm_image_cache_verify_on_run`
- `kvm_image_manifest_refresh_policy`
- `kvm_force_manifest_refresh`
- `kvm_image_checksum_cache_path`
- `kvm_checksum_file_immutable`
- `kvm_cloud_image_catalog`
- `kvm_instance_definitions`
- `kvm_parallel_instance_workers`
- `kvm_snapshot_overlay_path`
- `kvm_qemu_guest_agent_wait_timeout_seconds`
- `kvm_qemu_guest_agent_poll_interval_seconds`
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
    instance_ipv4_address: "192.168.122.131"
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
- Repository-root `CONTRIBUTOR-GUIDE.md` standards apply to this project.
