# ae-network-and-connectivity

Domain status: in use (`debian-based-perimeter`). `opnsense-firewall` is later (no files yet).

## Purpose

Provide the project perimeter: firewall, DNS, time, and OpenVPN. A project uses one of the two playbooks in this domain. The repository keeps both.

Where the pair runs is the admin's decision. The repository provides the playbook.

## Playbooks

- `debian-based-perimeter/`
  - Deploys the perimeter on Debian or Ubuntu. OPNsense is the other perimeter playbook. A project uses one of them
  - Two guests with keepalived and a WAN VIP plus a LAN VIP. A single node is refused
  - BIND 9 as a systemd service on both nodes
  - chrony as NTP on both nodes. Clients use the LAN VIP, the same address as DNS
  - Recursive cache for internet names
  - Authoritative zone for local names (for example `idops-repository.idops`)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - UDP/TCP 53 on both NICs
  - OpenVPN admin profile and user profile
  - Forwarding and SNAT come from the hardening firewall role on this guest
  - Files are in the repo

- `opnsense-firewall/`
  - One playbook. It covers the same perimeter job: firewall, DNS, time, and OpenVPN
  - Always a pair. CARP moves one WAN VIP and one LAN VIP. A single node is refused
  - The project supplies the OPNsense image. The image stays outside git. The playbook does not download it
  - Configuration is `config.xml` or the HTTPS API. Which one is used, and how the image is written onto the machine, are chosen when this playbook is written
  - Does not use cloud-init. `ad-os-baseline-and-hardening/debian-based-os-hardening` does not apply
  - When the project uses this perimeter, MX, SPF, DKIM, and DMARC for Stalwart are published on this pair
  - WireGuard is a later addition on this same pair
  - No files yet

## Alternatives

- None named. A project uses `debian-based-perimeter` or `opnsense-firewall`.

## Left out

- DHCP. Addresses stay in the provisioning settings
- Installing OPNsense on the Debian or Ubuntu perimeter guest
- A second playbook for DNS, time, or VPN
- OpenVPN certificates in `ar-secrets-and-pki`
- Mattermost and Stalwart (`ag-collaboration`)

## Dependencies

- Upstream: the guests the admin provides. Harden Debian or Ubuntu perimeter guests with `ad-os-baseline-and-hardening` first. OPNsense guests skip that playbook
- Downstream: LAN guests that use the LAN VIP for DNS, NTP, and their default route. OpenVPN clients that are not on the hypervisor

## Status

- `debian-based-perimeter` playbook files: yes
- `opnsense-firewall` playbook files: no
- Pair: two nodes
