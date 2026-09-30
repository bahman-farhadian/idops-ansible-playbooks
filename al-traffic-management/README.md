# al-traffic-management

Domain status: decision only (no playbook files yet)

## Purpose

Application traffic in front of services. Each proxy is its own playbook and its own guest.

## Playbook

- `haproxy/`
  - HAProxy as a systemd service
  - One guest, except where a pair is required. The administrator provides at least 2 guests for the Kubernetes API and for the Ceph object gateway. This playbook installs HAProxy on them. `ak-container-orchestration/kubernetes` configures the API pair. `ah-distributed-storage/ceph` configures the gateway pair. Each of those playbooks sets up keepalived on its pair
  - A single HAProxy in front of the Kubernetes API or the Ceph object gateway is refused
  - Backends come from that project's local settings
- `nginx/`
  - One guest
  - Nginx as a systemd service
  - Backends come from that project's local settings

## Alternatives

- Traefik. `haproxy/` and `nginx/` are separate playbooks and can be used together.

## Left out

- The perimeter pair (`ae-internal-services/debian-based-perimeter`)
- A keepalived pair for either proxy
- Traefik, and a Swarm or Kubernetes ingress

## Dependencies

- Upstream: the guests the administrator provides. This playbook does not create them
- Downstream: services that publish through this proxy

## Status

- Playbook files: no
- Guests: the administrator provides them. One HAProxy guest, or at least two in front of the Kubernetes API or the Ceph object gateway. One Nginx guest
