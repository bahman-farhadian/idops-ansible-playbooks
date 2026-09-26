# VPN clients

This firewall is the Linux alternative to OPNsense. OpenVPN clients
are created on the firewall over SSH. Ansible installs OpenVPN and
this guide. It does not add or remove clients.

One name is one connection file. The file contains the certificate
and the private key. Give that file to the person. Anyone who has a
copy can connect as that name until the name is deactivated.

SSH to either firewall node as root. The command updates both nodes.

```bash
ssh -p 2222 root@<wan-address>
vpn-client add user alice
```

`<wan-address>` is the WAN address of either node, or the WAN VIP once
keepalived is up.
The guide on the firewall is `/usr/local/share/doc/linux-firewall/vpn-client-guide.md`.

## Profiles

`admin` connects with TCP to port 1213 and reaches `10.32.0.0/24`
and `192.168.32.0/24`.

`user` connects with TCP to port 1195 and reaches `192.168.32.0/24`
only.

The connection file adds only those routes. It does not change DNS,
and it does not send the rest of the person's traffic through the
tunnel. In the OpenVPN program, leave "redirect all traffic" and
"block DNS" off.

A name starts with a letter and uses letters, digits, `_`, or `-`.
The same name cannot be on both profiles.

Each distro pair has its own CA and its own VIP. Run the command on
the pair that person should reach.

## Add a client

```bash
vpn-client add admin bob
vpn-client add user alice
```

The command prints the connection file:

`/root/openvpn-clients/<name>.ovpn`

That file is also copied to the other firewall node. Give the person
that one file. There is no separate key file.

## Deactivate a client

Use this when the file leaks or the person leaves, and you may want
the same file to work again later.

```bash
vpn-client deactivate alice
```

The name is taken off the allow list on both nodes. OpenVPN restarts
on the node that holds the WAN VIP, so the current session ends and
that file cannot connect again. The file stays on the firewall.

To let the same file work again:

```bash
vpn-client add user alice
```

## Remove a client

Use this when the file should not be kept on the firewall.

```bash
vpn-client remove alice
```

This deactivates the name and deletes `/root/openvpn-clients/alice.ovpn`
plus that client's certificate and private key on both nodes. A copy
the person already saved is still in their hands. Deactivation is
what makes that copy fail. Adding the same name later creates a new
file. The old copy does not start working again.
