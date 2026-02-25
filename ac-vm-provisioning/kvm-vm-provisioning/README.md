# kvm-vm-provisioning

Production-oriented KVM VM provisioning for the `ac-vm-provisioning` domain.

## What This Adds

- Parallel VM cloning workflow using `virt-clone`
- Per-VM template profiles with OS variant support (`debian`, `ubuntu`)
- Per-VM network mode support:
  - `ifupdown` (Debian-style `/etc/network/interfaces`)
  - `netplan` (Ubuntu-style `/etc/netplan/*.yaml`)
- Snapshot support after provisioning
- Cleanup workflow for safe VM removal
- `Makefile` workflow
- Local environment folder named `venv/` (not `.venv`)
- Single playbook entrypoint: `site.yml`

## Directory Layout

- `site.yml` (single playbook entrypoint)
- `tasks/provision.yml`
- `tasks/cleanup.yml`
- `vars/vms.yml`
- `inventory.ini`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `venv/` (project-local Python environment path)
- `wheelhouse/` (optional cached Python wheels)
- `CONTRIBUTOR-GUIDE.md` (implementation standard for contributors)

## Quick Start

```bash
cd ac-vm-provisioning/kvm-vm-provisioning
make venv
make check
make ping
```

Optional dependency cache workflow:

```bash
make deps-bundle
```

When `wheelhouse/` contains wheel files, `make venv` installs from local cache first.

Edit `vars/vms.yml` and define:

1. Hypervisor connection (`kvm_host`)
2. `template_profiles` (Debian/Ubuntu templates)
3. `vms` list referencing `template_profile`

Then run provisioning:

```bash
make provision-check
make provision
```

Cleanup:

```bash
make cleanup
make cleanup-force
```

The same `site.yml` handles all workflows using `kvm_action`:

- `kvm_action=provision`
- `kvm_action=cleanup`
- `kvm_action=ping`

## VM OS Variant Model

Each VM references a profile under `template_profiles`:

- `guest_os_variant`: `debian` or `ubuntu`
- `guest_network_mode`: `ifupdown` or `netplan`
- `template_vm`: source VM template name

This allows mixed Debian and Ubuntu provisioning in one run.

## Notes on venv/

This project uses `venv/` as the local environment folder name by design.
The folder is included in repo layout so teams use a consistent path.
