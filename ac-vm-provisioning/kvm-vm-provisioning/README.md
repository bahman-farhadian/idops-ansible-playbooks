# kvm-vm-provisioning

Production-oriented KVM VM provisioning for the `ac-vm-provisioning` domain.

This project is the production migration target for `old_playbooks/kvm-clone-ansible/`.

## What This Adds

- Parallel VM cloning workflow using `virt-clone`
- Explicit instance pool model (`kvm_instance_pool_path`)
- Explicit template catalog with template disk file path lists
- Per-instance template profile selection with OS variant support (`debian`, `ubuntu`)
- Per-instance network mode support:
  - `ifupdown` (Debian-style `/etc/network/interfaces`)
  - `netplan` (Ubuntu-style `/etc/netplan/*.yaml`)
- Snapshot support after provisioning
- Cleanup workflow with safety confirmation flag
- Stateful template validation markers (`always` or `once`)
- Optional runtime ACL auto-fix for `libvirt-qemu` path access
- Fast `provision-check` behavior by skipping mutation phases by default
- `Makefile` workflow
- Local environment folder named `venv/` (not `.venv`)
- Single playbook entrypoint: `playbook.yml`

## Directory Layout

- `playbook.yml` (single playbook entrypoint)
- `tasks/provision.yml`
- `tasks/cleanup.yml`
- `vars/kvm-provisioning.yml`
- `inventory.ini`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `venv/` (project-local Python environment path)
- `wheelhouse/` (optional cached Python wheels)

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
`wheelhouse/` is a local cache for Python wheel packages to reduce repeated downloads.

## Variable Model (Official)

Edit `vars/kvm-provisioning.yml` and define:

1. Hypervisor connection:
   - `kvm_hypervisor_host`
   - `kvm_hypervisor_python_interpreter`
2. Instance pool and execution behavior:
   - `kvm_instance_pool_path`
   - `kvm_clone_workspace_path`
   - `kvm_execute_mutation_phases_in_check_mode`
3. Template catalog (`kvm_template_catalog`), including:
   - `template_instance_name`
   - `template_instance_disk_files` (list of full paths on the hypervisor)
4. Instance definitions (`kvm_instance_definitions`) with:
   - `instance_name`
   - `template_profile_id`
   - `instance_ipv4_address`
   - `vcpu_count`
   - `memory_mb`
5. Runtime access behavior:
   - `kvm_validate_runtime_pool_access`
   - `kvm_auto_fix_runtime_pool_access`
   - `kvm_libvirt_runtime_user`
6. Template validation behavior:
   - `kvm_template_validation_mode` (`always` or `once`)
   - `kvm_template_validation_state_dir`

`template_profile_id` can be either:
- a key from `kvm_template_catalog` (for example `debian-trixie`)
- or a `template_instance_name` alias from that catalog (for example `debian-bookworm`)

`instance_name` must be different from `template_instance_name`.

`kvm_clone_workspace_path` must be different from `kvm_instance_pool_path` when `kvm_cleanup_workspace_path_after_run=true`.

Then run provisioning:

```bash
make provision-check
make provision
```

`make provision-check` runs in Ansible check mode.
By default, mutation phases are skipped in check mode (`kvm_execute_mutation_phases_in_check_mode=false`), so it performs fast preflight validation only.

Cleanup:

```bash
make cleanup
make cleanup-force
```

`make cleanup-force` sets `kvm_cleanup_confirmed=true`.

The same `playbook.yml` handles all workflows using `kvm_action`:

- `kvm_action=provision`
- `kvm_action=cleanup`
- `kvm_action=ping`

## Notes on venv/

This project uses `venv/` as the local environment folder name by design.
The folder is included in repo layout so teams use a consistent path.
Contributor standards are defined at repository root in `CONTRIBUTOR-GUIDE.md`.
