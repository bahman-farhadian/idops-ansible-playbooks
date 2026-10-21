# PostgreSQL

**Status:** Blocked. No install, no manifests, no chart pin.

**Goal:** Run PostgreSQL inside Kubernetes with one primary and replicas. Clients write to the primary. Replicas receive the stream and can be promoted if the primary is gone. After promotion there is still one writer.

PostgreSQL does not provide a Galera-style master-master cluster. This file does not add one. Multi-master writes are [mariadb-galera.md](mariadb-galera.md). Do not start this file until [apps/README.md](README.md) says the cluster gate is open, and until the Galera procedure has been written.

When this is written it will cover:

- One primary and at least one replica
- Persistent volumes from `ceph-rbd`
- A Service that always points writes at the current primary
- A write on the primary, read from a replica
- Fail the primary and confirm a replica is promoted, with writes going only to the new primary

## Prerequisites

- [README.md](README.md)
- [mariadb-galera.md](mariadb-galera.md)
