# ak-container-orchestration

Domain status: in use

## Purpose

Container orchestration. `kubernetes/` and `docker-swarm/` are separate playbooks. They can be used together. New clusters use `kubernetes/`. `docker-swarm/` is the playbook already in the repo.

## Implemented projects

- `docker-swarm/`
  - Initialize an odd set of managers and join workers
  - Optional node labels and overlay networks
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04, x86_64
  - Does not install the engine and does not open firewall ports

## Dependencies

- Upstream: `aj-container-runtime/docker-engine` with `live_restore: false`
  on every member, and a host firewall that already allows TCP 2377,
  TCP 7946, UDP 7946, and UDP 4789 between members
- Downstream: workloads that schedule onto the cluster

## Execution Notes

Install the engine first. Then run `docker-swarm`. A later engine
deploy on a member keeps the Swarm membership if live-restore stays
false.

## Alternatives

- None named.

## Scope decision

- `kubernetes/` is the production cluster. No files yet.
  - kubeadm, the upstream install path
  - Two etcd layouts. The project picks one in local settings
  - Stacked etcd runs on the control-plane guests. Make requires at least 3 control-plane guests, and that count must be odd
  - External etcd runs on its own guests. Make requires at least 3 control-plane guests and at least 3 etcd guests. The etcd count must be odd
  - Worker guests from local settings. Make requires at least 3
  - vCPU, RAM, and disk size stay in local settings. Make does not fix them
  - Firewall guests and a bastion are not part of this playbook. A project can omit them
  - A single HAProxy in front of the API is refused
  - containerd on the control-plane and worker guests. This playbook does not use `docker-engine`
  - This playbook does not deploy Ceph. When the project uses Ceph, the operator provides that cluster and puts the addresses in local settings
- `docker-swarm/` stays. It is already implemented. Docker's own docs say Swarm mode still works and development has slowed in favor of Kubernetes. New clusters use `kubernetes/`. The two playbooks can be used together.
