# 11. Update Kubernetes

**Goal:** Upgrade Kubernetes, Calico, and (external etcd only) the etcd packages, one held component at a time, from the versions deployed in [05-deploy-kubernetes.md](05-deploy-kubernetes.md). Do this after [09-smoke-test.md](09-smoke-test.md). Ceph's upgrade is the next file, [12-update-ceph.md](12-update-ceph.md).

## Teaching note

Upgrade one minor at a time. kubeadm's skew rule forbids skipping. First control plane runs `kubeadm upgrade apply`. Other nodes run `kubeadm upgrade node`. Drain a worker before you touch kubelet. Hold the package again before you leave the node. Calico upgrades by applying a newer operator manifest. Do not re-apply `custom-resources.yaml`, or you can reset the pod CIDR.

**Rule for every held package** (`containerd`, `kubelet`/`kubeadm`/`kubectl`, `haproxy`, `keepalived`, `etcd-*`, `ceph-*`, `docker-ce` on the bastion, `prometheus-node-exporter`): `sudo apt-mark unhold <pkg>` → drain/cordon if it's a k8s node → `apt install <pkg>=<exact-new-version>` (never a bare `apt install`/`apt upgrade`) → verify healthy → `sudo apt-mark hold <pkg>` again. A package never spends more than the length of one upgrade step unheld.

Compose on the bastion: read **that app's** file (`/opt/nexus/compose.yaml`, `/opt/prometheus/compose.yaml`, or `/opt/grafana/compose.yaml`), change the image tag in the file, then `cd /opt/<app> && sudo docker compose pull && sudo docker compose up -d`. Do not pull without changing the tag. `compose up` is what loads the file.

## Steps — Kubernetes minor upgrade

Deployed in [05-deploy-kubernetes.md](05-deploy-kubernetes.md). Upgrading one minor at a time, in this order: **first control-plane node → remaining control-plane nodes → workers** — never skip a minor, per [kubeadm's version skew policy](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubeadm-upgrade/). External etcd's apiserver is stateless, but `kubeadm upgrade` still walks the same control-plane component set on each node.

**1. New minor repo** — on `k8s-ctrl-1` first. One minor up. Do not skip.
```sh
KUBE_UPGRADE_MINOR=v1.37          # exactly one minor above the deployed minor
cat /etc/apt/sources.list.d/kubernetes.list                       # the minor you are leaving
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${KUBE_UPGRADE_MINOR}/deb/Release.key" \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg   # replace the old keyring file
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBE_UPGRADE_MINOR}/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
cat /etc/apt/sources.list.d/kubernetes.list                       # apt reads this file
sudo apt update
apt-cache madison kubeadm                            # copy the new pin
KUBE_UPGRADE_VERSION="1.37.1-1.1"                    # must match madison
```

**2. First control plane** — `kubeadm` first, then the apply, then kubelet and kubectl. Hold again before you leave the node.
```sh
sudo apt-mark unhold kubeadm
sudo apt install -y kubeadm=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubeadm                                          # hold before the long apply
sudo kubeadm upgrade plan                                           # read this; do not skip it
sudo kubeadm upgrade apply v${KUBE_UPGRADE_VERSION%%-*}             # only on the first control plane
sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=${KUBE_UPGRADE_VERSION} kubectl=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

**3. Remaining control-plane nodes** — stacked: `k8s-ctrl-2` and `k8s-ctrl-3`; external: `k8s-ctrl-2` only. Same repo switch as step 1, then per node:
```sh
sudo apt-mark unhold kubeadm
sudo apt install -y kubeadm=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubeadm
sudo kubeadm upgrade node

sudo apt-mark unhold kubelet kubectl
sudo apt install -y kubelet=${KUBE_UPGRADE_VERSION} kubectl=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubelet kubectl
sudo systemctl daemon-reload && sudo systemctl restart kubelet
```

**4. Each worker** — drain first. Workers run pods. Do one worker at a time.
```sh
kubectl cordon k8s-work-1
kubectl drain k8s-work-1 --ignore-daemonsets --delete-emptydir-data   # from the bastion
# then on k8s-work-1:
sudo apt-mark unhold kubeadm
sudo apt install -y kubeadm=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubeadm
sudo kubeadm upgrade node                                              # not "upgrade apply"
sudo apt-mark unhold kubelet
sudo apt install -y kubelet=${KUBE_UPGRADE_VERSION}
sudo apt-mark hold kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet
kubectl uncordon k8s-work-1                                            # from the bastion, after the node is back
```
Repeat per worker, one at a time — never drain two simultaneously on a 3-node worker pool. GPU: include `k8s-work-4`.

**5. Verify:**
```sh
kubectl get nodes -o wide   # every node on the new version, all Ready
```

## Steps — Calico upgrade

Deployed in [05-deploy-kubernetes.md](05-deploy-kubernetes.md). Operator-based installs upgrade by re-applying a newer operator manifest — you don't re-apply `custom-resources.yaml`, since that could reset your pod-CIDR/config back to its defaults; the operator reconciles the rest on its own.

**1. New Calico operator** — read the release notes, then apply only the operator manifest. Do not re-apply `custom-resources.yaml`.
```sh
CALICO_UPGRADE_VERSION=v3.33.0   # recheck github.com/projectcalico/calico/releases
kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/${CALICO_UPGRADE_VERSION}/manifests/tigera-operator.yaml"
kubectl get tigerastatus                              # Available=True again
kubectl get pods -n calico-system                     # pods roll one at a time
kubectl get nodes -o wide                             # nodes stay Ready
```

## Steps — etcd cluster upgrade (external etcd only)

Skip this section for stacked etcd — `kubeadm upgrade` already bumps etcd's static-pod image. External etcd is a plain apt package independent of Kubernetes' own version, so it needs its own upgrade, same "one node at a time, verify quorum" discipline as the Ceph mon upgrade in [12-update-ceph.md](12-update-ceph.md).

**1. Pick a new pinned version** (on `k8s-etcd-1`):
```sh
sudo apt update
apt-cache madison etcd-server
ETCD_UPGRADE_VERSION="<version from the list above>"
```

**2. One etcd node at a time** — quorum must be healthy before the next node.
```sh
sudo apt-mark unhold etcd-server etcd-client
sudo apt install -y etcd-server=${ETCD_UPGRADE_VERSION} etcd-client=${ETCD_UPGRADE_VERSION}
sudo apt-mark hold etcd-server etcd-client
sudo systemctl restart etcd
etcdctl --endpoints=https://10.0.1.15:2379,https://10.0.1.16:2379,https://10.0.1.17:2379 \
  --cacert=/etc/etcd/pki/ca.pem --cert=/etc/etcd/pki/k8s-etcd-1.pem --key=/etc/etcd/pki/k8s-etcd-1-key.pem \
  endpoint health --cluster                          # all three healthy before you continue
```
Repeat on `k8s-etcd-2`, then `k8s-etcd-3`. A mixed-version quorum mid-rollout is expected and safe.

## Also covers
- etcd backup and restore:
  - **Stacked:** all 3 members live in `/var/lib/etcd` on `k8s-ctrl-1/2/3` — `etcdctl snapshot save` against any member
  - **External:** `etcdctl snapshot save` directly against any `k8s-etcd-*` node (no `kubectl exec`; this etcd is a plain systemd service). Etcd's CA is the one from [05-deploy-kubernetes.md](05-deploy-kubernetes.md) step 2, separate from Kubernetes' PKI
- Adding/removing control-plane, etcd, and worker nodes
- Certificate rotation

## Prerequisites
- [09-smoke-test.md](09-smoke-test.md) — the stack from 05 through 09 is already up

## Next
- [12-update-ceph.md](12-update-ceph.md)
