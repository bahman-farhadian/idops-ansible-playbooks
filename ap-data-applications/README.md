# ap-data-applications

Domain status: decision only (no playbook files yet)

## Purpose

Internal data applications. Metabase and Superset are different playbooks, `metabase/` and `superset/`. Running one does not install the other. Each playbook has its own guest. The application and its database stay on that guest. They are not installed on the same virtual machine.

## Playbook

- `metabase/`
  - One guest
  - Metabase as a systemd service. The open-source edition is AGPL-3.0. The paid edition stays out
  - The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - Its application database stays on that guest. It does not use `am-databases/postgresql`
  - A second guest is not part of this playbook. The application and the database stay together at any scale
  - A deployment can point Metabase at `aq-identity-and-access/keycloak`, or leave Metabase with its own login. The choice is in local settings. This playbook does not require Keycloak
- `superset/`
  - One guest
  - Apache Superset as a systemd service. The license is Apache 2.0
  - The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - Its metadata database stays on that guest. It does not use `am-databases/postgresql`
  - A second guest is not part of this playbook. The application and the database stay together at any scale
  - A deployment can point Superset at `aq-identity-and-access/keycloak`, or leave Superset with its own login. The choice is in local settings. This playbook does not require Keycloak

## Alternatives

- None named. `metabase/` and `superset/` are separate playbooks. Each playbook targets its own guest.

## Left out

- A second guest for either application
- One playbook that installs both applications
- Installing Metabase and Superset on the same virtual machine
- A requirement that either guest use `am-databases/postgresql`

## Dependencies

- Upstream: the guest the administrator provides. This playbook does not create it and does not call provisioning or hardening
- Downstream: people querying data through the web UI

## Status

- Playbook files: no
- Review: decided
- Guests: one per playbook
