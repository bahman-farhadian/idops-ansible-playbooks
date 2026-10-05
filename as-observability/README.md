# as-observability

Domain status: decision only (no playbook files yet)

## Purpose

Metrics and alerts for the stack. Logs stay in `at-centralized-logging`. `prometheus/` and `zabbix/` are different playbooks. Running one does not install the other. Each has its own guest. They are not installed on the same virtual machine. They can both be used in one project.

## Playbook

- `prometheus/`
  - One guest
  - Prometheus, Alertmanager, and Grafana as systemd services on that guest
  - The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - A second guest is not part of this playbook
  - Programs that expose metrics on other guests are a later task in this same playbook
  - Grafana sign-in is still open
- `zabbix/`
  - One guest
  - Zabbix server, the web UI, and its database stay on that guest. The license is GPL
  - The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - A second guest is not part of this playbook
  - Agents on other guests are a later task in this same playbook
  - Zabbix sign-in is still open
  - This playbook does not create the guest and does not call provisioning or hardening

## Alternatives

- None named. Tempo and Jaeger for tracing stay out.

## Left out

- A separate Grafana playbook. Grafana stays on the Prometheus guest
- A second guest for either playbook
- Installing Prometheus and Zabbix on the same virtual machine
- Tracing (Tempo or Jaeger)

## Dependencies

- Upstream: the guest the administrator provides. This playbook does not create it
- Downstream: dashboards and alert routes

## Status

- Playbook files: no
- Review: one guest each is decided. Sign-in is still open
