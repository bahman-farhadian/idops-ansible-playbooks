# bind9-dns

Install BIND 9 as a systemd service. One process does two jobs:

1. Recursive cache for internet names (forwards to the listed resolvers)
2. Authoritative DNS for a local zone (for example `idops-repository.local`)

The host can be Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04.

## What it installs

- Package `bind9` from the OS stable/LTS archive
- A forward zone (`bind_zone`) with A records from local settings
- Optional reverse (`in-addr.arpa`) zone
- Queries and recursion limited to loopback and RFC1918

The host firewall must allow UDP 53 and TCP 53 from the networks that
should use this server.

Clients set this host as their resolver. They then use names such as
`deb.idops-repository.local` instead of a raw IP.

`.local` is also used by multicast DNS on some desktops. Guests in this
stack use this BIND server as their unicast resolver. On Ubuntu, turn
multicast DNS off in the hardening settings so `.local` is sent here.

## Local settings

You must pass a `*.local.yml` file. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.bind9.local.yml
```

Put the real host in `bind_targets`. Put A records in `bind_records`.
Do not put real addresses in tracked vars.

## Commands

```bash
make help
make ping LOCAL_SETTINGS_FILE=vars/settings.bind9.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.bind9.local.yml
```
