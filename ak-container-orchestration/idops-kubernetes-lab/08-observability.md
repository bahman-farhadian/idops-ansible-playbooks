# 08. Observability

**Goal:** Export host metrics from every node. Prometheus and Grafana are already running as Compose services on `k8s-bastion` from [04-bastion.md](04-bastion.md). This step is the **node_exporter** agents plus a Grafana dashboard. No in-cluster kube-state-metrics or logging stack.

## Teaching note

You cannot run what you cannot see. Each VM exports CPU, memory, and disk on port 9100. Prometheus scrapes that list from a file on the bastion. Put the Ceph VMs in that list too. Metrics stay on the host, not inside the cluster, so a broken kubelet still has a pulse. This is not a full logging stack.

`node_exporter` is a **systemd** package on every VM (including the bastion). It needs the host's `/proc` and `/sys`; do not put it in the Compose file.

## Steps

**1. `node_exporter` on every node** in the [02-prepare.md](02-prepare.md) hosts block (firewalls, bastion, control-plane, etcd if present, workers, and the three Ceph VMs):
```sh
sudo apt update
apt-cache madison prometheus-node-exporter
NODE_EXPORTER_VERSION="<version from the list above>"
sudo apt install -y prometheus-node-exporter=${NODE_EXPORTER_VERSION}
sudo apt-mark hold prometheus-node-exporter
systemctl cat prometheus-node-exporter | grep -E 'ExecStart|EnvironmentFile'
cat /etc/default/prometheus-node-exporter 2>/dev/null || true   # read; leave it unless a flag must change
sudo systemctl enable --now prometheus-node-exporter           # the unit file is what boot starts
```
Verify locally: `curl -s localhost:9100/metrics | head`. Prefer the Nexus apt proxy from step 07 if you created `apt-debian` / `apt-ubuntu`.

**2. Confirm Prometheus** (from the bastion or your workstation):
```sh
curl -s http://k8s-bastion:9090/api/v1/targets | grep -E '"health"|up'
```
Every node_exporter target should be `"up"`. If a target is missing, `grep -n 9100 /opt/prometheus/prometheus.yml`, change that file, then `cd /opt/prometheus && sudo docker compose up -d` so Prometheus loads it.

**3. Grafana:** open `http://k8s-bastion:3000`. Datasource from inside the Grafana container: `http://host.docker.internal:9090`. Import a maintained "Node Exporter Full" dashboard from [grafana.com/dashboards](https://grafana.com/dashboards).

> Host disk via node_exporter, not Ceph pool internals. `ceph mgr module enable prometheus` is out of scope here.

## Prerequisites
- [07-ingress.md](07-ingress.md)
- [04-bastion.md](04-bastion.md) — Compose stack already up

## Next
- [09-smoke-test.md](09-smoke-test.md)
