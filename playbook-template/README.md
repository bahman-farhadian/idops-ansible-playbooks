# playbook-template

Copy this directory when you start a new Ansible project in this repository.

## Purpose

It follows repository standards:

1. One playbook (`playbook.yml`)
2. Workflow logic in `tasks/`
3. User-editable settings in `vars/`
4. Standard `Makefile` with `make help` and `make ping`
5. Ignored `venv/` local environment path and optional `wheelhouse/` dependency cache

## How To Use

1. Copy this directory to your target location.
2. Rename copied directory using kebab-case.
3. Rename `vars/template-config.yml` to a name that fits the new project.
   Keep safe defaults in that file (see "Machine-Local Settings" in
   `CONTRIBUTOR-GUIDE.md`). Leave blank only passwords, SSH keys, and real
   host addresses. Put those real values in a named `*.local.yml` file,
   never in the tracked file.
4. Replace placeholder tasks in `tasks/provision.yml` and `tasks/cleanup.yml`.
5. Keep every user command in `make help`.
6. This copy already has `make settings` and the local-file check in
   `playbook.yml`. You must pass `LOCAL_SETTINGS_FILE`. There is no
   default. Do not add `LIMIT=` / `--limit`. Rename
   `template_local_settings_file` and `template_action` to names that fit
   the new project.

Do not commit files under `venv/` or `.venv/`. Virtual environments are local,
path-sensitive runtime artifacts and must be recreated with `make venv`.

## Security Note

Most settings in `vars/template-config.yml` are safe examples, not real
hosts. Leave `template_operator_password` and
`template_operator_ssh_public_keys` blank. Set real values in a named
`*.local.yml` file:

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml
```

Do not put real values in the tracked file.

## Quick Start

```bash
make venv
make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml
# edit the real values that file just wrote
# for a second deployment: make settings LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml
make check LOCAL_SETTINGS_FILE=vars/settings.local.yml
make ping LOCAL_SETTINGS_FILE=vars/settings.local.yml
make provision LOCAL_SETTINGS_FILE=vars/settings.local.yml
```
