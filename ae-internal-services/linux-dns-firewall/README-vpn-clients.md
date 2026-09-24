# VPN clients

One name is one connection file. The file contains the certificate and
the private key. Give that file to the person. Anyone who has a copy
can connect as that name until the name is removed and deploy runs
again.

Admin names and user names are separate lists in the local settings
file for that stack:

- `openvpn_admin_clients` reaches `10.32.0.0/24` and `192.168.32.0/24`
- `openvpn_user_clients` reaches `192.168.32.0/24` only

A name starts with a letter and uses letters, digits, `_`, or `-`.
The same name cannot be in both lists. Each distro has its own
settings file, its own CA, and its own VIP. Add or remove the name
only on the stack that person should reach.

Debian 12 uses `vars/settings.bind9.debian-12.local.yml`. The other
files are `settings.bind9.debian-13.local.yml`,
`settings.bind9.ubuntu-24.local.yml`, and
`settings.bind9.ubuntu-26.local.yml`.

## Add a client

Put the name in the list that matches the access they need:

```yaml
openvpn_admin_clients:
- admin
- bob
openvpn_user_clients:
- user
- alice
```

From this playbook directory:

```bash
make deploy LOCAL_SETTINGS_FILE=vars/settings.bind9.debian-12.local.yml
```

Deploy writes the new file and leaves every other current file in
place. Give the person this file from the control node:

`artifacts/openvpn/clients/<name>.ovpn`

The same file is on both firewall nodes at
`/root/openvpn-clients/<name>.ovpn`. The copy on the control node is
the one to hand over. It is gitignored.

The profile adds only that list's routes. It does not change DNS, and
it does not send the rest of the person's traffic through the tunnel.
In the OpenVPN program, leave "redirect all traffic" and "block DNS"
off.

## Deactivate a client

Use this when the file leaks or the person leaves. Delete the name
from `openvpn_admin_clients` or `openvpn_user_clients`. Leave at least
one name across the two lists. Deploy refuses an empty pair of lists.

```bash
make deploy LOCAL_SETTINGS_FILE=vars/settings.bind9.debian-12.local.yml
```

Deploy rewrites `/etc/openvpn/server/allowed-admin` and
`allowed-user` from those lists. The firewall accepts a certificate
only when its name is still on the matching list. An admin name
cannot connect to the user port, and a user name cannot connect to
the admin port.

When the allow list changes, OpenVPN restarts on the node that holds
the WAN VIP. Existing sessions drop. The removed file cannot connect
again. Every name still in the lists gets a new session when that
person connects again.

## Remove the old files

The same deploy deletes the retired copies:

- `artifacts/openvpn/clients/<name>.ovpn` on the control node
- `artifacts/openvpn/<name>.crt` and `artifacts/openvpn/<name>.key` on the control node
- `/root/openvpn-clients/<name>.ovpn` on both firewall nodes

The CA and the server certificate stay. Other clients stay. A copy
the person already saved is still in their hands; deactivation is
what makes that copy fail.
