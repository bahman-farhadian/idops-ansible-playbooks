# au-backup-and-disaster-recovery

Domain status: decision only (no playbook name yet)

## Purpose

Backup and restore for the stack. The product is not chosen yet. There are good open-source options. They are not the same kind of product.

## Options

A central backup service has a director, a catalog, and schedules. Clients on the other guests send backups to it.

- Bareos. AGPL. This is the open-source service with that shape: a director, a catalog, file daemons, and storage. The community build includes the core service. Some hypervisor plugins are subscription binaries. The project is still releasing, and it is used in production.
- UrBackup. AGPL. A smaller central server with a web UI, file backup, and disk images. Simpler than Bareos. Image backup fits workstations more than this server stack.
- Bacula community. AGPL, and the same shape as Bareos. More of the features sit in the paid edition. Bareos is the community fork.

A backup engine encrypts and deduplicates files into a repository. A timer or a small wrapper does the schedule. There is no director.

- restic. BSD. Widely used in production. Many storage backends, including S3. No central catalog.
- BorgBackup. BSD. Mature append-only repositories, on local disk or over SSH. No native S3.
- Kopia. Apache-2.0. The same kind of engine, plus an optional repository server and a web UI.

Veeam is the paid central service, and the backup server is mainly Windows, so it is out. Proxmox Backup Server is AGPL and tied to Proxmox. This stack uses KVM and ESXi, so that server is out.

No playbook name until one of these is accepted. No files yet. The guest count waits with the product.

## Alternatives

- Bareos, UrBackup, restic, BorgBackup, and Kopia are the open-source options.
- Veeam is paid and is out.

## Left out

- Veeam
- Proxmox Backup Server
- A second site

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guests this service needs, then `ag-os-baseline-and-hardening`
- Downstream: guests that send backups

## Status

- Playbook files: no
- Playbook name: not chosen
