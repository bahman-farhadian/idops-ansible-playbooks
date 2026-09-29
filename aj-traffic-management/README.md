# aj-traffic-management

Domain status: decision only (no playbook files yet)

## Purpose

Application traffic in front of services. Each proxy is its own playbook and its own guest.

## Playbook

- `haproxy/`
  - One guest
  - HAProxy as a systemd service
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

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: services that publish through this proxy

## Status

- Playbook files: no
- Guests: one per playbook, created by `kvm-vm-provisioning`
