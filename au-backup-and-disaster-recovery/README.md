# au-backup-and-disaster-recovery

Domain status: decision only (no playbook files yet)

## Purpose

Backup of the virtual machine disk, taken from the KVM host while the guest is running. This is not a copy of files from inside the guest. A database replica is not a backup.

## Playbook

- `virtnbdbackup/`
  - One backup guest. The backup files stay on an extra disk on that guest. The disk size stays in local settings
  - The playbook installs virtnbdbackup 2.53, published 7 September 2026. The license is GPL-3.0. The pin stays on 2.53 while the restore test below is open
  - virtnbdbackup runs on the backup guest and talks to libvirt on the KVM host. It does not install a client inside the virtual machine. The virtual machine stays running
  - A full run copies the disks. A later run copies the blocks that changed. Incremental backup needs qcow2. `virtnbdrestore` rebuilds the disk from that chain. Both commands are command line
  - The QEMU guest agent freezes the filesystems for the start of the copy. Without it, the disk is the same as after a sudden power loss
  - A systemd timer on the backup guest runs the job. The playbook does not create the KVM host and does not call provisioning or hardening
  - Each job publishes its result. Prometheus scrapes that result. `as-observability/grafana` shows it on a backup dashboard. This playbook does not install Grafana
  - Evaluation still open. A full backup and an incremental of a real guest must be restored onto another disk, and that virtual machine must boot, before this is the backup the stack depends on

## Alternatives

- Bareos and UrBackup, central file-backup services. restic, BorgBackup, and Kopia, file-backup engines. None of them take the virtual machine disk from a plain libvirt host.

## Left out

- Veeam. Paid, and the backup server is Windows
- Proxmox Backup Server. It backs up Proxmox guests. These hosts are libvirt
- The Bareos, VMware, and Hyper-V plugins. Paid, and they do not speak to a plain libvirt host
- A backup program written in this playbook. Libvirt starts the copy. virtnbdbackup stores the chain and restores it
- Copying a live disk file with `qemu-img` while the guest is running

## Dependencies

- Upstream: the backup guest and the KVM host the administrator provides. This playbook does not create them
- Downstream: a restored virtual machine disk, and the backup dashboard in Grafana

## Status

- Playbook files: no
- Review: virtnbdbackup is chosen. A real restore test is still open
