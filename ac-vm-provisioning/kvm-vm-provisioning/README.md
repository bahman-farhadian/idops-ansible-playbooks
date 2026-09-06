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
- Seed content configuration via the files in `vars/` (timezone, apt, packages, bootcmd/runcmd)
- Optional multi-disk provisioning (disabled by default) with per-disk mount targets
  such as `/data` or `/var/lib/<service>`
- Deterministic per-instance MAC assignment (or optional explicit `instance_mac_address`)
  for reliable cloud-init network matching
- Multi-hypervisor deployment: instances are placed on the host named by their
  `hypervisor` key, with per-host SSH credentials
- UEFI firmware enforced for every guest
- Inactive VM domain definition from `virt-install --import --print-xml`, with all
  declared disks attached before the first cloud-init boot
- Observed-state runtime reconciliation with mandatory external snapshots
- Optional CPU topology policy to force `sockets=1,threads=1` per instance
- Optional CPU share capping for controlled overcommit, where N vCPUs are
  worth one host CPU (hard CFS quota, not a relative weight)
- Strict cleanup scope to declared instance names only

## Directory Layout

- `playbook.yml` (single playbook entrypoint)
- `tasks/provision.yml` (stage orchestrator)
- `tasks/provision-preflight.yml`
- `tasks/provision-cpu-share.yml`
- `tasks/resolve-host-scope.yml`
- `tasks/provision-resolve-checksum-cache.yml`
- `tasks/provision-image-cache.yml`
- `tasks/provision-instances.yml`
- `tasks/provision-instances-batch-*.yml` (bounded parallel helpers)
- `tasks/provision-runtime-readiness.yml`
- `tasks/provision-runtime.yml`
- `tasks/cleanup.yml`
- `tasks/ping.yml`
- the files in `vars/`
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

Before first provisioning run, edit the files in `vars/`:

1. Set the `address` of `kvm-host-1` in `kvm_hypervisors` (section 1) to your
   KVM host, plus its `user` and `ssh_private_key_file` if it needs them. Add
   more entries to deploy across several hosts.
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

All user-editable settings are in the files in `vars/`.

Core interface keys:

- `kvm_image_cache_path`
- `kvm_instance_disk_pool_path`
- `kvm_image_cache_verify_on_run`
- `kvm_image_manifest_refresh_policy`
- `kvm_force_manifest_refresh`
- `kvm_image_checksum_cache_path`
- `kvm_checksum_file_immutable`
- `kvm_hypervisors`
- `kvm_hypervisor_ssh_private_key_file`
- `kvm_require_explicit_hypervisor`
- `kvm_cloud_image_catalog`
- `kvm_instance_definitions`
- `kvm_parallel_instance_workers`
- `kvm_snapshot_overlay_path`
- `kvm_qemu_guest_agent_wait_timeout_seconds`
- `kvm_qemu_guest_agent_poll_interval_seconds`
- `kvm_force_single_socket_vcpu_topology`
- `kvm_default_cpu_share_enabled`
- `kvm_cpu_share_vcpu_per_host_cpu`
- `kvm_cpu_share_period_microseconds`
- `kvm_cpu_share_validate_host_capacity`
- `kvm_cpu_share_host_cpu_reserve`
- `kvm_cpu_share_allow_capacity_overcommit`
- `kvm_cleanup_confirmed`
- `kvm_cleanup_remove_instance_disks`

## Configuration Layout

Settings live in `vars/`, one file per topic, numbered in reading order. Each
topic states its defaults before the thing that uses them, so the set ends with
the only question left once everything above is settled: which VMs to create.

| File | Holds |
|------|-------|
| `01-hypervisors.yml` | where VMs are deployed: hosts, their credentials, storage and network |
| `02-vm-defaults.yml` | CPU, memory, disks and the overcommit policy |
| `03-cloud-init.yml` | guest users, access and first-boot content |
| `04-images.yml` | cloud images, and how they are cached and trusted |
| `05-runtime.yml` | readiness waits, snapshots and cleanup guards |
| `06-instances.yml` | the VMs to create, and on which host |
| `settings.local.yml` | optional, gitignored, overrides any of the above |

Two files describe a deployment: `01-hypervisors.yml` declares the hosts and
`06-instances.yml` lists the VMs. Everything between them is the defaults those
VMs inherit, so a VM entry only needs to state what differs.

Each file opens with what it holds and the same index of its siblings, so
opening any one of them shows where everything else lives.

### Machine-Specific Values

Anything true only of your machine — real host addresses, SSH keys, local
storage pools — belongs in `vars/settings.local.yml`. It is loaded last, so it
overrides the tracked files, and it is optional: the playbook falls back to a
placeholder when it does not exist.

Generate it rather than writing it by hand:

```bash
make settings
```

That writes every setting the project exposes, commented out, grouped by the
file it comes from and carrying that file's own comments. Uncomment only what
differs here.

Running it again is safe and idempotent: it only ever adds settings that are
new since the last time (appended in a dated section) and never touches a
line that is already there, so a value you already uncommented and edited is
untouched. Nothing new to add means the file is not written at all. Run it any
time a project update adds a setting and want it available here too.

To discard your local edits and start from a clean template instead, pass
`FORCE=1`. That replaces the file outright, so it first copies your current
one to `vars/settings.local.yml.bak`; git does not back this file up otherwise.

Three rules worth knowing:

- Anything left commented keeps the tracked default, and follows it if that
  default later changes
- Overriding replaces the **whole** value, it does not merge. Uncomment
  `kvm_hypervisors` and every host must be listed there, because the tracked
  list is replaced outright
- Once a key lives in the local file, edit it there. The same key in a numbered
  file is ignored. Each run prints which keys the local file supplies, so an
  edit that appears to do nothing is explained on the spot

```yaml
---
kvm_hypervisors:
  - name: "my-host"
    address: "192.168.1.50"
    user: "root"
    ssh_private_key_file: "~/.ssh/my_kvm_key"
kvm_default_cloud_init_timezone: "Europe/Berlin"
```

### Looking Up A Field You Have Not Used Yet

`make settings` only tracks whether a setting exists at all. Once
`kvm_hypervisors` or `kvm_instance_definitions` has been customised, the sync
leaves its contents alone, so the full field list for a host or instance entry
is no longer visible in `vars/settings.local.yml` — there is nothing to copy a
field name such as `ssh_private_key_file` or `guest_network_gateway` from if
you have not already used it on that entry.

```bash
make settings-reference
```

writes every setting, including the complete example for a host and an
instance, to a separate file: `vars/settings-reference.local.yml`. It is not
read by `playbook.yml`, is regenerated from scratch every time, and exists
purely to be consulted or copied from. Edit `vars/settings.local.yml`, not
this one.

State only the keys that differ from the shipped defaults. `*.local.yml` is
gitignored, so those values are never committed and the tracked files stay
generic for everyone else.

## Multiple Hypervisors And Host Credentials

A KVM host is declared the same way a VM is: one entry in a list, with its own
settings. the files in `vars/` opens with the hosts (section 1), so the
first thing the file answers is *where* things are deployed.

```yaml
kvm_hypervisors:
  - name: "kvm-host-1"                       # Host name referenced by instances.
    address: "192.168.10.11"                 # Values: FQDN | IP | SSH alias.
    user: "root"                             # SSH user.
    ssh_private_key_file: "~/.ssh/id_kvm_host_1"
    ssh_port: 22
    python_interpreter: "/usr/bin/python3"
    libvirt_connection_uri: "qemu:///system"
```

Only `name` is required. Any key omitted or left empty falls back to the host
defaults in section 2, exactly as instance keys fall back to `kvm_default_*`:

```yaml
kvm_hypervisor_user: ""                      # "" = SSH config / current user
kvm_hypervisor_ssh_private_key_file: ""      # "" = SSH agent / SSH config
kvm_hypervisor_ssh_port: 22
```

`kvm_hypervisors` is the only place a host is declared, so at least one entry is
required and the run fails early if the list is empty.

An empty user or key is omitted rather than passed as a blank, so leaving both
empty keeps the operator's own SSH configuration and agent in charge.

### Per-Host Storage

Hosts rarely share a storage layout, so every path can be restated on the host
that owns it. Section 2 holds the fill-ins; a host that sets its own wins:

```yaml
kvm_hypervisors:
  - name: "kvm-host-1"
    image_cache_path: ""                     # "" = section 2 default
    instance_disk_pool_path: ""
    cloud_init_workspace_path: ""
  - name: "kvm-host-2"
    image_cache_path: "/srv/kvm/iso-pool"    # this host's own layout
    instance_disk_pool_path: "/srv/kvm/stg-pool"
```

`auto_create_image_cache_path` and `cleanup_workspace_path_after_run` are
per-host too. Derived paths follow the host that owns them, with nothing to
restate: the trusted checksum store stays under that host's image cache, and
snapshot overlays under its disk pool. Each path is checked for being absolute
before the run starts.

### Adding A Second Host

Append another entry, then point instances at it. Each host keeps its own
credentials, so hosts may use different SSH keys and users:

```yaml
kvm_hypervisors:
  - name: "kvm-host-1"
    address: "192.168.10.11"
    ssh_private_key_file: "~/.ssh/id_kvm_host_1"
  - name: "kvm-host-2"
    address: "192.168.10.12"
    user: "operator"
    ssh_private_key_file: "~/.ssh/id_kvm_host_2"
    ssh_port: 2222

kvm_instance_definitions:
  - instance_name: "debian-13-a"
    hypervisor: "kvm-host-1"
  - instance_name: "debian-13-b"
    hypervisor: "kvm-host-2"
```

`name` is the inventory name, so it is what `LIMIT` matches.

### Placement Rules

- An instance runs on the host named by its `hypervisor` key
- `hypervisor: ""` (or omitting the key) deploys on the first host declared in
  `kvm_hypervisors`. There is no separate "default host" setting to keep in
  sync: with one host declared the fallback is that host, and once a second is
  added each instance names the host it belongs to
- Set `kvm_require_explicit_hypervisor=true` to reject any instance that does
  not name its host, which is worth enabling once a fleet has more than one
  host. An empty `hypervisor: ""` counts as unset and is rejected too, so the
  destination must be stated outright
- Referencing an undefined hypervisor fails preflight with the list of known
  hosts, so a typo cannot silently place a VM on the wrong machine

All hosts are processed in the same run. Each host resolves its own slice of
`kvm_instance_definitions` and ignores the rest, so a VM is never created twice
or provisioned on the wrong host. A host with no assigned instances ends its own
run early instead of failing.

### Targeting One Host

`LIMIT` matches hypervisor names, so a run can be narrowed to a single host:

```bash
make provision LIMIT=kvm-host-2
make cleanup-force LIMIT=kvm-host-2
```

Cleanup stays scoped to the declared instances of the hosts in the run, so
limiting cleanup to one host cannot touch another host's VMs.

## CPU Share And Controlled Overcommit

`cpu_share_enabled` caps an instance so that a fixed number of vCPUs are worth
one host CPU. With the default ratio of `2`, a 4 vCPU guest can never consume
more than 2 host CPUs, which is what makes it safe to place more vCPUs on a
host than it has physical CPUs.

Enable it globally or per instance:

```yaml
kvm_default_cpu_share_enabled: false   # global default
kvm_cpu_share_vcpu_per_host_cpu: 2     # 2 vCPU == 1 host CPU

kvm_instance_definitions:
  - instance_name: "debian-13-b"
    vcpu_count: 4
    cpu_share_enabled: true            # capped at 2 host CPUs
```

### How The Cap Is Enforced

The ratio is applied as a Linux CFS bandwidth quota, written to the domain as:

```xml
<cputune>
  <period>100000</period>
  <quota>50000</quota>
</cputune>
```

`quota`/`period` is a **per-vCPU** ceiling, so `50000/100000` gives every vCPU
half a host CPU. This is a hard cap enforced by the kernel scheduler, not a
relative `shares` weight: a capped guest cannot exceed its budget no matter how
idle the host is, so bursty guests cannot contend for the same physical time
slices. The trade-off is deliberate — a capped guest will not use spare host
capacity, which is what buys the predictability.

`quota = kvm_cpu_share_period_microseconds / kvm_cpu_share_vcpu_per_host_cpu`
and must stay inside the libvirt range `1000-17592186044415`; `period` must stay
inside `1000-1000000`. Both are validated before anything is applied.

### Reconciliation

The cap is reconciled on every `provision` and `runtime` stage run, for existing
domains as well as new ones:

- Turning `cpu_share_enabled` on caps an already-defined domain in place
- Turning it off clears the cap (`vcpu_quota=-1`)
- Domains already at the requested values are left untouched (idempotent)
- Changes are written to the persistent config, and also applied live to running
  domains when `kvm_cpu_share_apply_to_running_domains` is true
- Every applied change is read back and asserted, so a cap that silently fails
  to take effect fails the run instead of passing quietly

Toggling the flag therefore converges without recreating the domain.

### Capacity Guard

When at least one instance is capped, preflight refuses to proceed if total CPU
demand exceeds the usable host budget:

```
demand  = sum(uncapped vcpu_count) + sum(capped vcpu_count) / ratio
usable  = host CPUs - kvm_cpu_share_host_cpu_reserve
```

Capped instances count at their true ceiling; uncapped instances count at full
`vcpu_count`. Set `kvm_cpu_share_allow_capacity_overcommit=true` to proceed
anyway. The guard is skipped entirely when no instance is capped, so existing
uncapped deployments keep their previous behavior.

Preflight also verifies the hypervisor exposes the cgroup `cpu` controller,
since libvirt cannot enforce a quota without CFS bandwidth control.

## Seed Configuration

Seed/user-data defaults are centralized in `vars/03-cloud-init.yml`:

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
