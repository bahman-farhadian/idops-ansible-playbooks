# aq-identity-and-access

Domain status: decision only (no playbook files yet)

## Purpose

Sign-in for web applications. A person is created once in Keycloak. A deployment can point a web application at this guest, or leave that application with its own login. Pointing at Keycloak is not mandatory. The choice is in that deployment's local settings. This playbook does not turn the connection on. SSH into a virtual machine stays a separate login. Vault keeps its own login.

## Playbook

- `keycloak/`
  - One guest
  - Keycloak as a systemd service. The license is Apache 2.0. The Red Hat subscription build stays out
  - The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - Its database stays on that guest. It does not use `am-databases/postgresql`
  - A second guest is not part of this playbook. Keycloak and its database stay together at any scale
  - This playbook does not create the guest and does not call provisioning or hardening

## Alternatives

- Authentik and FreeIPA. `keycloak/` is the sign-in playbook.

## Left out

- A second Keycloak guest
- FreeIPA and a separate LDAP directory. DNS stays on the `debian-based-perimeter` pair
- Authentik
- SSH login to virtual machines
- Vault login. Vault keeps its own login

## Dependencies

- Upstream: the guest the administrator provides. This playbook does not create it
- Downstream: web applications that delegate login to this guest

## Status

- Playbook files: no
- Review: decided
- Guest: one
