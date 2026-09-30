# al-traffic-management

Domain status: decision only (no playbook files yet)

## Purpose

Application traffic in front of services. Each proxy is its own playbook. The three playbooks can be used together.

## Playbook

- `haproxy/`
  - HAProxy as a systemd service. It is the stateless load balancer and reverse proxy
  - One guest is valid when the project accepts a single proxy. A deployment that must survive one proxy uses two guests with keepalived, because HAProxy holds no session state
  - The Kubernetes API and the Ceph object gateway are those deployments. The administrator provides at least 2 guests for each. This playbook installs HAProxy on them. `ak-container-orchestration/kubernetes` configures the API pair and sets up keepalived. `ah-distributed-storage/ceph` configures the gateway pair and sets up keepalived
  - A single HAProxy in front of the Kubernetes API or the Ceph object gateway is refused
  - Backends come from that project's local settings
  - When the project needs TLS, HAProxy terminates it. The administrator provides the certificate and the key. They stay in local settings
- `nginx/`
  - One guest. Nginx usually runs on the guest that already has the service, for example in front of gunicorn on a Unix socket. This playbook does not install that service
  - No second guest. Fault tolerance for a proxy that must survive one failure stays with HAProxy
  - Nginx as a systemd service
  - Backends come from that project's local settings
  - When the project needs TLS, Nginx terminates it. The administrator provides the certificate and the key. They stay in local settings
- `traefik/`
  - Traefik runs as a container. This playbook deploys that container, on one Docker Engine host or on a Swarm. The project chooses the target in local settings
  - The host already has Docker Engine, or it is already a Swarm member. This playbook does not install Docker Engine and does not call `aj-container-runtime/docker-engine` or `ak-container-orchestration/docker-swarm`
  - Backends come from that project's local settings
  - When the project needs TLS, Traefik terminates it. The administrator provides the certificate and the key. They stay in local settings

## Alternatives

- None named. `haproxy/`, `nginx/`, and `traefik/` are separate playbooks and can be used together.

## Left out

- The perimeter pair (`ae-internal-services/debian-based-perimeter` or `ad-network-and-connectivity/opnsense-firewall`)
- keepalived in this directory. The API pair and the gateway pair set up keepalived in `kubernetes/` and `ceph/`
- A second Nginx guest
- A Kubernetes ingress controller. `ak-container-orchestration/kubernetes` does not install one, and `traefik/` runs on Docker Engine or Swarm

## Dependencies

- Upstream: the guests the administrator provides. This playbook does not create them. For `traefik/`, Docker Engine or Swarm is already running on those guests
- Downstream: services that publish through this proxy

## Status

- Playbook files: no
- Guests: the administrator provides them. One HAProxy guest, or at least two in front of the Kubernetes API or the Ceph object gateway. One Nginx guest. Traefik is a container on one Docker host or on a Swarm
