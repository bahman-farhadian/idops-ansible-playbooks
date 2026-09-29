# ag-os-baseline-and-hardening

Domain for operating-system baseline configuration and hardening workflows.

## Implemented Projects

- `debian-based-os-hardening/`
  - Migrated from `old_playbooks/debian-based-hardening-ansible`
  - One playbook: `playbook.yml`
  - Hardens Debian 12/13 and Ubuntu 24.04/26.04
  - Lynis scan must score at least 86
  - Firewall is iptables, not UFW

## Alternatives

- No second operating-system family. Wazuh is a separate playbook in `at-security-and-compliance`. The two can be used together.

## Scope decision

- This domain is `debian-based-os-hardening/` only.
- It runs on guests that already exist. It does not provision a guest.
- No second operating-system family.
- Lynis stays here. The security platform is `at-security-and-compliance/wazuh`.
