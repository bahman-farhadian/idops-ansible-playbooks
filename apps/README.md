# Applications

**Goal:** Practice the application side on a cluster that is already healthy. Two databases, chosen because they teach different replication shapes.

Do not deploy either database yet. There is no procedure in this directory. Start here only after Debian 13 stacked has been through [09-smoke-test.md](../09-smoke-test.md) with Ceph healthy ([06-ceph.md](../06-ceph.md)). The cluster bring-up does not wait on this directory.

| Database | What this lab will practice | Replication |
| -------- | --------------------------- | ----------- |
| [MariaDB Galera](mariadb-galera.md) | A 3-node multi-master database on Kubernetes | Every node accepts writes. Galera replicates a transaction to the other nodes before it commits. |
| [PostgreSQL](postgresql.md) | A primary with replicas on Kubernetes | One node accepts writes. A replica can be promoted. That is still one writer, not a Galera cluster. |

Both will use the `ceph-rbd` StorageClass from [06-ceph.md](../06-ceph.md) once the procedures exist. Neither runs on the bastion, and neither replaces Ceph.

## Prerequisites

- [09-smoke-test.md](../09-smoke-test.md) passed
- [06-ceph.md](../06-ceph.md) healthy, `ceph-rbd` can bind a PVC

## Next

Write [mariadb-galera.md](mariadb-galera.md) first, then [postgresql.md](postgresql.md). Not before the cluster gate above.
