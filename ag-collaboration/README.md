# ag-collaboration

Domain status: decision only (no playbook files yet)

## Purpose

Team chat and mail. These playbooks are separate and can be used together. They are not the perimeter. Shared storage is `ah-distributed-storage`.

## Playbooks

- `mattermost/`
  - Team chat. One guest. The server and its PostgreSQL database stay on that guest. No files yet
  - This playbook installs the AGPL-3.0 source build. The official Team Edition binary is MIT, for under 250 users, and it has no SSO. The paid Enterprise edition is out of scope
  - It does not use `am-databases/postgresql`
  - A deployment can point Mattermost at `aq-identity-and-access/keycloak`, or leave Mattermost with its own login. The choice is in local settings. This playbook does not require Keycloak

- `stalwart/`
  - Mail server. One guest. SMTP, IMAP, JMAP, calendar, and contacts stay on that guest. No files yet
  - This playbook installs the AGPL-3.0 community edition. The paid Enterprise edition is out of scope
  - Mailbox data stays on that guest. It does not use `am-databases/postgresql`
  - MX, SPF, DKIM, and DMARC records stay on the perimeter pair that project uses (`ae-network-and-connectivity/debian-based-perimeter` or `ae-network-and-connectivity/opnsense-firewall`)
  - A deployment can point Stalwart at `aq-identity-and-access/keycloak`, or leave Stalwart with its own login. The choice is in local settings. This playbook does not require Keycloak

## Alternatives

- Zulip, for team chat
- A Postfix and Dovecot stack, for mail

## Left out

- The project perimeter (`ae-network-and-connectivity`)

## Dependencies

- Upstream: the guests the admin provides, and the perimeter pair for Stalwart DNS records
- Downstream: people who use chat and mail

## Status

- Playbook files: no
- Review: decided
