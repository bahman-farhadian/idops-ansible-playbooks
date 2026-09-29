# ai-openstack

Domain status: decision only (no playbook files yet)

## Purpose

Deploy an OpenStack cluster. This domain is not a hypervisor, and it does not create guests.

## Playbook

- `openstack/`
  - One playbook
  - The project defines the servers and the nodes
  - It does not use `ac-vm-provisioning/kvm-vm-provisioning` or `ac-vm-provisioning/esxi-vm-provisioning`
  - Those guest playbooks can still be used in the same project
  - When the project uses Ceph for images or volumes, the cluster is `ah-distributed-storage/ceph` and those addresses belong in this playbook's local settings
  - The deployment tool and the service list are added when a project deploys a cluster
  - No files yet

## Alternatives

- None named.

## Left out

- Guest creation (`ac-vm-provisioning`)
- Hypervisor setup (`ab-hypervisor-host-platform`)

## Dependencies

- Upstream: the servers the project names
- Downstream: the workloads that project places on the cluster

## Status

- Playbook files: no
- Guest: none
