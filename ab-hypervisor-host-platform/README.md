# ab-hypervisor-host-platform

Domain status: decision only (no playbook files yet)

## Purpose

Install the operating system or ESXi on the physical server, then prepare a KVM host or an ESXi host. KVM and ESXi are both required. A server takes one path. A project can use both paths on different servers.

## Order

1. `debian-based-os-install/`
2. `kvm-host/`
3. `kvm-host-hardening/`
4. `esxi-host/`

A KVM server runs 1, then 2, then 3. An ESXi server runs 4 only. `esxi-host` is the last playbook in this directory.

A later role, such as a Kubernetes worker or a bulk NFS server, runs 1 and then a setup playbook outside this directory when that project exists. Those role playbooks are not part of this decision.

## Playbook

- `debian-based-os-install/`
  - One playbook for Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04
  - The project supplies the ISO. The ISO stays outside the git repository. Local settings point at the file.
  - The release is the ISO
  - Baseline install. The server can later become a KVM host, a Kubernetes worker, a bulk NFS server, or another role
  - No files yet
- `kvm-host/`
  - Runs after `debian-based-os-install/`
  - SSH is up. `gather_facts` reports Debian or Ubuntu, and the playbook follows that result
  - libvirt, storage pools, and bridges
  - Does not create guests
  - No files yet
- `kvm-host-hardening/`
  - Hardening specialized for the KVM host
  - Guest hardening stays `ag-os-baseline-and-hardening/debian-based-os-hardening`
  - No files yet
- `esxi-host/`
  - Final playbook in this directory
  - Used when the server will be an ESXi host. That server does not run `debian-based-os-install/`
  - Installs ESXi from the ISO the project supplies, then datastores, virtual switches, port groups, and the host hardening
  - Hardening stays inside this playbook
  - The Makefile validates the ISO against the server generation. Gen9's published HPE list stops at ESXi 7.0 U3. Gen10 is not pinned to one release: many Gen10 models are listed for ESXi 8 and for ESXi 9. The exact image is the one the project supplies for that server
  - Does not create guests
  - No files yet

## Alternatives

- None named. KVM and ESXi are separate paths and can be used together on different servers.

## Left out

- `ilo-4-management` and `ilo-5-management` in `aa-physical-server-foundation`. iLO 6 and iLO 7 are later playbooks there
- Disk and RAID layout. That follows the role of each physical server and is added when the project reaches that server
- Guest creation (`ac-vm-provisioning/kvm-vm-provisioning` and `ac-vm-provisioning/esxi-vm-provisioning`)
- Guest hardening (`ag-os-baseline-and-hardening/debian-based-os-hardening`)
- A Kubernetes-worker playbook and a bulk NFS playbook. Those are later setup playbooks outside this directory

## Dependencies

- Upstream: `aa-physical-server-foundation`
- Downstream: `ac-vm-provisioning` for guests. A non-hypervisor role continues in its own later playbook

## Status

- Playbook files: no
- Guest: none
