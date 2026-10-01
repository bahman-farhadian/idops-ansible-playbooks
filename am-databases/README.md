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
  - Citus is the sharding extension, AGPL-3.0, on those same guests. One coordinator and workers. Applications connect to the coordinator. Many shards share a worker
  - For applications that want a shared database. Mattermost, Stalwart, Metabase, Superset, Keycloak, GitLab, and Zabbix keep their own data and do not use this playbook
  - Three etcd layouts. The project picks one in local settings. etcd on the PostgreSQL guests is installed by this playbook beside PostgreSQL and Patroni, and that guest count must be odd. External etcd is guests the administrator provides, not the PostgreSQL guests, and this playbook installs etcd there. An existing etcd cluster is addresses in local settings, and this playbook does not install it. An etcd count is at least 3 and odd. This playbook does not create the guests
  - One guest is a local-settings choice. That choice runs PostgreSQL only. Patroni and etcd stay off
  - This playbook does not install or configure a proxy. A project that wants one uses `al-traffic-management`
  - Guest counts for every supported scenario:

| Scenario | PostgreSQL VMs | etcd VMs | Total you provide |
| --- | --- | --- | --- |
| One guest, selected in local settings | 1 | 0. Patroni and etcd stay off | 1 |
| Replicated. etcd on the PostgreSQL guests | 3, odd | 0 extra | 3 |
| Replicated. External etcd | 2 | 3, odd | 5 |
| Replicated. Existing etcd cluster | 2 | 0. The cluster already has at least 3 members | 2 |
| Citus, no standbys. etcd on those guests | 3. One coordinator and two workers | 0 extra | 3 |
| Citus, no standbys. External etcd | 3 | 3 | 6 |
| Citus, no standbys. Existing etcd cluster | 3 | 0 | 3 |
| Citus, every primary has a standby. etcd on those guests | 7. Six is even, so one extra standby | 0 extra | 7 |
| Citus, every primary has a standby. External etcd | 6. Coordinator pair plus two worker pairs | 3 | 9 |
| Citus, every primary has a standby. Existing etcd cluster | 6 | 0 | 6 |

The counts are minimums. Another worker is one guest, or two when that worker has a standby. etcd can be 3, then 5, then 7. The number of shards does not add a guest. A Citus row with no standbys keeps a worker's shards only on that disk. A row with standbys keeps those shards on the standby.

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
- The paid Azure database built on Citus

## Dependencies

- Upstream: the guests the administrator provides. This playbook does not create them and does not call provisioning or hardening
- Downstream: applications that choose this database in their own local settings

## Status

- Playbook files: no
- Review: `postgresql/` is decided. Next is `mariadb/`
