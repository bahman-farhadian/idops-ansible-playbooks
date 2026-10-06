# av-security-and-compliance

Domain status: decision only (no playbook files yet)

## Purpose

One security platform for the guests that are already hardened. Wazuh reports. It does not change a firewall rule or an account.

## Playbook

- `wazuh/`
  - One guest. The manager, the indexer, and the dashboard run on that guest as systemd services
  - The pin is Wazuh 4.14.8, published 23 September 2026. 5.0 is still a beta, so it is not the pin
  - The manager and the agent are GPL-2.0. The indexer and the dashboard are Apache 2.0. Wazuh Cloud stays out
  - The indexer is Wazuh's own search store. Alerts stay on an extra disk on this guest. The disk size stays in local settings. This store is not `am-databases/elasticsearch` and not the logging Elasticsearch
  - People read the alerts on the Wazuh dashboard. This playbook does not send them to Grafana
  - The manager guest uses the same four releases as the other guests: Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04. Wazuh's indexer and dashboard pages list Ubuntu through 24.04 and the Red Hat family. This project does not add a separate Ubuntu-only guest
  - Agents on other guests are a later task in this same playbook. That task uses its own local settings file. It does not create the guest
  - Active response stays off. Wazuh does not block an address and does not change an account
  - A deployment can point the Wazuh dashboard at `aq-identity-and-access/keycloak`, or leave that page with its own login. The choice is in local settings. This playbook does not require Keycloak
  - Does not change the Lynis score in `ag-os-baseline-and-hardening`. Does not replace `at-centralized-logging`
  - This playbook does not create the guest and does not call provisioning or hardening

## Alternatives

- OSSEC. The same kind of agent, without this indexer and dashboard. OpenSCAP is a compliance scan, and it stays out. Security Onion is a separate distribution, and it stays out. Lynis stays in `ag-os-baseline-and-hardening`.

## Left out

- OpenSCAP as its own playbook
- Security Onion
- A second Lynis playbook. Lynis stays in `ag-os-baseline-and-hardening/debian-based-os-hardening`
- A second Wazuh guest. The manager, indexer, and dashboard stay together
- Wazuh 5.0 while it is a beta
- Wazuh Cloud
- Active response
- Using the logging Elasticsearch or `am-databases/elasticsearch` as the Wazuh store

## Dependencies

- Upstream: the guest the administrator provides. This playbook does not create it
- Downstream: alerts and reports on the Wazuh dashboard

## Status

- Playbook files: no
- Review: decided
