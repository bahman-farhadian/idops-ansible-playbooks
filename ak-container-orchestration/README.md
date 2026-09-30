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

- Upstream: the administrator runs `aj-container-runtime/docker-engine` first, with `live_restore: false` on every member. This playbook does not call it. The host firewall already allows TCP 2377, TCP 7946, UDP 7946, and UDP 4789 between members
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
  - External etcd runs on its own guests. The control plane holds no cluster state, so Make requires at least 2 control-plane guests. Make also requires at least 3 etcd guests, and that count must be odd
  - Worker guests from local settings. Make requires at least 3, so one worker can fail and pods still have a place to run
  - vCPU, RAM, and disk size stay in local settings. Make does not fix them
  - The project picks Calico or Cilium in local settings. This playbook supports both
  - Firewall guests are not part of this playbook. A project can omit them
  - The administrator provides the bastion. It is the jump host: SSH to the bastion, then SSH to the cluster guests. This playbook does not install services on it, and it is not an API proxy
  - The administrator provides the HAProxy guests. `al-traffic-management/haproxy` installs HAProxy. This playbook configures HAProxy for the API and sets up keepalived on those guests
  - Make requires at least 2 HAProxy guests. A single HAProxy is refused
  - containerd on the control-plane and worker guests. This playbook does not use `docker-engine`
  - Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04, x86_64
  - Application pods run on the workers. This playbook does not install an ingress controller
  - This playbook does not deploy Ceph. When the administrator provides a Ceph cluster, this playbook installs the volume drivers and uses those addresses
  - Stacked minimum: 3 control-plane guests, 3 workers, and 2 HAProxy guests, plus the bastion the administrator provides
  - External minimum: 2 control-plane guests, 3 etcd guests, 3 workers, and 2 HAProxy guests, plus the bastion the administrator provides
- `docker-swarm/` stays. It is already implemented. Docker's own docs say Swarm mode still works and development has slowed in favor of Kubernetes. New clusters use `kubernetes/`. The two playbooks can be used together.
