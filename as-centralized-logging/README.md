# as-centralized-logging

Domain status: decision only (no playbook files yet)

## Purpose

Log collection for the stack. rsyslog, ELK, and EFK are separate playbooks. They can be used together. The Elasticsearch guests here are the logging clusters. The application database is `al-databases/elasticsearch`.

## Playbook

- `rsyslog/`
  - One guest
  - rsyslog as a systemd service, receiving remote syslog
  - Shipping from other guests is a later task in this same playbook
- `elk/`
  - Elasticsearch, Logstash, and Kibana
  - One guest each
  - A three-node Elasticsearch cluster is a later change inside this playbook
- `efk/`
  - Elasticsearch, Fluent Bit, and Kibana
  - One guest each
  - Its own Elasticsearch and Kibana, separate from `elk/`
  - Fluent Bit is the collector. Fluentd is still maintained, and new production collectors use Fluent Bit
  - A three-node Elasticsearch cluster is a later change inside this playbook

## Alternatives

- Loki and OpenSearch. Fluentd is the collector EFK does not use.

## Left out

- Loki and OpenSearch

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: guests that forward logs

## Status

- Playbook files: no
- Guests: one for `rsyslog`, three for `elk`, three for `efk`, created by `kvm-vm-provisioning`
