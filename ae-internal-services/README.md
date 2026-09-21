# ae-internal-services

Domain for in-house platform services such as DNS.

## Implemented projects

- `bind9-dns/`
  - BIND 9 as a systemd service
  - Recursive cache for internet names
  - Authoritative zone for local names (for example `idops-repository.idops`)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - UDP/TCP 53, RFC1918 clients only
