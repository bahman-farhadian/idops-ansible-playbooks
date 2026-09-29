# ab-hypervisor-host-platform

Domain status: decision only (no playbook files yet)

## Purpose

Prepare an already-installed hypervisor. KVM and ESXi are both required. Each has its own playbook. The playbooks are separate and can be used together.

## Playbook

- `kvm-host/`
  - An installed Debian or Ubuntu machine
  - libvirt, storage pools, and bridges
  - Runs over SSH
  - Does not create guests and does not install the operating system
- `esxi-host/`
  - An installed ESXi host
  - Datastores, virtual switches, and port groups
  - Runs over the ESXi API
  - Does not create guests and does not install ESXi

## Alternatives

- None named.

## Left out

- `ilo-management` in `aa-physical-server-foundation` (one playbook: BIOS settings, BIOS update, and iLO)
- RAID
- Guest creation (`ac-vm-provisioning/kvm-vm-provisioning` and `ac-vm-provisioning/esxi-vm-provisioning`)

## Dependencies

- Upstream: an installed hypervisor host
- Downstream: `ac-vm-provisioning`

## Status

- Playbook files: no
- Guest: none. These playbooks configure the hosts the provisioning playbooks use.
