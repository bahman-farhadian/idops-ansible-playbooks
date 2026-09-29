# ao-identity-and-access

Domain status: decision only (no playbook files yet)

## Purpose

Sign-in and access for applications.

## Playbook

- `keycloak/`
  - One guest
  - Keycloak as a systemd service
  - Its database stays on that guest

## Alternatives

- Authentik and FreeIPA.

## Left out

- FreeIPA and a separate LDAP directory. DNS stays on the `debian-based-perimeter` pair.
- Authentik

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: applications that delegate login to this guest

## Status

- Playbook files: no
- Guest: one, created by `kvm-vm-provisioning`
