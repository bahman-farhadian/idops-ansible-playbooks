# at-security-and-compliance

Domain status: decision only (no playbook files yet)

## Purpose

One security platform for the guests that are already hardened.

## Playbook

- `wazuh/`
  - One manager guest
  - Wazuh manager as a systemd service
  - Wazuh is the open-source security monitor (GPL). The manager collects alerts. Agents on the other machines send logs, file-integrity checks, and intrusion checks. It is the self-hosted monitor when the stack does not use a paid SIEM
  - Agents on other guests are a later task in this same playbook
  - Does not change the Lynis score in `ag-os-baseline-and-hardening`

## Alternatives

- OpenSCAP and Security Onion. Lynis stays in `ag-os-baseline-and-hardening`. The two playbooks can be used together.

## Left out

- OpenSCAP as its own playbook
- Security Onion
- A second Lynis playbook. Lynis stays in `ag-os-baseline-and-hardening/debian-based-os-hardening`

## Dependencies

- Upstream: `ac-vm-provisioning` creates the manager guest, then `ag-os-baseline-and-hardening`
- Downstream: alerts and reports from the agents

## Status

- Playbook files: no
- Guest: one manager, created by `kvm-vm-provisioning`
