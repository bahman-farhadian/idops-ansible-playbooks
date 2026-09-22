# ad-network-and-connectivity

Domain for routing, addressing, and the perimeter firewall.

Domain status: not started

## Firewall

The operator runs one perimeter firewall. The two projects are independent.

- Debian or Ubuntu firewall. A normal cloud-init guest on Debian 12,
  Debian 13, Ubuntu 24.04, or Ubuntu 26.04. The playbook configures
  forwarding, SNAT, DNAT, address blocks, a DMZ, OpenVPN, and WireGuard.
  OS hardening applies to this guest.
- OPNsense. Its own install image and its own playbook. Configuration is
  `config.xml` or the HTTPS API. It does not use cloud-init, and OS
  hardening does not apply.

## Status

- Operator choice recorded: yes (run one project)
- First playbook implemented: no
