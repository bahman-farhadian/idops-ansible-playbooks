# aa-physical-server-foundation

Domain status: decision only (no playbook files yet)

## Purpose

Prepare the physical servers. This playbook does not create guests.

## Playbook

- `ilo-management/`
  - One playbook
  - BIOS settings, BIOS update, and HPE iLO on the physical servers the project names
  - Out of band for iLO
  - No files yet

The project defines which servers this playbook runs against. This domain does not fix a server count.

## Alternatives

- No second out-of-band controller was named.

## Left out

- RAID
- Guest creation (`ac-vm-provisioning`)
- Hypervisor setup (`ab-hypervisor-host-platform`)

## Dependencies

- Upstream: the physical servers
- Downstream: `ab-hypervisor-host-platform`

## Status

- Playbook files: no
- Guest: none
