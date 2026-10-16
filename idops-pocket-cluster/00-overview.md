# 00. Overview

**Goal:** Know what Pocket Cluster is, which versions it pins, and which document to open next.

## Teaching note

**Pocket Cluster** is the small lab. You already have an API. You practice Deployments, Services, ConfigMaps, Jobs, probes, and the rest of the application language. You also use it every day as a local test cluster for manifests and other Kubernetes tasks. The numbered files at the repo root teach how a production-shaped cluster is built. That work waits on VMs.

kind (Kubernetes IN Docker) starts it. Each node is a container, so the RAM cost stays small. Extra workers help you spread Pods and run DaemonSets. Extra control planes do not help: they still share one Docker host.

These files are documents, numbered like the HA lab. The repo [README.md](../README.md) is the project index. Walk **00 → 03** in this directory.

Every command in 01–03 is idempotent. Run the same block again: pins stay the same, `/opt/idops-pocket-cluster` is reused, and the cluster is created only if it is missing.

## Follow order

| Doc                                          | Covers                                                              |
| -------------------------------------------- | ------------------------------------------------------------------- |
| [00-overview.md](00-overview.md)             | This file: purpose, pins, isolation, CKAD map                       |
| [01-install-tools.md](01-install-tools.md)   | Host check, `/opt` tree, kubectl, kind, Helm 3, cloud-provider-kind |
| [02-create-cluster.md](02-create-cluster.md) | Create the cluster, verify, daily use, lifecycle                    |
| [03-hello-nginx.md](03-hello-nginx.md)       | First app: six nginx Pods, Ingress                                  |

The first app is [hello-nginx.yaml](hello-nginx.yaml) in this clone. `/opt` holds the toolchain only. Cluster config is [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). Session helpers are in [activate](activate).

## Where this sits in the repo

| Track                | Directory                                                                           | What you practice                                              |
| -------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Pocket Cluster       | [idops-pocket-cluster/](00-overview.md)                                             | Application delivery, CKAD, kubectl against a local API        |
| KVM HA lab           | [00-overview.md](../00-overview.md) through [09-smoke-test.md](../09-smoke-test.md) | Building the cluster (kubeadm, Calico, Ceph, Traefik)          |
| In-cluster databases | [apps/](../apps/README.md)                                                          | MariaDB Galera and PostgreSQL, after the HA cluster is healthy |

Pocket Cluster is for learning and for daily work. Use it to practice Kubernetes and CKAD. Use it the same way as a small test cluster: apply a manifest, check the result, change it, and apply again. Use this directory while the VMs are still being delivered. It does not replace the HA lab, and it does not wait on [apps/](../apps/README.md).

## Reference environment

Linux workstation or laptop with Docker Engine. Pins checked against upstream on **2026-10-11**.

| Item               | Value                                     |
| ------------------ | ----------------------------------------- |
| OS                 | Linux                                     |
| Architecture       | `x86_64` (`amd64`) or `aarch64` (`arm64`) |
| Runtime            | Docker Engine, user in the `docker` group |
| cgroup             | v2 (`cgroup2fs`)                          |
| Install tree       | `/opt/idops-pocket-cluster`               |
| Existing `kubectl` | left in place if the host already has one |

## Isolation model

1. Binaries live under `/opt/idops-pocket-cluster`. `/opt` is the local-software tree. `sudo` is only for creating that directory and giving it to your user. Daily `source` and `kubectl` do not need root.
2. The isolated `bin` directory is first on `PATH` only after you source `activate`.
3. `KUBECONFIG` points at a file in that tree, not `~/.kube/config`.

kind stores node state in Docker containers and in a Docker network named `kind`. Closing a terminal drops session variables and helper functions. Binaries, kubeconfig, and running containers stay.

## Pinned version matrix

Re-check before you run: [kind releases](https://github.com/kubernetes-sigs/kind/releases), [kubectl downloads](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), [CKAD exam version](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks).

| Component               | Version                     | Where it is set                                                                                 |
| ----------------------- | --------------------------- | ----------------------------------------------------------------------------------------------- |
| `kubectl` client        | v1.37.0                     | `KUBECTL_VERSION` in [01-install-tools.md](01-install-tools.md)                                 |
| kind CLI                | v0.33.0                     | `KIND_VERSION` in [01-install-tools.md](01-install-tools.md)                                    |
| Helm 3                  | v3.22.0                     | `HELM_VERSION` in [01-install-tools.md](01-install-tools.md)                                    |
| cloud-provider-kind     | v0.12.0                     | [01-install-tools.md](01-install-tools.md), started by `k8s_lab_start`                          |
| Kubernetes cluster      | v1.37.0                     | `image: kindest/node:v1.37.0` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) |
| Cluster name            | idops-pocket-k8s-cluster    | `name:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)                       |
| Nodes                   | 1 control plane, 3 workers  | `nodes:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)                      |
| Control-plane resources | 2 CPU, 2g RAM               | `PocketResources` in the yaml; `docker update` in `k8s_lab_start`                               |
| Each worker resources   | 2 CPU, 2g RAM               | same                                                                                            |
| Install tree            | `/opt/idops-pocket-cluster` | [01-install-tools.md](01-install-tools.md)                                                      |

kind has no `kubernetesVersion` key. The cluster version is the node image tag on every node. kubectl v1.37.0 matches that minor ([version skew](https://kubernetes.io/releases/version-skew-policy/)). The CKAD exam environment was Kubernetes v1.37 as of 2026-09-30 ([Linux Foundation FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)).

No command in this guide uses `latest`, `stable.txt`, a floating release URL, or an unversioned package-manager formula for kubectl or kind.

## Shape and limits

kind sets each node hostname when it creates the Docker container. Workers are `idops-pocket-k8s-cluster-worker`, `idops-pocket-k8s-cluster-worker2`, `idops-pocket-k8s-cluster-worker3`. There is no `worker1`. kind config has no hostname field.

kind Cluster YAML (`kind.x-k8s.io/v1alpha4`) has no CPU or memory fields on a node. Those keys on the Cluster object make `kind create` fail. Caps are the live `PocketResources` document in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) after `---`. kind reads only the Cluster document. `k8s_lab_start` applies PocketResources with `docker update`. Check the cap with `docker stats` (`MEM USAGE / LIMIT`). `docker ps` does not show RAM. kubelet may still report host memory in `kubectl get nodes`; it reads `/proc/meminfo`.

Do not put `node-role.kubernetes.io/*` in the kind yaml. kind passes extra labels to kubelet `--node-labels`. kubelet refuses reserved `kubernetes.io` labels and the worker never becomes healthy. `k8s_lab_start` labels workers after they are Ready.

kind removes the kubeadm control-plane taint so workloads can land there. `k8s_lab_start` puts `node-role.kubernetes.io/control-plane:NoSchedule` back. Application Pods run on the three workers. kube-system static pods stay on the control plane. `k8s_lab_load_image` loads images onto workers only.

Ingress and LoadBalancer use Cloud Provider KIND. Curl the Ingress ADDRESS (a docker network IP). Do not curl `127.0.0.1`.

kind has no `stop` or `pause`. To free RAM, delete the cluster. The node image stays in Docker, so the next start is faster.

## CKAD practice map

The CKAD exam is a two-hour, performance-based kubectl test. Domains below are from the [CKAD page](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/) (Kubernetes v1.37 as of 2026-09-30). Recheck that page before you sit.

This cluster is for practice. It is not the exam environment and it is not a dump of exam tasks.

| Domain                                              | Weight | What works on this cluster out of the box                                                                   |
| --------------------------------------------------- | ------ | ----------------------------------------------------------------------------------------------------------- |
| Application Environment, Configuration and Security | 25%    | ConfigMaps, Secrets, ServiceAccounts, SecurityContext, requests/limits/quotas                               |
| Application Design and Build                        | 20%    | Deployments, DaemonSets (three workers), Jobs, CronJobs, multi-container Pods, local-path PVCs (`standard`) |
| Application Deployment                              | 20%    | Rolling updates, canary via two Deployments + Service labels, `kubectl apply -k` (Kustomize is in kubectl)  |
| Services and Networking                             | 20%    | ClusterIP/NodePort Services, NetworkPolicy on kindnet, Ingress (Cloud Provider KIND)                        |
| Application Observability and Maintenance           | 15%    | probes, `kubectl logs`, `kubectl exec`, `kubectl describe`, debug Pods                                      |

Helm 3 is on `PATH` after [01-install-tools.md](01-install-tools.md). Debian's apt package named `helm` is Emacs.

Add later, when a domain needs it:

- **metrics-server** — needed for `kubectl top` and HorizontalPodAutoscaler. kind does not ship it.
- **Calico** — only if you disable kindnet (`networking.disableDefaultCNI: true`) and replace it. Default kindnet in kind v0.33.x includes a NetworkPolicy controller; confirm with a deny-all test the first time you study that domain.

Exam-day habits: type `kubectl`, `--dry-run=client -o yaml` into a file, then `kubectl apply -f`, and the official Kubernetes docs as the reference.

## Official references

- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
- [kind Known Issues](https://kind.sigs.k8s.io/docs/user/known-issues/)
- [kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress/)
- [kind LoadBalancer / Cloud Provider KIND](https://kind.sigs.k8s.io/docs/user/loadbalancer/)
- [Install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Kubernetes releases](https://kubernetes.io/releases/)
- [Kubernetes version-skew policy](https://kubernetes.io/releases/version-skew-policy/)
- [CKAD certification](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/)
- [CKA/CKAD/CKS FAQ (exam Kubernetes version)](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)

## Next

- [01-install-tools.md](01-install-tools.md)
