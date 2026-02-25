# ac-vm-provisioning

Domain status: active scaffold

## Purpose
Provider-specific VM provisioning implementations.

## Current Providers

- `kvm-vm-provisioning/`: KVM/libvirt VM clone + customize workflow

## Planned Providers

- `esxi-vm-provisioning/` (planned)

## Dependencies

- Upstream domains: `aa-physical-server-foundation`, `ab-hypervisor-host-platform`
- Downstream domains: `ag-os-baseline-and-hardening`, `ah-container-runtime`, and higher layers

## Consistency Contract

- Each provider directory must expose one playbook entrypoint: `site.yml`.
- Workflow logic should be organized in `tasks/` and included by `site.yml`.
- Operator docs go in `README.md`; contributor rules go in `DEVELOPER.md`.
