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
  - A deployment can point Grafana at `aq-identity-and-access/keycloak`, or leave Grafana with its own login. The choice is in local settings. This playbook does not require Keycloak
- `zabbix/`
  - One guest
  - Zabbix server, the web UI, and its database stay on that guest. The license is AGPL-3.0
  - The playbook pins Zabbix 7.0 LTS. That is the newest stable long-term release. Kubernetes monitoring templates are included for 7.0 and higher. Zabbix 8.0 LTS is still a release candidate, so it is not the pin. The pin moves to 8.0 LTS only after that release is stable
  - A second guest is not part of this playbook
  - Agents on other guests are a later task in this same playbook. Kubernetes monitoring is one of those later tasks
  - A deployment can point the Zabbix web page at `aq-identity-and-access/keycloak`, or leave Zabbix with its own login. The choice is in local settings. This playbook does not require Keycloak
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
- Review: decided
