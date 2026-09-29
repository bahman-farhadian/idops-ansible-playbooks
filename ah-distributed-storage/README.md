# ah-distributed-storage

Domain status: decision only (no playbook files yet)

## Purpose

Provide shared storage for the platform. OpenStack and Kubernetes use this cluster.

## Playbook

- `ceph/`
  - One playbook
  - The project defines how many monitor guests and how many OSD guests
  - Block and image storage for OpenStack
  - Kubernetes uses this cluster
  - S3-compatible object storage through the Ceph object gateway
  - MinIO is out of scope. The community edition repository was archived in 2026
  - Glance and Cinder addresses belong in the `ai-openstack` local settings
  - How Kubernetes attaches volumes, and where the object gateway runs, are added when this playbook is written
  - No files yet

## Alternatives

- MinIO. The community repository was archived in 2026.

## Left out

- Deploying OpenStack (`ai-openstack`)
- Deploying Kubernetes (`ak-container-orchestration/kubernetes`)
- An application database

## Dependencies

- Upstream: guests from `ac-vm-provisioning`, then `ag-os-baseline-and-hardening`
- Downstream: `ai-openstack` and `ak-container-orchestration/kubernetes`, when the project uses this cluster

## Status

- Playbook files: no
- Guests: the project defines the monitor count and the OSD count
