# aq-observability

Domain status: decision only (no playbook files yet)

## Purpose

Metrics and alerts for the stack. `prometheus/` and `zabbix/` are separate playbooks. They can be used together.

## Playbook

- `prometheus/`
  - One guest
  - Prometheus, Alertmanager, and Grafana as systemd services
  - Exporters on other guests are a later task in this same playbook
- `zabbix/`
  - One guest
  - Zabbix server, the web UI, and its database on that guest
  - Agents on other guests are a later task in this same playbook
  - GPL, self-hosted, and used in production

## Alternatives

- A separate Grafana playbook. Tempo and Jaeger for tracing.

## Left out

- A separate Grafana playbook
- Tracing (Tempo or Jaeger)

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: dashboards and alert routes

## Status

- Playbook files: no
- Guests: one per playbook, created by `kvm-vm-provisioning`
