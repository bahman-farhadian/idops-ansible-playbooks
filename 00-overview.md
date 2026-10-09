# 00. Overview

**Goal:** Define what this lab builds, what it deliberately leaves out, and how to read the rest of the docs.

## Teaching note

Read this file before you type a command. The fixed decisions are the contract: kubeadm, containerd 2.x, Calico, native Ceph, Traefik, Helm 3. Pins exist so an `apt upgrade` cannot surprise you, and so file 11 and 12 have a real next version. One host cannot give you failover. It can still teach quorum: one control plane, one firewall, one API proxy, or one Ceph VM can die while the others keep working.

## Covers
- Purpose: build a production-like, highly-available Kubernetes cluster for hands-on learning.
- Learning focus: HA control plane, networking, storage (Ceph), security, day-2 operations.
- Out of scope: VM/host provisioning. This repo assumes the VMs already exist (created manually, via Ansible, via a cloud provider, or any other method) and are reachable over SSH with a base OS installed.
- Two supported topologies, chosen up front in [Scenarios](#scenarios).
- Four scenarios (below). Only one is powered on at a time. They are never joined together.
- Style: manual, step-by-step, real commands — short enough to read end to end and understand what's happening, so you can later drive the same cluster with kubeadm scripted, Kubespray, or any other automation with eyes open.

## Deployment profiles

Named so a run and its docs/logs can be referred to unambiguously — always say which profile, not just "the cluster":

| Profile                 | Host                              | Nodes                                                                   |
| ----------------------- | --------------------------------- | ----------------------------------------------------------------------- |
| **Stacked**             | 128 GB server                     | 14 VMs. 40 vCPU, 118 GB. Deploy this first.                             |
| **Stacked + GPU**       | Same server, not at the same time | 15 VMs. 42 vCPU, 118 GB. GPU worker is 12 GB.                           |
| **External etcd**       | Same server, not at the same time | 16 VMs. 40 vCPU, 122 GB.                                                |
| **External etcd + GPU** | Same server, not at the same time | 17 VMs. 42 vCPU, 126 GB. GPU worker is 16 GB. 2 GB stays with the host. |

Circle the matching table in [01-inventory.md](01-inventory.md), then walk [02-prepare.md](02-prepare.md) through [09-smoke-test.md](09-smoke-test.md) in number order. Inside [05-deploy-kubernetes.md](05-deploy-kubernetes.md), open one bootstrap (stacked or external). Upgrades come after that stack is up: [11-update-kubernetes.md](11-update-kubernetes.md), then [12-update-ceph.md](12-update-ceph.md). See [README.md](README.md#layout). **Deploy stacked first. Only one of the four scenarios is powered on at a time.** One KVM host: Ryzen 9 3900X, 24 threads, 128 GB RAM, three SSDs (32G for the OS, then 192G, 192G, and 888G for data). Plan it as empty. No OSD disk on the server. All three Ceph disks share the 888G SSD. That is a lab choice. It cannot fail over if the server dies. It can tolerate one guest dying while the host stays up. Host table: [01-inventory.md](01-inventory.md#kvm-host). The 32 GB machine is not a target. See [README.md](README.md#rollout-plan). Record the exact pinned versions used for each profile's run in [15-deployment-log.md](15-deployment-log.md) — the steps use version *variables* (`KUBE_DEPLOY_VERSION`, `CEPH_DEPLOY_VERSION`, …), and which concrete value you picked for a given profile/run is exactly the kind of thing that's easy to lose track of otherwise.

## Fixed decisions

These are settled for the whole manual — later steps assume them rather than re-justifying them:

| Area                       | Choice                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OS                         | **Debian 13 ("Trixie") or Ubuntu 26 ("Resolute Raccoon")** on every VM of a given lab instance — do not mix distros inside one cluster. Work **one distro at a time** (Debian first, then Ubuntu). Apt commands are the same shape; where a repo URL or package name differs, the step says so.                                                                                                                                                                                  |
| Edge                       | Three separate roles, same as an on-prem production cluster. Firewalls `k8s-fw-1` / `k8s-fw-2`: keepalived, WAN VIP + LAN gateway VIP. They do **not** run HAProxy. Load balancers `k8s-lb-1` / `k8s-lb-2`: keepalived + HAProxy, their own VRID, floating VIP for `:6443` and later `:80`/`:443`. Bastion: one admin VM (jump, kubectl, k9s, Helm, Nexus, Prometheus, Grafana). It is not in the request path and it does **not** run HAProxy. WAN numbering stays out of this repo. |
| Bootstrap tool             | `kubeadm` (not k3s/RKE2/Kubespray)                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| Container runtime          | **containerd** on every Kubernetes node. **Docker Engine** exists only on `k8s-bastion`, as a single-node daemon for the Compose support stack. Do not install Docker on ctrl/workers.                                                                                                                                                                                                                                                                                           |
| CNI                        | Calico (NetworkPolicy support, needed in [10-security.md](10-security.md))                                                                                                                                                                                                                                                                                                                                                                                                       |
| Storage                    | Ceph on three dedicated VMs, `k8s-ceph-1/2/3`, native `apt` and systemd (not Rook, not on the Kubernetes workers). Each VM is one monitor, one manager, and one OSD. Ceph-CSI runs inside the cluster.                                                                                                                                                                                                                                                                            |
| Ingress                    | Traefik (ingress-nginx is being sunset upstream)                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| Bastion support plane      | Nexus + Prometheus + Grafana as **Docker Compose** on `k8s-bastion` ([04-bastion.md](04-bastion.md)). `kubectl`, k9s, and Helm 3 are installed and the kubeconfig is written there during [05-deploy-kubernetes.md](05-deploy-kubernetes.md). API HAProxy is **not** on this VM. `node_exporter` stays systemd on every VM.                                                                                                                     |
| Admin kubectl              | `k8s-bastion` is on the LAN, so its `kubectl` and k9s use `https://10.0.1.10:6443` directly. On any other host, both use that same address only through the site VPN, and that path enters at the firewall pair. k9s is configured with `logoless: true`, so the top bar does not show the k9s name. This repo does not install or configure the VPN server. Do not publish `:6443` on the WAN VIP, and do not replace the kubeconfig server with a localhost SSH tunnel. |
| Cache                      | Nexus (in that Compose stack) proxies apt and container registries so each object is fetched from the internet once.                                                                                                                                                                                                                                                                                                                                                             |
| GPU (GPU profile only)     | `k8s-work-4` is a VM with the GPU passed straight through to it (PCI passthrough); NVIDIA driver + container toolkit + plain Kubernetes device plugin inside the guest, no GPU Operator/MIG/time-slicing; node is tainted so only pods that explicitly tolerate it can be scheduled there. It is not a Ceph node — [14-gpu.md](14-gpu.md)                                                                                                                                        |
| Container-count philosophy | Kubernetes is systemd + containerd on cluster nodes (kubeadm model). Ceph is systemd on `k8s-ceph-*`, which do not run kubelet. Lab-support apps that must stay *outside* the cluster (Nexus, Prometheus, Grafana) run as Compose on a non-k8s VM whose host daemon is Docker. Do not put those apps in-cluster, and do not put Docker next to kubelet.                                                                                                                    |
| Configuration changes      | Read the current value or file first. Write the file that service reads at boot, then start, restart, or reload that service so it loads the file. This is every config in the manual: sysctl, modules, swap, nftables, the default gateway, `/etc/hosts`, keepalived, HAProxy, containerd (`containerd.io` on cluster nodes), apt source lists, `/etc/default/etcd`, Ceph, and Compose. A one-shot `sysctl -w`, `ip route replace`, `nft add`, or shell `export` is not the change. |

## Version pinning and the upgrade exercise

Every package this manual installs for the cluster to function (`containerd.io` on cluster nodes, `kubelet`, `kubeadm`, `kubectl`, `haproxy`, `keepalived`, `ceph-*`, `etcd-*`, `docker-ce` on the bastion, `prometheus-node-exporter`, …) is installed at an **exact pinned version** (`apt install pkg=<version>`, never a bare `apt install pkg`) and `apt-mark hold`ed right after. Compose images (`sonatype/nexus3`, `prom/prometheus`, `grafana/grafana`) are pinned by **tag** in `compose.yaml`, not by apt. A plain `apt upgrade`/`unattended-upgrades` run must never be able to silently bump a component that could break the cluster or change its behavior underneath you.

This pinning is deliberate for a second reason, not just safety: **Kubernetes and Calico are each deployed one minor behind current stable** ([05-deploy-kubernetes.md](05-deploy-kubernetes.md)), so [11-update-kubernetes.md](11-update-kubernetes.md) has a real next version. **Ceph on Debian 13 is Umbrella**, the only `download.ceph.com` suite that publishes Trixie — that is not "one release behind." [12-update-ceph.md](12-update-ceph.md) is an Umbrella patch (or Vampire when it has Trixie). The same unhold → install exact new pin → verify → re-hold cycle applies (Calico has no apt package/hold; the same shape applies via its operator manifest version). Staying current matters here, not just as an exercise: an untouched cluster silently ages out of its security-support window. That upgrade walkthrough is as much the point of this lab as the initial bootstrap is.

**Checked 2026-10-10** (Kubernetes has no LTS track — it ships a new minor roughly every 4 months and supports the 3 most recent; Ceph ships a new stable release roughly once a year; Calico keeps the latest two minors in security support):

| Component  | Deploy version                                                       | Upgrade-to version                          | Source                                                                                       |
| ---------- | -------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Kubernetes | v1.36 (latest patch 1.36.5)                                          | v1.37 (latest patch 1.37.1)                 | [kubernetes.io/releases](https://kubernetes.io/releases/)                                    |
| Ceph       | Debian 13: Umbrella 21.x from `debian-umbrella` (trixie exists here) | Next Umbrella patch, or Vampire when it ships a trixie suite | [docs.ceph.com/en/latest/releases](https://docs.ceph.com/en/latest/releases/)                |
| Calico     | v3.32.2 (one minor behind)                                           | v3.33.0 (current stable)                    | [github.com/projectcalico/calico/releases](https://github.com/projectcalico/calico/releases) |

Re-check all three before you actually run the steps — this table is a snapshot, not a promise. Kubernetes 1.36 needs containerd 2.x ([SIG Node](https://kubernetes.io/blog/2025/09/12/kubernetes-v1-34-cri-cgroup-driver-lookup-now-ga/)); Debian 13's `containerd` 1.7 package is too old. Squid (19.x) is EOL 2026-10-31, and `download.ceph.com` has **no** `debian-squid/trixie` or `debian-tentacle/trixie` suite (checked 2026-10-10). Only `debian-umbrella` publishes Trixie. Debian 13 is Ceph tier "C" (packages, untested) for Umbrella. Debian's own Reef package is already EOL; do not use it. [06-ceph.md](06-ceph.md) and [05-deploy-kubernetes.md](05-deploy-kubernetes.md) follow that.

## Scenarios

Pick one before provisioning. It changes the node count and which bootstrap section you open in [05-deploy-kubernetes.md](05-deploy-kubernetes.md).

|                    | Stacked etcd                     | External etcd      |
| ------------------ | -------------------------------- | ------------------ |
| Control-plane VMs  | 3 (etcd on each)                 | 2 (apiserver only) |
| Dedicated etcd VMs | 0                                | 3                  |
| Failure isolation  | etcd and apiserver fail together | independent        |
| Bootstrap section  | Stacked                          | External           |

Stacked is the simpler path and the one to build first. External costs more VMs and uses a native `etcd-server` package rather than kubeadm's static-pod etcd. Official kubeadm external etcd is 3 control planes plus 3 etcd nodes running etcd as a static pod; this lab keeps 2 apiservers and distro etcd on purpose.

## Diagram color legend

Every Mermaid diagram in this repo reuses the same two palettes (GitHub can't share Mermaid `classDef`s across files, so each diagram repeats the same hex values verbatim — keep them in sync if you change one).

**Role palette** (architecture/topology diagrams — bastion, control-plane, etcd, worker, storage):

| Role           | Color       |
| -------------- | ----------- |
| Bastion / LB   | 🔵 `#1f6feb` |
| Control plane  | 🟣 `#8250df` |
| etcd           | 🟠 `#d29922` |
| Worker         | 🟢 `#2da44e` |
| Storage (Ceph) | 🟦 `#0d9488` |

**Flow palette** (step-sequence diagrams — README.md pipeline):

| Meaning                      | Color                               |
| ---------------------------- | ----------------------------------- |
| Common step (both scenarios) | ⚪ `#57606a`                         |
| Scenario A — stacked etcd    | 🟣 `#8250df` (matches Control plane) |
| Scenario B — external etcd   | 🟠 `#d29922` (matches etcd)          |

The flow palette's scenario colors intentionally match the role palette: Scenario A is purple because its etcd is embedded in the (purple) control plane; Scenario B is amber because its etcd is the (amber) standalone tier. "Scenario A"/"Scenario B" and "stacked"/"external" are the same two things — diagrams may label nodes either way, but the colors don't change.

## Prerequisites
- None — start here.
