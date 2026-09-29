# ac-vm-provisioning

Domain status: in use

## Purpose
Provider-specific VM provisioning implementations.

## Current Providers

- `kvm-vm-provisioning/`: create KVM guests from Debian 12/13 and Ubuntu 24.04/26.04 cloud images

## Migration Notes

- Legacy guest provisioning source: `old_playbooks/kvm-clone-ansible/`
- Current implementation target: `ac-vm-provisioning/kvm-vm-provisioning/`
- `ab-hypervisor-host-platform/` has no playbook files yet. The decided host playbooks, in directory order, are `debian-based-os-install`, `kvm-host`, `kvm-host-hardening`, and `esxi-host`.

## Planned Providers

- `esxi-vm-provisioning/` is required. No files yet.

## Scope decision

- Directory order is `kvm-vm-provisioning/`, then `esxi-vm-provisioning/`.
- The two are separate playbooks. They can be used together. The admin picks the playbook when a guest is deployed.
- `kvm-vm-provisioning/` creates KVM guests from Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04 cloud images. It does not install application services.
- `esxi-vm-provisioning/` creates the same four guest releases on ESXi. It does not install application services. No files yet.
- A normal Debian or Ubuntu service guest is created by one of those two playbooks, then hardened, then handed to its own playbook.
- OpenStack is `ah-openstack`. It is not part of this directory.

## Alternatives

- None named.

## Dependencies

- Upstream domains: `aa-physical-server-foundation`, `ab-hypervisor-host-platform`
- Downstream domains: `ag-os-baseline-and-hardening`, `ai-container-runtime`, and higher layers

## Consistency Contract

- Each provider directory has one playbook: `playbook.yml`.
- Workflow logic should be organized in `tasks/` and included by `playbook.yml`.
- Operator docs go in local `README.md`.
- Contributor rules are centralized in root `CONTRIBUTOR-GUIDE.md`.
