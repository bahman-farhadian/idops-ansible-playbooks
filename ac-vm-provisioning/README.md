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

## Execution Notes

- This domain follows the stack model from root README.
- Execution is wave-based and iterative; VM provisioning is usually rerun as capacity grows.
