# Pocket Cluster

Small Kubernetes on Docker. One control plane, two workers.

**Goal:** Learn how to ship applications (CKAD) and test manifests on a Linux box that already has Docker. Three containers. No kubeadm HA, no keepalived, no Ceph.

## Teaching Note

**Pocket Cluster** is the small lab: you already have an API, and you practice Deployments, Services, ConfigMaps, Jobs, probes, and the rest of the application language. The numbered files in this repo teach how a production-shaped cluster is built. That work waits on VMs.

kind (Kubernetes IN Docker) starts it. Each node is a container, so the RAM cost stays small. Extra workers help you spread Pods and run DaemonSets. Extra control planes do not help: they still share one Docker host.

The Kubernetes **cluster** version is the `image:` field on every node in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). The kubectl **client** version is `KUBECTL_VERSION` in the install steps. Match those two minors.

Tools live under `/opt/pocket-cluster`. That is the local-software tree. `sudo` is only for creating that directory and giving it to your user. Daily `source` and `kubectl` do not need root.

kind sets each node hostname when it creates the Docker container. The first worker is `idops-pocket-k8s-cluster-worker`, the second is `idops-pocket-k8s-cluster-worker2`. There is no `worker1`. kind config has no hostname field. `docker rename` and `hostname` inside a running node do not change the Kubernetes node name.

kind Cluster YAML (`kind.x-k8s.io/v1alpha4`) has no CPU or memory fields on a node. Those keys on the Cluster object make `kind create` fail. Caps are the live `PocketResources` document in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) after `---`. kind reads only the Cluster document. `k8s_lab_start` applies PocketResources with `docker update`. Check the cap with `docker stats` (`MEM USAGE / LIMIT`). `docker ps` does not show RAM. kubelet may still report host memory in `kubectl get nodes`; it reads `/proc/meminfo`.

Every command in this file is safe to run again. A second pass keeps the same pins, reuses `/opt/pocket-cluster`, and starts the cluster only if it is missing.

## Contents

- [Part I — One-Time Setup and Configuration](#part-i--one-time-setup-and-configuration)
- [Part II — Daily Use and Lifecycle](#part-ii--daily-use-and-lifecycle)
- [CKAD Practice Map](#ckad-practice-map)
- [Troubleshooting](#troubleshooting)
- [Official References](#official-references)

## Goals

This setup provides:

- native Linux `amd64` or `arm64` binaries under `/opt/pocket-cluster`;
- a step-by-step kubectl install with a pinned version and a checksum check;
- the cluster Kubernetes version in one file, [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml);
- one control plane and two workers, with commented samples in that file;
- no package-manager install of `kubectl` or kind;
- a session-scoped `PATH` and an isolated kubeconfig;
- a stable activation command after you close the terminal.

## Where This Sits in the Repo

| Track                  | Directory                                                                           | What you practice                                              |
| ---------------------- | ----------------------------------------------------------------------------------  | -------------------------------------------------------------- |
| Pocket Cluster         | [pocket-cluster/](README.md)                                                        | Application delivery, CKAD, kubectl against a local API        |
| KVM HA lab             | [00-overview.md](../00-overview.md) through [09-smoke-test.md](../09-smoke-test.md) | Building the cluster (kubeadm, Calico, Ceph, Traefik)          |
| In-cluster databases   | [apps/](../apps/README.md)                                                          | MariaDB Galera and PostgreSQL, after the HA cluster is healthy |

Use this directory while the VMs are still being delivered. It does not replace the HA lab, and it does not wait on [apps/](../apps/README.md).

## Reference Environment

Linux workstation or laptop with Docker Engine. Pins checked against upstream on **2026-10-11**.

| Item                 | Value                                                  |
| -------------------- | ------------------------------------------------------ |
| OS                   | Linux                                                  |
| Architecture         | `x86_64` (`amd64`) or `aarch64` (`arm64`)              |
| Runtime              | Docker Engine, user in the `docker` group              |
| cgroup               | v2 (`cgroup2fs`)                                       |
| Install tree         | `/opt/pocket-cluster`                                  |
| Existing `kubectl`   | left in place if the host already has one              |

## Isolation Model

1. Binaries are installed under `/opt/pocket-cluster`.
2. The isolated `bin` directory is placed first in `PATH` only after activation.
3. `KUBECONFIG` points to a project-specific file instead of `~/.kube/config`.

kind stores node state in Docker containers and in a Docker network named `kind`. Closing a terminal removes the session variables and helper functions. It leaves the binaries, kubeconfig, and running containers in place.

## Pinned Version Matrix

Checked **2026-10-11**. Re-check before you run: [kind releases](https://github.com/kubernetes-sigs/kind/releases), [kubectl downloads](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), [CKAD exam version](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks).

| Component              | Version                    | Where it is set                                               |
| ---------------------- | -------------------------- | ------------------------------------------------------------- |
| `kubectl` client       | v1.37.0                    | `KUBECTL_VERSION` in Part I, then the kubectl install step    |
| kind CLI               | v0.33.0                    | `KIND_VERSION` in Part I, then the kind install step          |
| Kubernetes cluster     | v1.37.0                    | `image: kindest/node:v1.37.0` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) |
| Cluster name           | idops-pocket-k8s-cluster   | `name:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)                       |
| Nodes                  | 1 control plane, 2 workers | `nodes:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)                      |
| Control-plane resources| 2 CPU, 3g RAM              | `docker update` in `k8s_lab_start`                            |
| Each worker resources  | 2 CPU, 2g RAM              | `docker update` in `k8s_lab_start`                            |
| Install tree           | `/opt/pocket-cluster`      | Part I, create `/opt`                                         |

kind has no `kubernetesVersion` key. The cluster version is the node image tag, `kindest/node:v1.37.0`, on every node in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). kubectl v1.37.0 matches that minor ([version skew](https://kubernetes.io/releases/version-skew-policy/)). The CKAD exam environment was Kubernetes v1.37 as of 2026-09-30 ([Linux Foundation FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)).

No command in this guide uses `latest`, `stable.txt`, a floating release URL, or an unversioned package-manager formula for kubectl or kind.

---

# Part I — One-Time Setup and Configuration

Run these steps from the top whenever you need the cluster. Every command is idempotent: install overwrites the same pin, `k8s_lab_start` creates the cluster only if `idops-pocket-k8s-cluster` is missing.

Run the commands from the `pocket-cluster/` directory of this clone.

Work from this directory so `idops-pocket-k8s-cluster.yaml` and `activate` are next to you.

```sh
cd /path/to/kubernetes-lab/pocket-cluster
```

Remember this path for the copy steps.

```sh
GUIDE_DIR="$(pwd)"
```

## 1. Confirm the Host Requirements

Confirm the kernel reports Linux.

```sh
uname -s
```

Expected: `Linux`.

Confirm the CPU architecture.

```sh
uname -m
```

Expected: `x86_64` or `aarch64`.

Confirm this shell is Bash.

```sh
printf 'Shell: %s Bash: %s\n' "$SHELL" "$BASH_VERSION"
```

Kubernetes 1.37 needs cgroup v2.

```sh
stat -fc %T /sys/fs/cgroup
```

Expected: `cgroup2fs`.

Confirm this user can talk to Docker without `sudo`.

```sh
id -nG
```

```sh
docker context show
```

```sh
docker info >/dev/null && echo "Docker is ready"
```

Your user must be in the `docker` group.

Read CPU and memory Docker can see.

```sh
docker info --format 'Architecture={{.Architecture}} CPUs={{.NCPU}} MemoryBytes={{.MemTotal}}'
```

Three kind nodes plus the node image need several GB of RAM and disk. First create pulls `kindest/node` (about a gigabyte).

## 2. Inspect the Existing kubectl

See whether a distro or Docker kubectl is already on `PATH`. Leave it in place.

```sh
type -a kubectl 2>/dev/null || true
```

```sh
command -v kubectl 2>/dev/null || true
```

```sh
kubectl version --client 2>/dev/null || true
```

The next steps install a second binary under `/opt/pocket-cluster`.

## 3. Pin the Tool Versions

These pins are for the **binaries on this machine**. The **cluster** Kubernetes version is the `image:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml).

```sh
export KUBECTL_VERSION="v1.37.0"
```

```sh
export KIND_VERSION="v0.33.0"
```

```sh
export KIND_CLUSTER_NAME="idops-pocket-k8s-cluster"
```

Map `uname -m` to the Kubernetes arch name.

```sh
case "$(uname -m)" in x86_64) export K8S_ARCH=amd64 ;; aarch64) export K8S_ARCH=arm64 ;; *) echo "This guide supports Linux amd64 (x86_64) and arm64 (aarch64) only." >&2; return 1 2>/dev/null || exit 1 ;; esac
```

```sh
[ "$(uname -s)" = Linux ] || { echo "This guide is Linux only." >&2; return 1 2>/dev/null || exit 1; }
```

```sh
export K8S_LAB_HOME="/opt/pocket-cluster"
```

```sh
export K8S_LAB_ROOT="$K8S_LAB_HOME/kubectl-${KUBECTL_VERSION}_kind-${KIND_VERSION}"
```

```sh
export K8S_LAB_BIN="$K8S_LAB_ROOT/bin"
```

`KUBECTL_VERSION` must stay in the same minor as the node `image:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) (here both are 1.37).

## 4. Create the /opt Tree

`/opt` is the place for local software. `sudo` is only here, so the directory exists and your user owns it.

```sh
sudo mkdir -p "$K8S_LAB_BIN"
```

```sh
sudo chown -R "$USER:$USER" "$K8S_LAB_HOME"
```

Layout:

```
/opt/pocket-cluster/
└── kubectl-v1.37.0_kind-v0.33.0/
    └── bin/
```

## 5. Install kubectl

Download the pinned client ([install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)).

```sh
curl --fail --location --output "$K8S_LAB_BIN/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"
```

Download the published checksum for that same binary.

```sh
curl --fail --location --output "$K8S_LAB_ROOT/kubectl.sha256" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256"
```

Check the file. `sha256sum --check` needs two spaces between the hash and the filename.

```sh
printf '%s  %s\n' "$(cat "$K8S_LAB_ROOT/kubectl.sha256")" "$K8S_LAB_BIN/kubectl" | sha256sum --check
```

Expected: `.../bin/kubectl: OK`. Stop if this fails.

```sh
chmod 0755 "$K8S_LAB_BIN/kubectl"
```

```sh
rm -f "$K8S_LAB_ROOT/kubectl.sha256"
```

Confirm it is a Linux binary for this CPU.

```sh
file "$K8S_LAB_BIN/kubectl"
```

```sh
"$K8S_LAB_BIN/kubectl" version --client
```

Expected client version: `v1.37.0`. This binary is not on `PATH` until you source `activate`.

## 6. Install kind

Download the pinned kind binary ([quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)).

```sh
curl --fail --location --output "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${K8S_ARCH}"
```

Download the checksum kind published next to that binary.

```sh
curl --fail --location --output "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum" "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${K8S_ARCH}.sha256sum"
```

Check the file. The checksum names `kind-linux-amd64` or `kind-linux-arm64`, so run the check in `bin`.

```sh
( cd "$K8S_LAB_BIN" && sha256sum --check "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum" )
```

Expected: `kind-linux-amd64: OK` or `kind-linux-arm64: OK`. Stop if this fails.

```sh
cp "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "$K8S_LAB_BIN/kind"
```

```sh
chmod 0755 "$K8S_LAB_BIN/kind"
```

```sh
rm -f "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum"
```

```sh
file "$K8S_LAB_BIN/kind"
```

```sh
"$K8S_LAB_BIN/kind" version
```

Expected: `kind v0.33.0` plus the Go and arch suffix.

## 7. Install the Cluster Config and Activate Script

**This is where the cluster version is defined.** Open [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). Every node has `image: kindest/node:v1.37.0`. That image is the Kubernetes version. kind has no `kubernetesVersion` field. Change the cluster version by changing every `image:` to a new `kindest/node:vX.Y.Z` from the [kind release notes](https://github.com/kubernetes-sigs/kind/releases), then recreate the cluster.

The file also has commented samples: three workers, and a control-plane-only layout.

Copy the config into `/opt` so daily use does not depend on the git clone path.

```sh
cp "$GUIDE_DIR/idops-pocket-k8s-cluster.yaml" "$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml"
```

Copy [activate](activate). It restores `PATH`, `KUBECONFIG`, and the helper functions.

```sh
cp "$GUIDE_DIR/activate" "$K8S_LAB_ROOT/activate"
```

```sh
chmod 0644 "$K8S_LAB_ROOT/activate"
```

kind has no `stop` or `pause`. To free RAM, delete the cluster. The node image stays in Docker, so the next start is faster.

## 8. Create Stable Activation Links

Point `current` at this versioned directory so later upgrades can retarget one link.

```sh
ln -sfn "$K8S_LAB_ROOT" "$K8S_LAB_HOME/current"
```

Point the stable `activate` path at `current/activate`.

```sh
ln -sfn "current/activate" "$K8S_LAB_HOME/activate"
```

Layout:

```
/opt/pocket-cluster/
├── activate -> current/activate
├── current -> kubectl-v1.37.0_kind-v0.33.0
└── kubectl-v1.37.0_kind-v0.33.0/
    ├── activate
    ├── idops-pocket-k8s-cluster.yaml
    └── bin/
        ├── kubectl
        └── kind
```

## 9. Activate the Environment

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_info
```

```sh
type -a kubectl
```

```sh
type -a kind
```

The first `kubectl` and `kind` must resolve under `$K8S_LAB_BIN`.

## 10. Verify the Pinned Client Versions

```sh
kubectl version --client --output=yaml
```

```sh
kind version
```

Expected: kubectl `v1.37.0`, kind `v0.33.0`.

```sh
actual_kubectl_version="$(kubectl version --client --output=json | awk -F'"' '/"gitVersion"/ { print $4; exit }')"
```

```sh
actual_kind_version="$(kind version | awk '{ print $2; exit }')"
```

```sh
[[ "$actual_kubectl_version" == "$KUBECTL_VERSION" ]] && echo "kubectl version is correct" || { echo "Unexpected kubectl version: $actual_kubectl_version" >&2; return 1 2>/dev/null || exit 1; }
```

```sh
[[ "$actual_kind_version" == "$KIND_VERSION" ]] && echo "kind version is correct" || { echo "Unexpected kind version: $actual_kind_version" >&2; return 1 2>/dev/null || exit 1; }
```

## 11. Create the Cluster

If an old cluster named `pocket` is still around, delete it first. kind delete is idempotent if that name is already gone.

```sh
kind delete cluster --name pocket
```

```sh
k8s_lab_start
```

kind reads `$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml`: name `idops-pocket-k8s-cluster`, one control plane, two workers, image `kindest/node:v1.37.0`. The first run pulls that image. Run it again and it exports kubeconfig if `idops-pocket-k8s-cluster` already exists. After the cluster is up, `k8s_lab_start` caps each Docker node (`docker update`) and labels workers with `kubectl` so `ROLES` shows `worker`. Do not put that label in the yaml: kubelet will refuse it at join.

## 12. Verify the Cluster

```sh
k8s_lab_status
```

```sh
kubectl version
```

```sh
kubectl cluster-info
```

```sh
kubectl get pods --all-namespaces
```

```sh
kubectl get storageclass
```

```sh
kubectl wait --for=condition=Ready node --all --timeout=180s
```

```sh
kubectl get nodes
```

Expected names: `idops-pocket-k8s-cluster-control-plane`, `idops-pocket-k8s-cluster-worker`, `idops-pocket-k8s-cluster-worker2`. Expected versions: client and server `v1.37.0`. Worker `ROLES` is `worker`.

kind names the first worker `{cluster}-worker` and the next `{cluster}-worker2`. That is the container hostname and the Kubernetes node name. You cannot set `worker1` in kind config.

kind ships Rancher local-path provisioner. Default StorageClass is `standard`. kubectl context name is `kind-idops-pocket-k8s-cluster`.

## 13. Confirm Isolation

```sh
printf 'kubectl=%s kind=%s KUBECONFIG=%s\n' "$(command -v kubectl)" "$(command -v kind)" "$KUBECONFIG"
```

```sh
kubectl config get-contexts
```

```sh
docker ps --filter "label=io.x-k8s.kind.cluster=${KIND_CLUSTER_NAME}" --format '{{.Names}} {{.Image}}'
```

Project-specific state is under `/opt/pocket-cluster`. Host kubectl and `~/.kube/config` stay untouched.

## 14. Ship a First Application

Two replicas can land on the two workers. kind nodes do not see images on the host Docker daemon until you load them. Pull on the laptop, load into the cluster, then apply. That avoids a rollout wait on Docker Hub from inside the nodes.

```sh
docker pull nginx:1.27
```

```sh
k8s_lab_load_image nginx:1.27
```

```sh
kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
```

```sh
kubectl create deployment hello --image=nginx:1.27 --replicas=2 -n demo --dry-run=client -o yaml | kubectl apply -f -
```

```sh
kubectl create service clusterip hello --tcp=80:80 -n demo --dry-run=client -o yaml | kubectl apply -f -
```

```sh
kubectl rollout status deployment/hello -n demo --timeout=180s
```

If this times out, list the pods. ImagePullBackOff means the image is not on the node; run the pull and load again.

```sh
kubectl get pods -n demo -o wide
```

```sh
kubectl get deploy,po,svc -n demo -o wide
```

Reach the Service from inside the cluster.

```sh
kubectl run curl --rm -it --restart=Never -n demo --image=busybox:1.36 -- wget -qO- http://hello
```

Expected: nginx HTML, then the curl pod exits.

```sh
kubectl delete namespace demo --ignore-not-found
```

---

# Part II — Daily Use and Lifecycle

## 1. Start a New Terminal Session

Closing a terminal removes shell variables, `PATH` changes, aliases, and helper functions. The `/opt` install and the Docker containers stay.

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_info
```

```sh
k8s_lab_status
```

If the cluster is missing:

```sh
k8s_lab_start
```

If it is running:

```sh
kubectl get nodes
```

```sh
kubectl get pods --all-namespaces
```

The session alias `k` is `kubectl`. Example: `k get po -A`.

## 2. Understand What Survives Terminal Closure

| Item                        | Survives terminal closure? | Location or behavior                                         |
| --------------------------- | -------------------------- | ------------------------------------------------------------ |
| Pinned `kubectl` binary     | Yes                        | `/opt/pocket-cluster/.../bin`                                |
| Pinned kind binary          | Yes                        | `/opt/pocket-cluster/.../bin`                                |
| Stable activation link      | Yes                        | `/opt/pocket-cluster/activate`                               |
| Isolated kubeconfig         | Yes                        | under the versioned directory                                |
| kind cluster config         | Yes                        | `$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml` (`image:` is the cluster version) |
| Running kind nodes          | Usually yes                | Docker containers, until deleted or Docker stops             |
| Node image in Docker        | Yes                        | Docker image cache                                           |
| Exported variables          | No                         | Restore by sourcing `activate`                               |
| PATH precedence             | No                         | Restore by sourcing `activate`                               |
| Helper functions and `k`    | No                         | Restore by sourcing `activate`                               |

## 3. Command Reference

After activation:

| Command                          | Effect                                                                  |
| -------------------------------- | ----------------------------------------------------------------------- |
| `k8s_lab_info`                   | Show paths, versions, cluster name, and the `image:` from idops-pocket-k8s-cluster.yaml  |
| `k8s_lab_start`                  | Create or reuse the cluster; cap Docker CPU/RAM; label workers                          |
| `k8s_lab_status`                 | List kind clusters, node containers, and Kubernetes nodes               |
| `k8s_lab_load_image <image>`     | Load a local Docker image into the kind nodes                           |
| `k8s_lab_delete_cluster`         | Delete the `idops-pocket-k8s-cluster` cluster (kind delete is idempotent)                 |
| `k8s_lab_deactivate`             | Restore the shell's original PATH and variables                         |

## 4. Load a Local Image

kind nodes do not see images that exist only on the host Docker daemon.

```sh
k8s_lab_load_image my-app:dev
```

In the Pod spec, set `image: my-app:dev` and `imagePullPolicy: IfNotPresent` (or `Never`). See [kind load](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).

## 5. Deactivate Only the Current Shell

```sh
k8s_lab_deactivate
```

The kind cluster keeps running.

```sh
command -v kubectl
```

```sh
kubectl version --client
```

## 6. Restart After Docker Was Stopped

```sh
source /opt/pocket-cluster/activate
```

```sh
docker info >/dev/null && echo "Docker is ready"
```

```sh
kind get clusters
```

```sh
kubectl get nodes
```

If the node containers are gone or the nodes stay NotReady:

```sh
k8s_lab_delete_cluster
```

```sh
k8s_lab_start
```

```sh
k8s_lab_status
```

Workloads from the old cluster are gone after delete.

## 7. Delete the Cluster but Keep the Tools

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_delete_cluster
```

This removes the `idops-pocket-k8s-cluster` containers. kubectl, kind, and `/opt/pocket-cluster` stay.

```sh
k8s_lab_start
```

## 8. Completely Uninstall Pocket Cluster

Docker Engine and any host kubectl stay.

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_delete_cluster
```

```sh
k8s_lab_deactivate
```

`/opt` needs root to remove.

```sh
sudo rm -rf /opt/pocket-cluster
```

Optional: free the cached node image.

```sh
docker image rm kindest/node:v1.37.0 2>/dev/null || true
```

## 9. Optional Bash Convenience Function

Add this to the Bash startup file this terminal uses if you want a shorter command.

```sh
k8s_lab_activate() { source /opt/pocket-cluster/activate; }
```

```sh
k8s_lab_activate
```

## 10. Update Pinned Versions Later

Treat an upgrade as a new versioned directory under `/opt/pocket-cluster`.

1. Pick a `kindest/node:vX.Y.Z` from the [kind release notes](https://github.com/kubernetes-sigs/kind/releases).
2. Put that tag on every `image:` line in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml).
3. Set `KUBECTL_VERSION` to the same minor and install that kubectl.
4. Recheck the CKAD exam Kubernetes version if you are studying for the exam.
5. Copy `idops-pocket-k8s-cluster.yaml` and `activate` into the new versioned directory.
6. Delete the old cluster, or use a different `name:` in idops-pocket-k8s-cluster.yaml.
7. Point `current` at the new directory.

```sh
ln -sfn "$NEW_K8S_LAB_ROOT" /opt/pocket-cluster/current
```

Daily activation stays:

```sh
source /opt/pocket-cluster/activate
```

Two versioned environments must not share the cluster name `idops-pocket-k8s-cluster` at the same time.

---

# CKAD Practice Map

The CKAD exam is a two-hour, performance-based kubectl test. Domains below are from the [CKAD page](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/) (Kubernetes v1.37 as of 2026-09-30). Recheck that page before you sit.

This cluster is for practice. It is not the exam environment and it is not a dump of exam tasks.

| Domain                                                      | Weight | What works on this cluster out of the box                                                                                      |
| ----------------------------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------ |
| Application Environment, Configuration and Security         | 25%    | ConfigMaps, Secrets, ServiceAccounts, SecurityContext, requests/limits/quotas                                                  |
| Application Design and Build                                | 20%    | Deployments, DaemonSets (two workers), Jobs, CronJobs, multi-container Pods, local-path PVCs (`standard`)                      |
| Application Deployment                                      | 20%    | Rolling updates, canary via two Deployments + Service labels, `kubectl apply -k` (Kustomize is in kubectl)                     |
| Services and Networking                                     | 20%    | ClusterIP/NodePort Services, NetworkPolicy on kindnet, Ingress objects (an ingress controller is still required to serve HTTP) |
| Application Observability and Maintenance                   | 15%    | probes, `kubectl logs`, `kubectl exec`, `kubectl describe`, debug Pods                                                         |

Add later, when a domain needs it:

- **Helm 3** — CKAD lists Helm. Install a pinned tarball the same way [05-deploy-kubernetes.md](../05-deploy-kubernetes.md) does on the bastion. Debian's apt package named `helm` is Emacs.
- **metrics-server** — needed for `kubectl top` and HorizontalPodAutoscaler. kind does not ship it.
- **Ingress controller** — extraPortMappings on 8080/8443 are ready. Follow [kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress/) or install Traefik as in the HA lab, on this cluster.
- **Calico** — only if you disable kindnet (`networking.disableDefaultCNI: true`) and replace it. Default kindnet in kind v0.33.x includes a NetworkPolicy controller; confirm with a deny-all test the first time you study that domain.

Exam-day habits to use here: `k` as kubectl, `--dry-run=client -o yaml` into a file, then `kubectl apply -f`, and the official Kubernetes docs as the reference.

---

# Troubleshooting

## The Top-Level Activation File Is Missing

```sh
ls -la /opt/pocket-cluster
```

```sh
ln -sfn /opt/pocket-cluster/kubectl-v1.37.0_kind-v0.33.0 /opt/pocket-cluster/current
```

```sh
ln -sfn current/activate /opt/pocket-cluster/activate
```

```sh
source /opt/pocket-cluster/activate
```

## The Host kubectl Is Still Selected

```sh
source /opt/pocket-cluster/activate
```

```sh
hash -r
```

```sh
type -a kubectl
```

The `/opt/pocket-cluster/.../bin` directory must appear before `/usr/local/bin` and `/usr/bin`.

## Docker Is Unavailable

```sh
docker context show
```

```sh
docker info
```

```sh
groups
```

Start the Docker engine. If `docker` returns permission denied, this user is missing from the `docker` group. After `sudo usermod -aG docker "$USER"`, log out and back in.

## kubectl Cannot Find the Cluster

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_info
```

```sh
k8s_lab_status
```

```sh
kubectl config get-contexts
```

Context name: `kind-idops-pocket-k8s-cluster`.

## The Shell Variables Disappeared

Expected after closing the terminal.

```sh
source /opt/pocket-cluster/activate
```

Skip the download steps.

## The Cluster Is Missing

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

## Host Port 8080 or 8443 Is Already in Use

kind create fails if those host ports are taken. Stop the other process, or change `hostPort` in `$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml` and recreate the cluster.

## A Pod Stays ImagePullBackOff for a Local Image

```sh
k8s_lab_load_image my-app:dev
```

Set `imagePullPolicy: IfNotPresent`. `--name idops-pocket-k8s-cluster` is already inside `k8s_lab_load_image`.

## NetworkPolicy Seems to Do Nothing

Apply a default-deny in a test namespace and confirm traffic is dropped. If it is not, check `kubectl -n kube-system logs ds/kindnet`. Replacing kindnet with Calico is a later optional step (`disableDefaultCNI: true`).

## Cgroup v1

Kubernetes 1.37 expects cgroup v2. If `stat -fc %T /sys/fs/cgroup` is not `cgroup2fs`, use a host with cgroup v2, or pick an older `kindest/node` tag. Change every `image:` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). This file stays on 1.37.

## Rollout Timed Out / 0 Replicas Available

kind nodes pull images themselves. `nginx:1.27` from Docker Hub can sit in `ImagePullBackOff` past a 120s rollout wait.

```sh
kubectl get pods -n demo -o wide
```

```sh
kubectl describe pod -n demo
```

Pull on the laptop and load into the cluster, then wait again.

```sh
docker pull nginx:1.27
```

```sh
k8s_lab_load_image nginx:1.27
```

```sh
kubectl rollout status deployment/hello -n demo --timeout=180s
```

## Docker Stats Show the Whole Laptop RAM

kind YAML cannot set `--memory` or `--cpus` on the Cluster object. Caps are the `PocketResources` document in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). `k8s_lab_start` applies them with `docker update`. Confirm with `docker stats` (`180MiB / 2GiB` means the cap is 2GiB). `docker ps` has no memory column. kubelet may still print host RAM in `kubectl get nodes`.

## Joining Worker Nodes Failed / kubelet healthz

kind create can sit on "Joining worker nodes" for about four minutes, then delete the cluster. kubeadm reports kubelet healthz on `127.0.0.1:10248` connection refused.

Do not put `node-role.kubernetes.io/worker` (or any reserved `kubernetes.io` label) in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) `labels:`. kind hands those to kubelet `--node-labels`. kubelet refuses them and never becomes healthy. Set the worker role after the cluster is up: `k8s_lab_start` runs `kubectl label`.

Copy the repo [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) and [activate](activate) into `/opt/pocket-cluster` again, then retry `k8s_lab_start`.

## Worker Names Are Not worker1 and worker2

kind sets the hostname to `idops-pocket-k8s-cluster-worker` and `idops-pocket-k8s-cluster-worker2`. That is also the Kubernetes node name. kind has no hostname field. `docker rename` and `hostname` inside the container do not retarget kubelet.

---

# Official References

- [kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [kind Configuration](https://kind.sigs.k8s.io/docs/user/configuration/)
- [kind Known Issues](https://kind.sigs.k8s.io/docs/user/known-issues/)
- [kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress/)
- [Install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
- [Kubernetes releases](https://kubernetes.io/releases/)
- [Kubernetes version-skew policy](https://kubernetes.io/releases/version-skew-policy/)
- [CKAD certification](https://training.linuxfoundation.org/certification/certified-kubernetes-application-developer-ckad/)
- [CKA/CKAD/CKS FAQ (exam Kubernetes version)](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)
