# ag-os-baseline-and-hardening

Domain for operating-system baseline configuration and hardening workflows.

## Implemented Projects

- `debian-based-os-hardening/`
  - Migrated from `old_playbooks/debian-based-hardening-ansible`
  - One playbook: `playbook.yml`
  - Hardens Debian 12/13 and Ubuntu 24.04/26.04
  - Lynis scan must score at least 86
  - Firewall is iptables, not UFW
