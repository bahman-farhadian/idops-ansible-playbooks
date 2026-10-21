# 04. MariaDB Galera

**Goal:** Ship a 3-node MariaDB Galera cluster with its own PersistentVolumeClaim per node, verify it is genuinely multi-master, and know how to recover it.

## Teaching note

[hello-nginx.yaml](hello-nginx.yaml) is stateless: delete a Pod, a new one starts with no memory of the old one. [mariadb-galera.yaml](mariadb-galera.yaml) is this cluster's first stateful app. A `StatefulSet` gives each replica a stable name (`galera-0`, `galera-1`, `galera-2`), a stable DNS name via a headless Service, and its own `PersistentVolumeClaim` that follows that specific replica across restarts. A `Deployment` cannot do any of that — its Pods are interchangeable and share no per-replica identity.

This is the small lab version. It uses the `standard` StorageClass — kind's bundled Rancher local-path provisioner, a host-directory bind inside each worker's container. It is **not** [../apps/mariadb-galera.md](../apps/mariadb-galera.md), the production HA-lab version referenced from [../apps/README.md](../apps/README.md): that one uses the `ceph-rbd` StorageClass and is gated on the full KVM cluster being healthy. Same database, same replication model, different purpose — this is CKAD/StatefulSet practice, that is production-shaped delivery.

Why a plain StatefulSet can't just hardcode `wsrep_cluster_address`: a brand-new Galera cluster bootstraps from an **empty** address (`gcomm://`), one node only; every later start of every node — the first join, and every restart after that — uses the **full peer list** (`gcomm://galera-0...,galera-1...,galera-2...`). A StatefulSet has no field for "is this the very first start of the whole cluster." [mariadb-galera.yaml](mariadb-galera.yaml) answers that with a small init container: it checks whether this Pod is `galera-0` **and** its own PVC has no `grastate.dat` yet (meaning this PVC has never held a cluster). If both are true, it bootstraps; otherwise it joins. That check only looks at this Pod's own PVC — see Troubleshooting for the one case that doesn't cover.

Image pin: `mariadb:12.3.3`. This matters more than it looks: the official `mariadb` image only started bundling Galera (the `mariadb-server-galera` package) at the **12.3** branch — `11.4`/`11.8` install plain `mariadb-server` with no wsrep provider at all. `12.3` is also the current **Long Term Support** branch (confirmed against [MariaDB/mariadb-docker's `versions.json`](https://github.com/MariaDB/mariadb-docker/blob/master/versions.json) — `13.0` is Stable but only `Rolling` support, `13.1` is still `RC`). Bitnami's `mariadb-galera` image was considered and rejected: since Broadcom's "Bitnami Secure Images" change, its versioned tags are paywalled and only `:latest` stays free, which conflicts with this repo's pinned-version rule.

`k` is an alias for `kubectl` after you source `activate`. Every command here is idempotent except the root-password Secret, which you only create once.

## Prerequisites

- Cluster is up from [02-create-cluster.md](02-create-cluster.md)
- Open [mariadb-galera.yaml](mariadb-galera.yaml) and read it before you apply

## Steps

**1. Create the root password Secret** — never committed to this repo. One Secret per cluster lifetime; re-run `k8s_lab_delete_cluster` and this Secret is gone too, so you make a new one on the next `k8s_lab_start`.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_start
kubectl create namespace idops-galera-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic galera-root \
  --namespace idops-galera-demo \
  --from-literal=password="$(openssl rand -base64 18)" \
  --dry-run=client -o yaml | kubectl apply -f -
```

**2. Load the image** — kind worker nodes do not see images on the host Docker daemon until you load them.
```sh
docker pull mariadb:12.3.3
k8s_lab_load_image mariadb:12.3.3
```

**3. Apply the manifest** — work from the clone.
```sh
cd /path/to/kubernetes-lab/idops-pocket-cluster
kubectl apply -f mariadb-galera.yaml
kubectl get cm,svc,sts,po,pvc -n idops-galera-demo -o wide
kubectl rollout status statefulset/galera -n idops-galera-demo --timeout=300s
```

Expected: ConfigMap `galera-static`, Services `galera-internal` (headless) and `galera` (ClusterIP), StatefulSet `galera` `3/3`, three Running Pods `galera-0`/`galera-1`/`galera-2` each `1/1` Ready, three Bound PVCs `data-galera-0`/`data-galera-1`/`data-galera-2`. `galera-0` becomes Ready well before `galera-1` starts — `podManagementPolicy: OrderedReady` is what makes that happen, and it's what keeps the first node from racing the others during bootstrap.

**4. Verify the cluster is actually a cluster** — `wsrep_cluster_size` must read `3`, not `1`. The image's client binary is `mariadb`, not `mysql` (MariaDB renamed its client tools; there is no `mysql`/`mysqladmin` in this image). `sh -c "..."` with escaped `\$` makes `$MARIADB_ROOT_PASSWORD` expand inside the container, not on the host.
```sh
kubectl exec -n idops-galera-demo galera-0 -- sh -c \
  "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" -N -e \"SHOW STATUS LIKE 'wsrep_cluster_size'; SHOW STATUS LIKE 'wsrep_cluster_status'; SHOW STATUS LIKE 'wsrep_ready';\""
```

**5. Prove multi-master, not just three Pods** — write on one node, read on another.
```sh
kubectl exec -n idops-galera-demo galera-0 -- sh -c \
  "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" -e \"CREATE DATABASE IF NOT EXISTS demo; CREATE TABLE IF NOT EXISTS demo.probe (id INT PRIMARY KEY, note VARCHAR(64)); REPLACE INTO demo.probe VALUES (1, 'written on galera-0');\""
kubectl exec -n idops-galera-demo galera-2 -- sh -c \
  "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" -N -e \"SELECT * FROM demo.probe;\""
```
Expected: `galera-2` prints the row that was written on `galera-0` — proof the write replicated, not just that the Pod exists.

**6. Confirm self-healing** — delete one Pod and watch it rejoin on its own.
```sh
kubectl delete pod -n idops-galera-demo galera-1
kubectl rollout status statefulset/galera -n idops-galera-demo --timeout=180s
kubectl exec -n idops-galera-demo galera-1 -- sh -c \
  "mariadb -u root -p\"\$MARIADB_ROOT_PASSWORD\" -N -e \"SHOW STATUS LIKE 'wsrep_cluster_size';\""
```
`galera-1` still has its PVC (StatefulSet Pod deletion does not delete the PVC), so the init container's "no `grastate.dat`" check is false and it joins instead of bootstrapping.

**7. Remove the app** — PVCs are not deleted by this command (`StatefulSet` deletion never deletes `volumeClaimTemplates`-created PVCs). Delete those explicitly if you want the data gone too.
```sh
cd /path/to/kubernetes-lab/idops-pocket-cluster
kubectl delete -f mariadb-galera.yaml --ignore-not-found
kubectl delete pvc -n idops-galera-demo -l app=galera   # optional: also drop the stored data
```

## Troubleshooting

**A Pod never goes Ready / stuck before `wsrep_ready` turns `ON`** — SST (state transfer) can take a few seconds even for an empty database. Watch the main container's logs, not just `kubectl get pods`.
```sh
kubectl logs -n idops-galera-demo galera-1 -f
kubectl logs -n idops-galera-demo galera-1 -c wsrep-address   # the init container's own output
```

**Why the readiness probe has its own credentials file, not the image's `.my-healthcheck.cnf`** — found by testing this exact manifest, not assumed: the official image's entrypoint only writes `/var/lib/mysql/.my-healthcheck.cnf` during the normal single-node `mariadb-install-db` init flow. A Galera node that joins via SST/IST gets its datadir by copying/streaming `galera-0`'s actual files — that entrypoint flow never runs, so that file never exists on `galera-1`/`galera-2`, and `healthcheck.sh` falls back to a passwordless connection attempt and fails with `Access denied ... (using password: NO)`. [mariadb-galera.yaml](mariadb-galera.yaml)'s init container writes its own `/etc/mysql-healthcheck/creds.cnf` identically on every node instead, and passes it to `healthcheck.sh` via `--defaults-extra-file`. This is also why `livenessProbe` is a plain `tcpSocket` check, not another `healthcheck.sh` call: liveness should never depend on auth or Galera cluster state — a transient non-Primary view during a network blip is not a reason to kill and restart a healthy process, and the first version of this manifest did exactly that (confirmed by testing) before `tcpSocket` replaced it.

**A Pod restarts with stale `grastate.dat` before its siblings have ever started** — the init container's bootstrap check (ordinal `0` and no `grastate.dat`) assumes the only two cases that happen in this lab's real lifecycle: a totally fresh cluster, or a fully-formed one. There is one gap, hit once while building this doc: if `galera-0` crashes and restarts *before `galera-1`/`galera-2` have ever been created* (so it already wrote a `grastate.dat` from its own earlier successful start, but has no real peers yet), it reads as "not fresh" and tries to **join** a peer list that does not exist yet (DNS for `galera-1.galera-internal...` fails to resolve because that Pod was never created) — it hangs in a non-Primary view instead of bootstrapping. This cannot happen once the StatefulSet has reached `3/3` for the first time; it only happens during an unusually troubled first rollout. Recover by deleting that Pod's PVC — there is no real cluster data to lose yet — and letting it re-bootstrap:
```sh
kubectl delete pod -n idops-galera-demo galera-0
kubectl delete pvc -n idops-galera-demo data-galera-0
```

**Only `galera-0`'s PVC was deleted by hand, 1/2 still have old data** — the init container's bootstrap check only looks at `galera-0`'s own PVC. If you delete just that one PVC (`kubectl delete pvc data-galera-0`) while `galera-1`/`galera-2` still hold real cluster state, `galera-0` will bootstrap a **second, separate** one-node cluster instead of rejoining — a split-brain, not a crash. This lab's normal lifecycle never does this on its own: `k8s_lab_delete_cluster` destroys all three worker containers (and therefore all three PVCs, which are host-dir binds inside them) together, so the only two cases that happen automatically are "all three PVCs are fresh" and "all three PVCs already have state." If you ever do delete just one PVC by hand, recover manually: delete all three PVCs and reapply, or manually edit `galera-0`'s `wsrep_cluster_address` to join instead of bootstrap.

**OOMKilled, or a worker goes NotReady under load** — each worker is capped at 2 CPU / 2G RAM ([idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)), shared with whatever else is running. `innodb_buffer_pool_size=128M` in [mariadb-galera.yaml](mariadb-galera.yaml) is deliberately small for exactly this reason. If a worker is tight, remove [hello-nginx.yaml](hello-nginx.yaml) first (`kubectl delete -f hello-nginx.yaml`), or lower `innodb_buffer_pool_size` further and reapply.
```sh
docker stats --no-stream
kubectl get pods -n idops-galera-demo -o wide
kubectl describe pod -n idops-galera-demo -l app=galera
```

**`ImagePullBackOff` for `mariadb:12.3.3`**
```sh
docker pull mariadb:12.3.3
k8s_lab_load_image mariadb:12.3.3
kubectl rollout status statefulset/galera -n idops-galera-demo --timeout=300s
```

## Next

Practice CKAD tasks from the map in [00-overview.md](00-overview.md#ckad-practice-map) — this app is the first real example of the `standard` local-path PVC that table already references.
