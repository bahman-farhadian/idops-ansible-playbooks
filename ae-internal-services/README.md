# ae-internal-services

Domain for in-house platform services: the Debian-based perimeter pair, Ceph, Mattermost, and Stalwart. The playbooks are separate and can be used together.

## Alternatives

- MinIO. The community repository was archived in 2026.
- Zulip, for team chat.
- A Postfix and Dovecot stack, for mail.

## Implemented projects

- `debian-based-perimeter/`
  - Deploys the perimeter on Debian or Ubuntu. OPNsense is the other perimeter playbook. A project uses one of them.
  - Two guests with keepalived and a WAN VIP plus a LAN VIP
  - BIND 9 as a systemd service on both nodes
  - Recursive cache for internet names
  - Authoritative zone for local names (for example `idops-repository.idops`)
  - Host OS: Debian 12, Debian 13, Ubuntu 24.04, Ubuntu 26.04
  - UDP/TCP 53 on both NICs
  - OpenVPN admin profile and user profile
  - Forwarding and SNAT come from the hardening firewall role on this guest

## Scope decision

- The pair is the Debian-based perimeter: firewall, BIND, chrony, and OpenVPN on Debian or Ubuntu.
- Playbook directory: `debian-based-perimeter/`.
- OPNsense is `ad-network-and-connectivity/opnsense-firewall`. A project uses this perimeter or that one. The repository keeps both playbooks.
- chrony runs on both nodes of this pair. Clients use the same VIP they already use for DNS. This playbook does not install chrony yet.
- WireGuard stays a later addition on the same pair.
- No DHCP playbook. Addresses stay static in the provisioning settings.
- OpenVPN certificates stay on this pair. They are not moved to `aq-secrets-and-pki`.
- `ceph/` is distributed storage. The project defines how many monitor guests and how many OSD guests. No files yet. Block and image storage for OpenStack, and S3-compatible object storage through the Ceph object gateway, come from this cluster. MinIO is out of scope: the community edition repository was archived in 2026. Glance and Cinder addresses belong in the `ah-openstack` local settings.
- `mattermost/` is team chat. One guest. The server and its PostgreSQL database stay on that guest. No files yet. This playbook installs the AGPL-3.0 source build. The official Team Edition binary is MIT, for under 250 users, and it has no SSO. The paid Enterprise edition is out of scope. It does not use `al-databases/postgresql`.
- `stalwart/` is the mail server. One guest. SMTP, IMAP, JMAP, calendar, and contacts stay on that guest. No files yet. This playbook installs the AGPL-3.0 community edition. The paid Enterprise edition is out of scope. Mailbox data stays on that guest. It does not use `al-databases/postgresql`. MX, SPF, DKIM, and DMARC records stay on the perimeter pair that project uses.
