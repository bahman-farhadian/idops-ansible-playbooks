# Manual Debian-based perimeter setup

This runbook follows the Ansible workflow in `playbook.yml` and `tasks/`.
Ansible is the repeatable path for the pair. Use this guide to study the
configuration or perform a controlled manual recovery. Deploy both nodes;
the project refuses a single-node perimeter.

The source of truth for variable values is `vars/firewall-ha.yml`,
`vars/bind.yml`, and `vars/chrony.yml`, plus the selected local settings.
Keep real addresses, private keys, and OpenVPN PKI material out of Git.

## 1. Confirm the pair and network plan

Before installing packages, record the two node names, each WAN and LAN
address, WAN and LAN VIPs, prefix, VRID, interfaces, DNS zone, A records,
NTP upstream, VPN pools, and VPN routes. Use one project unicast zone such
as `idops`; do not use `.local`, which systemd-resolved sends to mDNS.

The WAN NIC keeps the default route. The isolated LAN NIC has no gateway.
Both nodes must share the WAN and LAN layer-2 networks. Their keepalived
priorities must differ, and the VIPs must be unused on those networks.
OpenVPN clients reach only the routes listed in the profile; the user
profile must not receive the admin LAN route.

## 2. Prepare both Debian or Ubuntu guests

Use Debian 12/13 or Ubuntu 24.04/26.04, x86_64. Configure the two NICs
before continuing and verify the default route exits through WAN:

```bash
ip -br address
ip route
```

Apply the `ad-os-baseline-and-hardening/debian-based-os-hardening`
procedure before deploying the perimeter. Its firewall defaults to DROP;
allow the required DNS, NTP, VRRP, OpenVPN, and forwarding traffic for this
pair before enabling the hardening firewall. On admin VPN clients, add the
specific `tun-admin` to LAN forward rule in the hardening settings.

Install packages used by the roles:

```bash
sudo apt-get update
sudo apt-get install -y bind9 bind9-utils bind9-dnsutils chrony keepalived openvpn
```

Package names and service unit names may differ by release. The Ansible
deploy task reads service facts and selects `named` or `bind9` for BIND.

## 3. Configure the BIND cache and local zone

Build `named.conf.options` and `named.conf.local` from
`templates/named.conf.options.j2` and `templates/named.conf.local.j2`.
Use the configured forwarders, query ACLs, recursion policy, zone name,
TTL, records, and serial. The master zone must have empty forwarders so
private names are answered locally rather than sent to public DNS.

Build the zone file from `templates/db.zone.j2`; include the NS record and
the A records in `bind_records`. If a reverse zone is configured, build it
from `templates/db.reverse.j2` and the configured PTR records.

Check syntax and reload BIND:

```bash
named-checkconf
ZONE='idops-repository.idops'
named-checkzone "$ZONE" "/etc/bind/db.$ZONE"
systemctl enable --now bind9 || systemctl enable --now named
```

Use your configured zone and zone-file path in `named-checkzone`. Query the
server's loopback and LAN address; confirm an authoritative answer for a
local name and recursion for a public name. Firewall both UDP and TCP 53
from approved networks.

## 4. Configure chrony

Write `/etc/chrony/chrony.conf` from `templates/chrony.conf.j2`. Set the
upstream pool and client allow-list from `vars/chrony.yml`. Enable and
restart chrony on both nodes:

```bash
systemctl enable --now chrony
chronyc tracking
chronyc sources -v
```

Allow UDP 123 from the client networks in the host firewall. Clients use
the LAN VIP as their NTP server.

## 5. Configure keepalived and the firewall

Render `/etc/keepalived/keepalived.conf` from
`templates/keepalived.conf.j2` on each node. Use that node's interface,
WAN/LAN addresses, VRID, VIPs, and priority. Verify the peer has the same
VRID and VIPs but the other priority. Enable keepalived on both nodes:

Install `files/notify-openvpn.sh` at
`/etc/keepalived/notify-openvpn.sh` with mode `0750`; the keepalived sync
group calls it when the active node changes so OpenVPN listeners follow
the VIP.

```bash
systemctl enable --now keepalived
systemctl status keepalived --no-pager
ip address
```

Allow VRRP protocol 112 between the pair on both layer-2 segments. The
perimeter uses IPv4 forwarding and SNAT; the OS-hardening firewall must
have forwarding and NAT enabled for the WAN/LAN interfaces. Do not flush
firewall rules over a remote session. Check the active node owns both VIPs
and the standby owns neither before testing failover.

## 6. Configure the OpenVPN server pair

The Ansible workflow creates the PKI on the control node by running
`files/openvpn-init-pki.sh` into `artifacts/openvpn/`, then copies the CA
and server certificate material to both perimeter nodes. For a manual
setup, run that same reviewed project script on the control node after
confirming the destination is private. The current client-management
command needs `ca.key` on both nodes to issue certificates, so keep it
root-only there and protect a separate backup. Never put it in Git or
expose it to VPN users. Use `templates/openvpn-server.conf.j2` for server
configuration, `templates/vpn-peer.conf.j2` for peer configuration, and
`files/tls-verify.sh` for peer validation.

Create admin and user server configs with the ports, tunnel networks,
routes, and interfaces in `vars/firewall-ha.yml`. Admin uses TCP 1213 and
the admin route list; user uses TCP 1314 and only the user route list.
The server template uses `dh none`; do not omit it. Enable both OpenVPN
instances on both nodes with the `openvpn-server@admin` and
`openvpn-server@user` units and confirm they listen on their configured
ports.

Client profiles use `templates/vpn-client.conf.j2`. They install only
configured routes, do not change DNS, and ignore full-tunnel pushes. Keep
the client guide at `vpn-client-guide.md` for add/deactivate/remove steps.
Allow the selected TCP ports through the host firewall.

## 7. Verify DNS, time, VIP failover, and VPN

From an approved LAN client:

```bash
LAN_VIP='<configured LAN VIP>'
ZONE='idops-repository.idops'
dig @"$LAN_VIP" "ns.$ZONE" A
dig @"$LAN_VIP" example.org A
```

Use the actual zone and record values. Confirm local answers come from the
authoritative zone, external answers recurse through configured forwarders,
and time clients reach the LAN VIP. Configure a client to use the LAN VIP
as its NTP server and confirm synchronization with `chronyc tracking` on
that client. Connect one admin client and one user client; verify the admin
has only the configured admin routes and the user cannot reach the isolated
LAN. Test keepalived failover in a maintenance window and confirm both VIPs
move together.

Reconcile or change the production pair through the Ansible playbook so
settings, configuration templates, and both nodes remain consistent.
