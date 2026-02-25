# ab-hypervisor-host-platform

Hypervisor host platform automation for Debian-based KVM hosts.

## Scope

- Prepare hypervisor hosts with required KVM/libvirt packages
- Validate virtualization and libvirt readiness
- Keep one-playbook entrypoint structure (`playbook.yml`)

## Standard Layout

- `playbook.yml` (single playbook entrypoint)
- `tasks/configure.yml`
- `tasks/ping.yml`
- `vars/hypervisor.yml`
- `inventory.ini`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `README.md`

## Quick Start

```bash
cd ab-hypervisor-host-platform
make venv
make check
make ping
make configure-check
make configure
```

## Notes

- This domain is only for hypervisor host platform setup.
- Guest VM provisioning is implemented under `ac-vm-provisioning/`.
- Legacy guest clone reference `old_playbooks/kvm-clone-ansible/` maps to `ac-vm-provisioning/kvm-vm-provisioning/`.
- Contributor standards are defined at repository root in `CONTRIBUTOR-GUIDE.md`.
