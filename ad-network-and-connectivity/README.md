# ad-network-and-connectivity

Domain for routing, addressing, and segmentation.

Domain status: `opnsense-firewall` is later. The Debian or Ubuntu perimeter is a separate playbook.

## Firewall

`ae-internal-services/debian-based-perimeter` deploys the perimeter
on Debian or Ubuntu: firewall, BIND, chrony, and OpenVPN on that
pair. chrony is in scope and is not installed yet. The guest is
Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04. OS hardening
applies. Forwarding and SNAT are the hardening firewall role on
that guest.

OPNsense is a separate playbook in this domain, `opnsense-firewall/`.
It uses its own install image. Configuration is `config.xml` or the
HTTPS API. It does not use cloud-init, and OS hardening does not
apply. The two playbooks can be used together.

## Scope decision

- The only playbook name in this domain is `opnsense-firewall/`.
- It stays later: own install image, `config.xml` or the HTTPS API. No files yet.
- No DHCP playbook. Guest addresses stay in the provisioning settings for each instance.
- Routing and segmentation for the current stacks stay on `ae-internal-services/debian-based-perimeter`.

## Alternatives

- None named.

## Status

- Debian-based perimeter: `ae-internal-services/debian-based-perimeter`
- `opnsense-firewall/`: not started
