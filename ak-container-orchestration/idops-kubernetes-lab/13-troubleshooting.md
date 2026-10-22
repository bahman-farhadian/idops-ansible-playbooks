# 13. Troubleshooting

**Goal:** Collect known issues and fixes encountered while building this lab.

## Teaching note

Write the failure here when it happens. Stacked etcd is a static pod; you `kubectl exec` into it. External etcd is a systemd unit; you use `etcdctl` on the VM. A VIP that vanishes is keepalived, not kube-apiserver. This file stays empty until a real run fills it. That is the point.

## Covers
- etcd quorum loss recovery
  - **Stacked:** `kubectl exec` into the etcd static pod
  - **External:** on the standalone `k8s-etcd-*` nodes — no `kubectl exec` available, work directly via `etcdctl`/`systemctl`
- Node stuck `NotReady`
- Ceph OSD/placement group issues
- kubeadm join/token failures
- API VIP failover (`k8s-lb-1` / `k8s-lb-2`, apiserver `10.0.1.10`)
- Firewall keepalived WAN/LAN VIP failover (`k8s-fw-1` / `k8s-fw-2`)

## Prerequisites
- Populated as issues come up during deployment.

## Next
- GPU profile: [14-gpu.md](14-gpu.md)
- Everyone: [15-deployment-log.md](15-deployment-log.md) — record what you actually deployed
