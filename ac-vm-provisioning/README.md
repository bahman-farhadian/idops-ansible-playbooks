# ac-vm-provisioning

Domain status: `kvm-vm-provisioning` is in use. `esxi-vm-provisioning` is decision only (no files yet).

## Purpose

Create a Debian or Ubuntu guest on KVM or on ESXi. The admin picks the playbook when the guest is deployed. This domain does not install application services.

## Order

1. `kvm-vm-provisioning/`
2. `esxi-vm-provisioning/`

The two are separate playbooks. They can be used together.

## Playbook

- `kvm-vm-provisioning/`
  - KVM guests from Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04 cloud images
  - Cloud images. The installer ISO stays with `ab-hypervisor-host-platform/debian-based-os-install`
  - UEFI for every guest
  - The hypervisor, the image cache, the instance disk pool, and the libvirt network stay in local settings
  - Does not install application services
  - Files are in the repo
- `esxi-vm-provisioning/`
  - The same four guest releases on ESXi
  - Does not install application services
  - No files yet
  - How the guest disk is built, and how the playbook talks to the ESXi host, are added when this playbook is written

A normal service guest is created by one of these two playbooks, then hardened by `ag-os-baseline-and-hardening/debian-based-os-hardening`, then handed to its service playbook.

## Alternatives

- None named. The KVM playbook and the ESXi playbook can be used together.

## Left out

- OpenStack. That cluster is `ai-openstack`. It does not create guests
- Hypervisor install (`ab-hypervisor-host-platform`)
- Guest hardening (`ag-os-baseline-and-hardening/debian-based-os-hardening`)
- Application services

## Dependencies

- Upstream: `aa-physical-server-foundation`, `ab-hypervisor-host-platform`
- Downstream: `ag-os-baseline-and-hardening`, then the service playbook

## Status

- `kvm-vm-provisioning`: files in the repo
- `esxi-vm-provisioning`: no files yet
