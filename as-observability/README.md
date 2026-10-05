# as-observability

Domain status: decision only (no playbook files yet)

## Purpose

Metrics and alerts for the stack. Logs stay in `at-centralized-logging`. `prometheus/` and `zabbix/` are different playbooks. Running one does not install the other. They are not installed on the same virtual machine. They can both be used in one project.

## Playbook

- `prometheus/`
  - One guest
  - Prometheus, Alertmanager, and Grafana as systemd services on that guest
  - PostgreSQL stays on that guest. It is the database for Grafana. It is not installed on another machine. It does not use `am-databases/postgresql`. The playbook pins PostgreSQL 18. That is the current stable major release. The current minor is 18.6, published 13 Aug 2026. Support runs through 14 Nov 2030. PostgreSQL 19 is still a beta, so it is not the pin
  - Prometheus keeps the metrics on its own disk on that guest. It does not use PostgreSQL
  - The playbook pins Prometheus 3.13 LTS. That is the current long-term release on the official download page. The maintenance release is 3.13.4, published 29 Sep 2026. Support runs through 31 Jul 2027. The license is Apache 2.0. Prometheus 3.15.0 is a newer stable release, so it is not the pin. The pin stays on 3.13
  - Alertmanager has no long-term release. The pin is 0.34.1, the current stable release on the official download page, published 17 Sep 2026. The license is Apache 2.0. Release candidates stay out
  - Grafana is the open-source edition. The license is AGPL-3.0. The paid edition stays out. Grafana does not publish a long-term line. The pin is 12.4, the last minor of Grafana 12. That line has extended patch support through 24 May 2027. The pin stays on 12.4
  - A second guest is not part of this playbook
  - Adding a machine is a later task in this same playbook. That task installs the node exporter on a machine the administrator already has. The node exporter pin is 1.12.1, the current stable release on the official download page, published 14 Jul 2026. It has no long-term release. The task uses its own local settings file. It does not create the guest
  - Kubernetes monitoring is a later task in this same playbook
  - Alerts go to a broadcast channel in `ae-internal-services/mattermost`. Sending them is a later task in this same playbook. The channel stays in local settings
  - A deployment can point Grafana at `aq-identity-and-access/keycloak`, or leave Grafana with its own login. The choice is in local settings. This playbook does not require Keycloak
  - This playbook does not create the guest and does not call provisioning or hardening
- `zabbix/`
  - One guest
  - Zabbix server, the web UI, and PostgreSQL stay on that guest. This PostgreSQL is for Zabbix. It is not installed on another machine. It does not use `am-databases/postgresql`, and it is not the PostgreSQL on the Prometheus guest. The playbook pins PostgreSQL 18, the same line as Grafana's database. Zabbix 7.0 supports PostgreSQL 18. The license is AGPL-3.0
  - The playbook pins Zabbix 7.0 LTS. That is the newest stable long-term release. Kubernetes monitoring templates are included for 7.0 and higher. Zabbix 8.0 LTS is still a release candidate, so it is not the pin. The pin moves to 8.0 LTS only after that release is stable
  - A second guest is not part of this playbook
  - Adding a machine is a later task in this same playbook. That task installs the Zabbix agent on a machine the administrator already has. The agent pin is Zabbix 7.0 LTS. The task uses its own local settings file. It does not create the guest
  - Kubernetes monitoring is a later task in this same playbook
  - Alerts go to a broadcast channel in `ae-internal-services/mattermost`. Sending them is a later task in this same playbook. The channel stays in local settings
  - A deployment can point the Zabbix web page at `aq-identity-and-access/keycloak`, or leave Zabbix with its own login. The choice is in local settings. This playbook does not require Keycloak
  - This playbook does not create the guest and does not call provisioning or hardening

## Alternatives

- None named. Tempo and Jaeger for tracing stay out.

## Left out

- A second guest for either playbook
- A separate Grafana playbook. Grafana stays on the Prometheus guest
- Installing Prometheus and Zabbix on the same virtual machine
- A database on another machine. PostgreSQL stays on the monitor guest
- The paid Grafana edition
- Tracing (Tempo or Jaeger)

## Dependencies

- Upstream: the guest the administrator provides. This playbook does not create it
- Downstream: dashboards and alert routes

## Status

- Playbook files: no
- Review: decided
