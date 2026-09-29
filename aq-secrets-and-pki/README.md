# aq-secrets-and-pki

Domain status: decision only (no playbook files yet)

## Purpose

A secrets store and an internal certificate authority.

## Playbook

- `vault/`
  - One guest
  - HashiCorp Vault as a systemd service
  - Secrets and certificates for services that opt in
  - Kept from the earlier decision. The license is BSL 1.1, so this playbook does not meet the open-source rule. OpenBao is MPL 2.0 and is the open-source match. It is not this playbook yet.

## Alternatives

- OpenBao is the open-source match. step-ca was left out. OpenVPN certificates stay on the `debian-based-perimeter` pair.

## Left out

- OpenBao
- OpenVPN certificates. Those stay on the `debian-based-perimeter` pair
- A separate step-ca playbook

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: services that request a secret or a certificate

## Status

- Playbook files: no
- Guest: one, created by `kvm-vm-provisioning`
