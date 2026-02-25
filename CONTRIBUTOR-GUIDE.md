# Contributor Guide

This is the single contributor standard for the entire repository.

## Purpose

Use one consistent Ansible project pattern across all domain directories (`aa-*`, `ab-*`, ...).

## Scope

These rules apply to every implementation project inside this repository.

## Required Standards

1. Exactly one top-level playbook entrypoint: `site.yml`.
2. Do not create multiple top-level workflow playbooks.
3. Put workflow logic in `tasks/*.yml` and include from `site.yml`.
4. Keep user-editable runtime settings in `vars/` with documented defaults.
5. Use `venv/` as local Python environment path when needed (not `.venv`).
6. Expose user workflows through `Makefile` targets.
7. Every implementation `Makefile` must include `make ping`.
8. Every user-facing Make target must appear in `make help`.
9. Keep `help` as default Make target.

## Best-Practice Project Structure

Minimum structure for each implementation project:

- `site.yml`
- `tasks/`
- `vars/`
- `inventory.*`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `README.md`

Optional but recommended:

- `venv/` (local environment path placeholder, not committed with binaries)
- `wheelhouse/` (local wheel cache directory)
- `docs/` (operator runbooks and architecture notes)

Reference tree:

```text
<project>/
  site.yml
  tasks/
  vars/
  inventory.ini
  ansible.cfg
  requirements.txt
  Makefile
  README.md
  venv/
    .gitkeep
  wheelhouse/
    .gitkeep
```

## What Is `wheelhouse`?

`wheelhouse/` is a local cache directory for Python wheel files downloaded by pip.

Why it exists:

1. Reduces repeated dependency downloads.
2. Helps offline or restricted-network environments.
3. Makes dependency bootstrap more predictable.

Best practice:

1. Do not commit full `venv` binaries.
2. Keep only placeholders in `wheelhouse/` by default.
3. If your team decides to commit wheel artifacts, treat them as managed release artifacts and document that policy in the project README.

## Commit Practice

1. Commit after each coherent change set.
2. Keep commit messages short and explicit.
3. Prefer one intent per commit.
