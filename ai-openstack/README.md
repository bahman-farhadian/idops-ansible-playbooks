# ai-openstack

Domain status: decision only (no playbook files yet)

## Purpose

Deploy an OpenStack cluster. This domain is not a hypervisor, and it does not create guests.

## Playbook

- `openstack/`
  - One playbook
  - Several servers. The project defines the servers and the nodes
  - The operator prepares each server as a KVM host, then runs this playbook. The runs stay separate
  - `ab-hypervisor-host-platform/debian-based-os-install`, then `kvm-host`, then `kvm-host-hardening`
  - This playbook does not call those playbooks
  - It does not use `ac-vm-provisioning/kvm-vm-provisioning` or `ac-vm-provisioning/esxi-vm-provisioning`
  - Those guest playbooks can still be used in the same project
  - This playbook does not deploy Ceph. When the project uses Ceph for images, volumes, or CephFS, the operator provides that cluster and puts the addresses in local settings
  - The deployment tool and the service list are added when a project deploys a cluster
  - No files yet

## Alternatives

- None named.

## Left out

- Guest creation (`ac-vm-provisioning`)
- Hypervisor setup (`ab-hypervisor-host-platform`)

## Dependencies

- Upstream: the KVM hosts the operator prepared. This playbook does not call the host playbooks
- Downstream: the workloads that project places on the cluster

## Status

- Playbook files: no
- Guest: none
