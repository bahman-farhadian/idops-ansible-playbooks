# ad-network-and-connectivity

Domain status: decision only. `opnsense-firewall` is later (no files yet).

## Purpose

Provide the perimeter on OPNsense. The Debian or Ubuntu perimeter stays `ae-internal-services/debian-based-perimeter`. The two playbooks can be used together.

Where this pair runs is the admin's decision. The repository provides the playbook.

## Playbook

- `opnsense-firewall/`
  - One playbook. It covers the same perimeter job as `debian-based-perimeter`: firewall, DNS, time, and OpenVPN
  - Always a pair. CARP moves one WAN VIP and one LAN VIP. A single node is refused
  - Firewall, NAT, and routing
  - DNS on both nodes. Recursive cache for internet names, and authoritative DNS for the local names in that project's settings. Clients use the VIP
  - Time service on both nodes. Clients use the same VIP
  - OpenVPN on the pair: an admin profile and a user profile. Certificates stay on this pair
  - WireGuard is a later addition on this same pair
  - The project supplies the OPNsense image. The image stays outside git. The playbook does not download it
  - Configuration is `config.xml` or the HTTPS API. Which one is used, and how the image is written onto the machine, are chosen when this playbook is written
  - Does not use cloud-init. `ag-os-baseline-and-hardening/debian-based-os-hardening` does not apply
  - No files yet

## Alternatives

- None named. This playbook and `debian-based-perimeter` can be used together.

## Left out

- DHCP. Addresses stay in the provisioning settings
- Installing OPNsense on the Debian or Ubuntu perimeter guest
- A second playbook for DNS, time, or VPN
- OpenVPN certificates in `aq-secrets-and-pki`

## Dependencies

- Upstream: the machines the admin selects
- Downstream: the clients that use this pair

## Status

- Playbook files: no
- Pair: two nodes
