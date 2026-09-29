# aw-ci-cd-automation

Domain status: decision only (no playbook files yet)

## Purpose

Git hosting and CI for this environment.

## Playbook

- `gitlab/`
  - One guest
  - GitLab as a systemd service
  - Git repositories, CI, and GitLab's own database stay on that guest
  - The runner stays on this guest. A separate runner guest is a later change inside this playbook

## Alternatives

- Forgejo and Jenkins.

## Left out

- Forgejo and Jenkins

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: repositories and pipelines hosted on this guest

## Status

- Playbook files: no
- Guest: one, created by `kvm-vm-provisioning`
