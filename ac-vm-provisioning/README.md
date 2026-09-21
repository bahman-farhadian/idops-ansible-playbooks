# ac-vm-provisioning

Domain status: in use

## Purpose
Provider-specific VM provisioning implementations.

## Current Providers

- `kvm-vm-provisioning/`: create KVM guests from Debian 12/13 and Ubuntu 24.04/26.04 cloud images

## Migration Notes

- Legacy guest provisioning source: `old_playbooks/kvm-clone-ansible/`
- Current implementation target: `ac-vm-provisioning/kvm-vm-provisioning/`
- `ab-hypervisor-host-platform/` is reserved for host-platform automation and is currently empty.

## Planned Providers

- `esxi-vm-provisioning/` (planned)

## Dependencies

- Upstream domains: `aa-physical-server-foundation`, `ab-hypervisor-host-platform`
- Downstream domains: `ag-os-baseline-and-hardening`, `ah-container-runtime`, and higher layers

## Consistency Contract

- Each provider directory has one playbook: `playbook.yml`.
- Workflow logic should be organized in `tasks/` and included by `playbook.yml`.
- Operator docs go in local `README.md`.
- Contributor rules are centralized in root `CONTRIBUTOR-GUIDE.md`.
