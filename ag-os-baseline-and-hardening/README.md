# ag-os-baseline-and-hardening

Domain status: in use

## Purpose

Harden Debian and Ubuntu guests that already exist. This domain does not create the guest.

## Playbook

- `debian-based-os-hardening/`
  - One playbook for Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04
  - A normal guest is created by `ac-vm-provisioning`, hardened here, then handed to its service playbook
  - Firewall is iptables. Lynis stays here. The minimum score is 86
  - SSH listens on port 2222. The first user is `idops`
  - `dist-upgrade` runs here
  - APT URLs stay in that guest's local settings. The project points them at Nexus when that cache exists
  - Files are in the repo

## Alternatives

- None named. Wazuh is `av-security-and-compliance/wazuh`. The two can be used together.

## Left out

- A second operating-system family
- Creating the guest
- KVM host hardening (`ab-hypervisor-host-platform/kvm-host-hardening`)
- ESXi host hardening (`ab-hypervisor-host-platform/esxi-host`)
- OPNsense (`ad-network-and-connectivity/opnsense-firewall`)

## Dependencies

- Upstream: the guest. `ac-vm-provisioning` creates it when the project uses those playbooks
- Downstream: the service playbook for that guest

## Status

- Playbook files: yes
