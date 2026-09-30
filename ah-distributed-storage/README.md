# ah-distributed-storage

Domain status: decision only (no playbook files yet)

## Purpose

Provide the Ceph cluster. OpenStack and Kubernetes do not deploy it. When a project uses Ceph, the operator runs this playbook and gives those playbooks the addresses.

## Playbook

- `ceph/`
  - One playbook
  - The project defines how many monitor guests and how many OSD guests
  - Block and image storage for OpenStack
  - OpenStack and Kubernetes consume this cluster. They do not deploy it
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

- Upstream: the guests the project already created. This playbook does not call provisioning or hardening
- Downstream: `ai-openstack` and `ak-container-orchestration/kubernetes` use the addresses when the project uses this cluster. They do not call this playbook

## Status

- Playbook files: no
- Guests: the project defines the monitor count and the OSD count
