# Developer Workflow Standards

This repository is organized as domain directories (`aa-...`, `ab-...`, ...).

The goal is consistency across all playbook projects.

## Core Conventions

1. Every implementation project uses one playbook entrypoint file: `site.yml`.
2. Complex logic is split into `tasks/*.yml` includes from `site.yml`.
3. User-editable variables live in `vars/` with documented defaults.
4. Local environment path is `venv/` (not `.venv`) when a Python environment is needed.
5. Project commands are exposed through `Makefile` targets.
6. Each project must include:
   - `README.md` for operators
   - `DEVELOPER.md` for contributor rules

## Recommended Project Layout

- `site.yml`
- `tasks/`
- `vars/`
- `inventory.*`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`
- `README.md`
- `DEVELOPER.md`

## Commit Practice

- Commit after each coherent change set.
- Keep commit messages short and explicit.
- Prefer one intent per commit.
