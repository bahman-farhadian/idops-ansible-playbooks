# aa-physical-server-foundation

Domain status: decision only (no playbook files yet)

## Purpose

Prepare HPE physical servers so an operating system or a hypervisor can be installed afterwards. The project names the servers. This domain does not fix a server count. There is no guest.

iLO 4 and iLO 5 are separate playbooks. A server belongs to one of them. The two can be used together when a project has both generations. iLO 6 and iLO 7 are later playbooks. They are not in this decision.

## Playbook

- `ilo-4-management/`
  - iLO 4 servers only
  - BIOS settings, BIOS update, and iLO
  - Ansible's `hpilo_*` modules in `community.general`, over the iLO HTTP API. Those modules need the `hpilo` package.
  - No files yet
- `ilo-5-management/`
  - iLO 5 servers only
  - BIOS settings, BIOS update, and iLO
  - Same `hpilo_*` modules and the same `hpilo` package
  - No files yet

## Before Ansible

On each iLO, by hand:

- Install the iLO license
- Set the iLO IP address
- Set the iLO user and password

The address, user, and password then live in gitignored local settings. The playbook uses those values.

## Firmware

The user supplies the HPE SPP ISO for that generation. The playbook does not download it. The ISO stays outside the git repository. Local settings point at the file.

## After these playbooks

The server is ready for whatever operating system or hypervisor the project installs next. `kvm-host` and `esxi-host` both start from a host that already has that software installed.

## Later, on the server the project is working on

These are added when a project reaches that server. This decision does not fix them.

- Which iLO and BIOS settings a run applies
- The BIOS values
- When a run may reboot the server
- Disk and RAID layout. A server that will host a Kubernetes worker and a server that will be a bulk NFS mount use different layouts. There is no separate RAID playbook.

## Later playbooks

- `ilo-6-management/` and `ilo-7-management/` when a project has those generations. iLO 6 does not serve the older HTTP API the `hpilo_*` modules use, so those playbooks are not a copy of the iLO 4 and iLO 5 playbooks.

## Alternatives

- Dell and Supermicro. Out for now.

## Left out

- A second vendor
- Installing the operating system or the hypervisor
- Guest creation (`ac-vm-provisioning`)
- Hypervisor setup (`ab-hypervisor-host-platform`)

## Dependencies

- Upstream: an HPE server whose iLO already has a license, an IP address, and a user
- Downstream: the operating system or hypervisor install, then `ab-hypervisor-host-platform`

## Status

- Playbook files: no
- Guest: none
