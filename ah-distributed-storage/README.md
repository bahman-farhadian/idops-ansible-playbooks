# ah-distributed-storage

Domain status: decision only (no playbook files yet)

## Purpose

Provide the Ceph cluster. OpenStack and Kubernetes do not deploy it. When a project uses Ceph, the operator runs this playbook and gives those playbooks the addresses.

## Playbook

- `ceph/`
  - One playbook
  - The project defines how many monitor guests and how many OSD guests
  - The monitor count must be odd. Make checks a change against the cluster that is already running. A set of 3 monitors cannot be raised to 4. The next valid count is 5
  - Block and image storage for OpenStack
  - CephFS is in this playbook. OpenStack is one consumer. Make requires at least 2 metadata-server guests
  - OpenStack and Kubernetes consume this cluster. They do not deploy it
  - The object gateway runs on its own guests. The project sets how many. Make requires at least 2. The monitors and the OSDs stay on their own guests
  - The administrator provides at least 2 HAProxy guests in front of the gateway. `al-traffic-management/haproxy` installs HAProxy. This playbook configures HAProxy and sets up keepalived on those guests. A single HAProxy is refused
  - MinIO is out of scope. The community edition repository was archived in 2026
  - Glance, Cinder, and CephFS addresses belong in the `ai-openstack` local settings
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
- Guests: the project defines the monitor count, the OSD count, and the object-gateway count. At least 2 object gateways. At least 2 metadata servers. At least 2 HAProxy guests in front of the gateway
