# ae-internal-services

Domain for in-house platform services such as DNS.

## Implemented projects

- `linux-firewall/`
  - Linux firewall pair. OPNsense is a later, separate project
  - Two guests with keepalived and a WAN VIP plus a LAN VIP
  - BIND 9 as a systemd service on both nodes
  - Recursive cache for internet names
  - Authoritative zone for local names (for example `idops-repository.idops`)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - UDP/TCP 53 on both NICs
  - OpenVPN admin profile and user profile
  - Forwarding and SNAT come from the hardening firewall role on this guest
