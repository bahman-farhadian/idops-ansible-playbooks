# ac-vm-provisioning

Domain status: active implementation

## Purpose
Provider-specific VM provisioning implementations.

## Current Providers

- `kvm-vm-provisioning/`: KVM/libvirt VM clone + customize workflow

## Migration Notes

- Legacy guest provisioning source: `old_playbooks/kvm-clone-ansible/`
- Current implementation target: `ac-vm-provisioning/kvm-vm-provisioning/`
- `ab-hypervisor-host-platform/` remains host-platform automation only.

## Planned Providers

- `esxi-vm-provisioning/` (planned)

## Dependencies

- Upstream domains: `aa-physical-server-foundation`, `ab-hypervisor-host-platform`
- Downstream domains: `ag-os-baseline-and-hardening`, `ah-container-runtime`, and higher layers

## Consistency Contract

- Each provider directory must expose one playbook entrypoint: `playbook.yml`.
- Workflow logic should be organized in `tasks/` and included by `playbook.yml`.
- Operator docs go in local `README.md`.
- Contributor rules are centralized in root `CONTRIBUTOR-GUIDE.md`.
