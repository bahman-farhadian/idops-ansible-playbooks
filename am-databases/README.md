# am-databases

Domain status: decision only (no playbook files yet)

## Purpose

Database services for the stack. Each engine is its own playbook. The playbooks are separate and can be used together.

Each playbook can run as one guest, as a replicated set, or as a sharded set. A project can use replication and sharding together. The project picks the layout in local settings. The minimum guest count for each layout is decided one playbook at a time.

Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04. The playbook pins the database version. The repository URL stays in local settings. That pin is the same on each of those releases. Each guest has an extra disk for its data directory. vCPU, RAM, and disk size stay in local settings.

When the project needs TLS, the engine terminates it. The administrator provides the certificate and the key. They stay in local settings. Accounts and passwords stay in local settings.

## Playbook

- `postgresql/`
  - PostgreSQL as a systemd service. Patroni runs on the PostgreSQL guests and promotes a standby when the primary fails
  - For applications that want a shared database. Mattermost, Stalwart, Metabase, Superset, Keycloak, GitLab, and Zabbix keep their own data and do not use this playbook
  - Three etcd layouts. The project picks one in local settings
  - etcd on the PostgreSQL guests. This playbook installs etcd there, beside PostgreSQL and Patroni. Make requires at least 3 PostgreSQL guests, and that count must be odd, so one guest can fail and etcd still has a quorum. Two guests are refused
  - External etcd: the administrator provides the guests. They are not the PostgreSQL guests. This playbook installs etcd on them and does not create the guests. Make requires at least 3, and that count must be odd. A single etcd is refused. The PostgreSQL set is at least 2
  - An existing etcd cluster: the addresses stay in local settings. Make requires at least 3 addresses, and that count must be odd. This playbook does not install etcd. The PostgreSQL set is at least 2
  - One guest is a local-settings choice. That choice runs PostgreSQL only. Patroni and etcd stay off
  - This playbook does not install or configure a proxy. A project that wants one uses `al-traffic-management`
  - Sharding is still open
- `mariadb/`
  - MariaDB as a systemd service
  - Layout minimums are still open
- `clickhouse/`
  - ClickHouse as a systemd service. The database code is Apache 2.0
  - Layout minimums are still open
- `elasticsearch/`
  - Elasticsearch as a systemd service, for applications
  - This guest is not the Elasticsearch in `at-centralized-logging`. ELK and EFK keep their own clusters
  - The source is available under AGPL, SSPL, or the Elastic License. AGPL is the open-source terms. The usual Elastic download is the Elastic License, so when this playbook is written it installs the AGPL terms on purpose
  - Layout minimums are still open
- `mongodb/`
  - MongoDB Community Server as a systemd service
  - Community Server is SSPL. That is not an OSI open-source license. It is in this domain because the stack asked for MongoDB
  - Layout minimums are still open

## Alternatives

- MySQL, for the relational engines. No second analytics engine was named for ClickHouse.
- OpenSearch, for Elasticsearch. ELK and EFK keep their own Elasticsearch and can be used together with this guest.

## Left out

- MySQL
- ClickHouse Cloud and the paid ClickHouse self-managed addendum

## Dependencies

- Upstream: the guests the administrator provides. This playbook does not create them and does not call provisioning or hardening
- Downstream: applications that choose this database in their own local settings

## Status

- Playbook files: no
- Review: `postgresql/` is the open playbook. MariaDB, ClickHouse, Elasticsearch, and MongoDB follow one at a time
