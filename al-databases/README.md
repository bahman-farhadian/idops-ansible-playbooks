# al-databases

Domain status: decision only (no playbook files yet)

## Purpose

Database services for the stack. Each engine is its own playbook and its own guest. The playbooks are separate and can be used together.

## Playbook

- `postgresql/`
  - One guest
  - PostgreSQL as a systemd service
  - An extra disk for the data directory
  - This guest is for applications that want a shared database. A playbook that keeps its own database does not use this guest.
- `mariadb/`
  - One guest
  - MariaDB as a systemd service
  - An extra disk for the data directory
- `clickhouse/`
  - One guest
  - ClickHouse as a systemd service
  - An extra disk for the data directory
- `elasticsearch/`
  - One guest
  - Elasticsearch as a systemd service, for applications
  - An extra disk for the data directory
  - This guest is not the Elasticsearch in `as-centralized-logging`. ELK and EFK keep their own clusters
  - The source is available under AGPL, SSPL, or the Elastic License. AGPL is the open-source terms. The usual Elastic download is the Elastic License, so when this playbook is written it installs the AGPL terms on purpose
- `mongodb/`
  - One guest
  - MongoDB Community Server as a systemd service
  - An extra disk for the data directory
  - Community Server is SSPL. That is not an OSI open-source license. It is in this domain because the stack asked for MongoDB

## Alternatives

- MySQL, for the relational engines. No second analytics engine was named for ClickHouse.
- OpenSearch, for Elasticsearch. ELK and EFK keep their own Elasticsearch and can be used together with this guest.

## Left out

- MySQL
- A replica or a failover manager, until a later change inside that same playbook

## Dependencies

- Upstream: `ac-vm-provisioning` creates the guest, then `ag-os-baseline-and-hardening`
- Downstream: applications that choose this database in their own local settings

## Status

- Playbook files: no
- Guests: one per playbook, created by `kvm-vm-provisioning`
