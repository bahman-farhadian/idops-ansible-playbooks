# ad-network-and-connectivity

Domain for routing, addressing, and segmentation.

Domain status: the Linux firewall is the DNS guest. OPNsense is later.

## Firewall

The Linux perimeter firewall is the guest from
`ae-internal-services/linux-dns-firewall`. That guest is Debian 12,
Debian 13, Ubuntu 24.04, or Ubuntu 26.04. OS hardening applies.
Forwarding and SNAT are the hardening firewall role on that guest.

OPNsense is a later project in this domain. It uses its own install
image and its own playbook. Configuration is `config.xml` or the
HTTPS API. It does not use cloud-init, and OS hardening does not
apply.

## Status

- Linux firewall: the DNS guest
- OPNsense playbook: not started
