# MariaDB Galera

**Status:** Blocked. No install, no manifests, no chart pin.

**Goal:** Run a 3-node MariaDB Galera cluster inside Kubernetes so the lab has a multi-master database. Any of the three nodes can take a write. Galera certifies that write with the other nodes and then commits it. Lose one node and the other two still accept writes. Lose two and the cluster stops rather than split.

This is the master-master case. [postgresql.md](postgresql.md) is the single-writer case. Do not start this file until [apps/README.md](README.md) says the cluster gate is open.

When this is written it will cover:

- A 3-member Galera set, odd count, same reason a mon quorum is three
- Persistent volumes from `ceph-rbd`
- A Service for clients inside the cluster, and later an ingress name if anything outside the cluster must connect
- A write against one member, read back from another
- Stop one member and confirm the other two still commit

## Prerequisites

- [README.md](README.md)
