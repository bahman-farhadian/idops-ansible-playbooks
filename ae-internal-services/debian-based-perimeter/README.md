# debian-based-perimeter

This playbook deploys the perimeter on two Debian or Ubuntu guests.
The guest OS is Debian or Ubuntu. OPNsense is a separate playbook,
`ad-network-and-connectivity/opnsense-firewall`. A project uses one
of these two perimeters.

keepalived moves one WAN VIP and one LAN VIP between the guests.
This playbook installs BIND 9, keepalived, and OpenVPN on that pair.
A single node is refused.

The first NIC is the WAN and keeps the default route. The extra NIC
is the isolated LAN and has no gateway. named listens on every IPv4
address, so both NICs answer DNS. Clients use the VIPs.

OpenVPN has two TCP profiles. Admin listens on port 1213 and its
client can reach `10.32.0.0/24` and `192.168.32.0/24`. User listens
on port 1314 and its client can reach `192.168.32.0/24` only. The
client file installs those routes and nothing else. It does not
change DNS, and it ignores a full-tunnel push.

Adding, deactivating, and removing a client is an SSH command on
the firewall. The guide is
[vpn-client-guide.md](vpn-client-guide.md). Deploy copies it to
both nodes at `/usr/local/share/doc/debian-based-perimeter/vpn-client-guide.md`.

WireGuard is a later addition on this same pair.

Install BIND 9 as a systemd service. One process does two jobs:

1. Recursive cache for internet names (forwards to the listed resolvers)
2. Authoritative DNS for a local zone (for example `idops-repository.idops`)

The host can be Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04.
Deploy gathers host facts, prints that release, and refuses any other
guest. The BIND package names are the same on all four. After install,
deploy reads the service facts and starts `named` or `bind9`, whichever
unit the package shipped.

## What it installs

- Package `bind9` from the OS stable/LTS archive
- A forward zone (`bind_zone`) with A records from local settings
- Optional reverse (`in-addr.arpa`) zone
- Queries and recursion limited to loopback and RFC1918

The host firewall must allow UDP 53 and TCP 53 from the networks that
should use this server.

Clients set this host as their resolver. They then use names such as
`deb.idops-repository.idops` instead of a raw IP.

Local master zones set empty `forwarders`. Global `forward only` would
otherwise send recursive queries for a private TLD to 1.1.1.1/8.8.8.8,
which return NXDOMAIN. Deploy also checks the answer on the guest IPv4,
not only on 127.0.0.1.

Do not use a `.local` zone. systemd-resolved sends `.local` to multicast
DNS (RFC 6762) and never asks this server for those names. Use a unicast
TLD such as `.idops`.

## Local settings

You must pass a `*.local.yml` file. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.debian-based-perimeter.local.yml
```

Put the real host in `bind_targets`. Put A records in `bind_records`.
Do not put real addresses in tracked vars.

## Commands

```bash
make help
make ping LOCAL_SETTINGS_FILE=vars/settings.debian-based-perimeter.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.debian-based-perimeter.local.yml
```
