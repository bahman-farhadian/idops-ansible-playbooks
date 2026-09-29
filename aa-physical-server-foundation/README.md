# aa-physical-server-foundation

Domain status: decision only (no playbook files yet)

## Purpose

Prepare HPE physical servers so an operating system or a hypervisor can be installed afterwards. The project names the servers. This domain does not fix a server count. There is no guest.

## Playbook

- `ilo-management/`
  - One playbook
  - HPE servers only
  - BIOS settings, BIOS update, and iLO
  - No files yet

## Before Ansible

On each iLO, by hand:

- Install the iLO license
- Set the iLO IP address
- Set the iLO user and password

The address, user, and password then live in gitignored local settings. The playbook uses those values.

## Connection

The control node manages iLO over the iLO HTTP API, with Ansible's iLO modules in `community.general`. The host operating system is a later path, in `ab-hypervisor-host-platform`, after an operating system is installed.

## Firmware

The user supplies the HPE SPP ISO. The playbook does not download it. The ISO stays outside the git repository. Local settings point at the file.

## After this playbook

The server is ready for whatever operating system or hypervisor the project installs next. `kvm-host` and `esxi-host` both start from a host that already has that software installed.

## Later, on the server the project is working on

These are added when a project reaches that server. This decision does not fix them.

- Which iLO and BIOS settings a run applies
- The BIOS values
- When a run may reboot the server
- Disk and RAID layout. A server that will host a Kubernetes worker and a server that will be a bulk NFS mount use different layouts. There is no separate RAID playbook.

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
