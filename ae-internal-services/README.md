# ae-internal-services

Domain for in-house platform services such as DNS.

## Implemented projects

- `linux-dns-firewall/`
  - One guest: DNS and the Linux firewall
  - BIND 9 as a systemd service
  - Recursive cache for internet names
  - Authoritative zone for local names (for example `idops-repository.idops`)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - UDP/TCP 53, RFC1918 clients only
  - Forwarding and SNAT come from the hardening firewall role on this guest
