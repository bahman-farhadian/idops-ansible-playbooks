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

- No second operating-system family. Wazuh is a separate playbook in `av-security-and-compliance`. The two can be used together.

## Scope decision

- This domain is `debian-based-os-hardening/` only.
- It runs on guests that already exist. It does not provision a guest.
- The KVM host has its own hardening playbook, `ab-hypervisor-host-platform/kvm-host-hardening`. ESXi host hardening stays inside `ab-hypervisor-host-platform/esxi-host`.
- No second operating-system family.
- Lynis stays here. The security platform is `av-security-and-compliance/wazuh`.
