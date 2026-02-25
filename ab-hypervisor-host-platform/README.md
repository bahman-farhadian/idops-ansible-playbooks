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

- This domain is for hypervisor host setup, not guest VM provisioning.
- Guest VM provisioning lives under `ac-vm-provisioning/` providers.
- Contributor standards are defined at repository root in `CONTRIBUTOR-GUIDE.md`.
