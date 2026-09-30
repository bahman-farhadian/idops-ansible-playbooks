# al-traffic-management

Domain status: decision only (no playbook files yet)

## Purpose

Application traffic in front of services. Each proxy is its own playbook and its own guest.

## Playbook

- `haproxy/`
  - HAProxy as a systemd service
  - One guest, except the Kubernetes API. The administrator provides at least 2 guests for that API. This playbook installs HAProxy on them. `ak-container-orchestration/kubernetes` configures HAProxy and sets up keepalived on those guests
  - A single HAProxy in front of the Kubernetes API is refused
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
- Guests: the administrator provides them. One HAProxy guest, or at least two when they front the Kubernetes API. One Nginx guest
