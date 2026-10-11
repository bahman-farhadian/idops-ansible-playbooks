# Pocket Cluster

Small Kubernetes on Docker. One control plane, two workers.

**Goal:** Learn how to ship applications (CKAD) and test manifests on a Linux box that already has Docker. Three containers. No kubeadm HA, no keepalived, no Ceph.

## Teaching Note

**Pocket Cluster** is the small lab: you already have an API, and you practice Deployments, Services, ConfigMaps, Jobs, probes, and the rest of the application language. The numbered files in this repo teach how a production-shaped cluster is built. That work waits on VMs.

kind (Kubernetes IN Docker) starts it. Each node is a container, so the RAM cost stays small. Extra workers help you spread Pods and run DaemonSets. Extra control planes do not help: they still share one Docker host.

The Kubernetes **cluster** version is the `image:` field on every node in [cluster.yaml](cluster.yaml). The kubectl **client** version is `KUBECTL_VERSION` in the install steps. Match those two minors.

## Contents

- [Part I — One-Time Setup and Configuration](#part-i--one-time-setup-and-configuration)
- [Part II — Daily Use and Lifecycle](#part-ii--daily-use-and-lifecycle)
- [CKAD Practice Map](#ckad-practice-map)
- [Troubleshooting](#troubleshooting)
- [Official References](#official-references)

## Goals

This setup provides:

- native Linux `amd64` or `arm64` binaries;
- a step-by-step kubectl install with a pinned version and SHA-256 check;
- the cluster Kubernetes version in one file, [cluster.yaml](cluster.yaml);
- one control plane and two workers, with commented samples in that file;
- no `sudo` for the kind or kubectl install;
- no package-manager install of `kubectl` or kind;
- a session-scoped `PATH` and an isolated kubeconfig;
- a stable activation command after you close the terminal.

## Where This Sits in the Repo

| Track                  | Directory                                                                          | What you practice                                              |
| ---------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| Pocket Cluster         | [kind/](README.md)                                                                 | Application delivery, CKAD, kubectl against a local API        |
| KVM HA lab             | [00-overview.md](../00-overview.md) through [09-smoke-test.md](../09-smoke-test.md) | Building the cluster (kubeadm, Calico, Ceph, Traefik)          |
| In-cluster databases   | [apps/](../apps/README.md)                                                         | MariaDB Galera and PostgreSQL, after the HA cluster is healthy |

Use this directory while the VMs are still being delivered. It does not replace the HA lab, and it does not wait on [apps/](../apps/README.md).

## Reference Environment

Linux workstation or laptop with Docker Engine. Pins checked against upstream on **2026-10-11**. The full create was not executed in that check.

| Item                 | Value                                                  |
| -------------------- | ------------------------------------------------------ |
| OS                   | Linux                                                  |
| Architecture         | `x86_64` (`amd64`) or `aarch64` (`arm64`)              |
| Runtime              | Docker Engine, user in the `docker` group              |
| cgroup               | v2 (`cgroup2fs`)                                       |
| Existing `kubectl`   | left in place if the host already has one              |

Docker Desktop on Linux also works. This guide talks to the Docker API the same way. Rootless Docker needs extra host sysctls; this file stays on the default Docker Engine socket.

## Isolation Model

1. Binaries are installed beneath `~/pocket-cluster`.
2. The isolated `bin` directory is placed first in `PATH` only after activation.
3. `KUBECONFIG` points to a project-specific file instead of `~/.kube/config`.

kind stores node state in Docker containers and in a Docker network named `kind`. Closing a terminal removes the session variables and helper functions. It leaves the binaries, kubeconfig, and running containers in place.

## Pinned Version Matrix

Checked **2026-10-11**. Re-check before you run: [kind releases](https://github.com/kubernetes-sigs/kind/releases), [kubectl downloads](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/), [CKAD exam version](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks).

| Component              | Version                    | Where it is set                                              |
| ---------------------- | -------------------------- | ------------------------------------------------------------ |
| `kubectl` client       | v1.37.0                    | `KUBECTL_VERSION` in Part I step 3, then step 4              |
| kind CLI               | v0.33.0                    | `KIND_VERSION` in Part I step 3, then step 5                 |
| Kubernetes cluster     | v1.37.0                    | `image: kindest/node:v1.37.0` in [cluster.yaml](cluster.yaml) |
| Cluster name           | pocket                     | `name:` in [cluster.yaml](cluster.yaml)                      |
| Nodes                  | 1 control plane, 2 workers | `nodes:` in [cluster.yaml](cluster.yaml)                     |

kind has no `kubernetesVersion` key. The cluster version is the node image tag, `kindest/node:v1.37.0`, on every node in [cluster.yaml](cluster.yaml). kubectl v1.37.0 matches that minor ([version skew](https://kubernetes.io/releases/version-skew-policy/)). The CKAD exam environment was Kubernetes v1.37 as of 2026-09-30 ([Linux Foundation FAQ](https://docs.linuxfoundation.org/tc-docs/certification/faq-cka-ckad-cks)).

No command in this guide uses `latest`, `stable.txt`, a floating release URL, or an unversioned package-manager formula for kubectl or kind.

---

# Part I — One-Time Setup and Configuration

Complete this part once. Run the commands from the `kind/` directory of this clone.

```sh
cd /path/to/kubernetes-lab/kind
GUIDE_DIR="$(pwd)"
```

## 1. Confirm the Host Requirements

Confirm Linux and architecture:

```sh
uname -s
uname -m
```

Expected OS:

```
Linux
```

Expected machine hardware is one of:

```
x86_64
aarch64
```

Confirm Bash:

```sh
printf 'Shell: %s\n' "$SHELL"
printf 'Bash:  %s\n' "$BASH_VERSION"
```

Confirm cgroup v2 (Kubernetes 1.37 drops cgroup v1):

```sh
stat -fc %T /sys/fs/cgroup
```

Expected:

```
cgroup2fs
```

Confirm Docker without `sudo`:

```sh
id -nG
docker context show
docker info >/dev/null && echo "Docker is ready"
```

Your user must be in the `docker` group. Inspect resources:

```sh
docker info --format \
  'Architecture={{.Architecture}} CPUs={{.NCPU}} MemoryBytes={{.MemTotal}}'
```

Three kind nodes plus the node image need several GB of RAM and disk. First create pulls `kindest/node` (about a gigabyte). Leave room for that pull.

## 2. Inspect the Existing kubectl

Run this before the isolated install:

```sh
type -a kubectl 2>/dev/null || true
command -v kubectl 2>/dev/null || true
kubectl version --client 2>/dev/null || true
```

A distro or Docker install commonly exposes `/usr/bin/kubectl` or `/usr/local/bin/kubectl`. Leave that executable in place. The next steps install a second binary under `~/pocket-cluster`.

## 3. Pin the Tool Versions

These two pins are for the **binaries on your laptop**. The **cluster** Kubernetes version is set later, in [cluster.yaml](cluster.yaml).

```sh
export KUBECTL_VERSION="v1.37.0"
export KIND_VERSION="v0.33.0"
export KIND_CLUSTER_NAME="pocket"

case "$(uname -m)" in
  x86_64)  export K8S_ARCH="amd64" ;;
  aarch64) export K8S_ARCH="arm64" ;;
  *)
    echo "This guide supports Linux amd64 (x86_64) and arm64 (aarch64) only." >&2
    return 1 2>/dev/null || exit 1
    ;;
esac

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This guide is Linux only." >&2
  return 1 2>/dev/null || exit 1
fi

export K8S_LAB_HOME="$HOME/pocket-cluster"
export K8S_LAB_ROOT="$K8S_LAB_HOME/kubectl-${KUBECTL_VERSION}_kind-${KIND_VERSION}"
export K8S_LAB_BIN="$K8S_LAB_ROOT/bin"

mkdir -p "$K8S_LAB_BIN"
```

The initial directory layout is:

```
~/pocket-cluster/
└── kubectl-v1.37.0_kind-v0.33.0/
    └── bin/
```

`KUBECTL_VERSION` must stay in the same minor as the node `image:` in [cluster.yaml](cluster.yaml) (here both are 1.37).

## 4. Install kubectl

Download the pinned client and its published checksum ([install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)):

```sh
curl --fail --location \
  --output "$K8S_LAB_BIN/kubectl" \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"

curl --fail --location \
  --output "$K8S_LAB_ROOT/kubectl.sha256" \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256"

# two spaces between the hash and the filename, as sha256sum --check requires
printf '%s  %s\n' \
  "$(cat "$K8S_LAB_ROOT/kubectl.sha256")" \
  "$K8S_LAB_BIN/kubectl" \
  | sha256sum --check
```

Expected:

```
.../bin/kubectl: OK
```

Stop if verification fails.

```sh
chmod 0755 "$K8S_LAB_BIN/kubectl"
rm "$K8S_LAB_ROOT/kubectl.sha256"

file "$K8S_LAB_BIN/kubectl"
"$K8S_LAB_BIN/kubectl" version --client
```

Expected output of `file` includes `ELF 64-bit LSB executable` and either `x86-64` or `ARM aarch64`, matching `uname -m`. Expected client version: `v1.37.0`.

This binary is not on `PATH` until you source `activate` in step 10.

## 5. Install kind

kind publishes a `.sha256sum` next to each binary ([quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)):

```sh
curl --fail --location \
  --output "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" \
  "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${K8S_ARCH}"

curl --fail --location \
  --output "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum" \
  "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${K8S_ARCH}.sha256sum"

(
  cd "$K8S_LAB_BIN"
  sha256sum --check "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum"
)
```

Expected:

```
kind-linux-amd64: OK
```

or `kind-linux-arm64: OK`. Stop if verification fails.

```sh
mv "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "$K8S_LAB_BIN/kind"
chmod 0755 "$K8S_LAB_BIN/kind"
rm "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum"

file "$K8S_LAB_BIN/kind"
"$K8S_LAB_BIN/kind" version
```

Expected version line:

```
kind v0.33.0 go1.26.7 linux/amd64
```

The Go and arch suffix follow the binary you downloaded.

## 6. Set the Cluster Kubernetes Version

**This is where the cluster version is defined.** Open [cluster.yaml](cluster.yaml). Every node has an `image:` line. That image **is** the Kubernetes version kind will boot. kind has no separate `kubernetesVersion` field.

Default (small): one control plane, two workers, Kubernetes v1.37.0:

```yaml
image: kindest/node:v1.37.0
```

That same line is on the control plane and on both workers. Change the cluster version by changing **every** `image:` to a new `kindest/node:vX.Y.Z` from the [kind release notes](https://github.com/kubernetes-sigs/kind/releases), then recreate the cluster. Also move `KUBECTL_VERSION` in step 3 so the client stays in the same minor.

The file also has **commented samples**: three workers, and a control-plane-only layout. To use a sample, copy its `nodes:` list over the live list, then recreate. Keep a single `role: control-plane`.

Copy the file into the versioned lab root so daily use does not depend on the git clone path:

```sh
cp "$GUIDE_DIR/cluster.yaml" "$K8S_LAB_ROOT/cluster.yaml"
```

Host ports `8080` and `8443` map to node ports `80` and `443` so an ingress controller you add later can be reached without a privileged bind.

## 7. Create the Reusable Activation File

The activation file restores the variables in every new terminal and defines the helper functions. `kind create` reads Kubernetes version from `cluster.yaml`. It does not take a separate `--image` flag here, so the file stays the single source.

```sh
cat > "$K8S_LAB_ROOT/activate" <<'EOF'
# Pocket Cluster
# Source this file; do not execute it as a standalone process.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "This file must be sourced:" >&2
  echo '  source "$HOME/pocket-cluster/activate"' >&2
  exit 1
fi

export KUBECTL_VERSION="v1.37.0"
export KIND_VERSION="v0.33.0"
export KIND_CLUSTER_NAME="pocket"

export K8S_LAB_HOME="$HOME/pocket-cluster"
export K8S_LAB_ROOT="$K8S_LAB_HOME/kubectl-${KUBECTL_VERSION}_kind-${KIND_VERSION}"
export K8S_LAB_BIN="$K8S_LAB_ROOT/bin"

if [[ ! -x "$K8S_LAB_BIN/kubectl" || ! -x "$K8S_LAB_BIN/kind" ]]; then
  echo "The pinned kubectl or kind binary is missing or not executable:" >&2
  echo "  $K8S_LAB_BIN" >&2
  return 1
fi

if [[ ! -f "$K8S_LAB_ROOT/cluster.yaml" ]]; then
  echo "kind cluster config is missing:" >&2
  echo "  $K8S_LAB_ROOT/cluster.yaml" >&2
  return 1
fi

# Save the pre-activation PATH once. Re-sourcing does not duplicate entries.
if [[ -z "${K8S_LAB_OLD_PATH+x}" ]]; then
  export K8S_LAB_OLD_PATH="$PATH"
fi

export PATH="$K8S_LAB_BIN:$K8S_LAB_OLD_PATH"

# Leave ~/.kube/config untouched.
export KUBECONFIG="$K8S_LAB_ROOT/kubeconfig"

mkdir -p "$(dirname "$KUBECONFIG")"

if [[ ! -e "$KUBECONFIG" ]]; then
  touch "$KUBECONFIG"
fi

chmod 0600 "$KUBECONFIG"
hash -r

alias k=kubectl

if command -v kubectl >/dev/null 2>&1; then
  # session-only completion; matches the CKAD habit of alias k=kubectl
  source <(kubectl completion bash 2>/dev/null) || true
  complete -o default -F __start_kubectl k 2>/dev/null || true
fi

k8s_lab_require_docker() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker is not ready. Start the engine and confirm this user is in the docker group." >&2
    return 1
  fi
}

k8s_lab_node_image() {
  awk '
    /^[[:space:]]*image:[[:space:]]*/ {
      sub(/^[[:space:]]*image:[[:space:]]*/, "")
      print
      exit
    }
  ' "$K8S_LAB_ROOT/cluster.yaml"
}

k8s_lab_info() {
  printf 'Pocket Cluster\n'
  printf '  kubectl:            %s\n' "$(command -v kubectl 2>/dev/null || printf 'not found')"
  printf '  kind:               %s\n' "$(command -v kind 2>/dev/null || printf 'not found')"
  printf '  KUBECTL_VERSION:    %s\n' "$KUBECTL_VERSION"
  printf '  KIND_VERSION:       %s\n' "$KIND_VERSION"
  printf '  KIND_CLUSTER_NAME:  %s\n' "$KIND_CLUSTER_NAME"
  printf '  cluster.yaml:       %s\n' "$K8S_LAB_ROOT/cluster.yaml"
  printf '  Kubernetes image:   %s\n' "$(k8s_lab_node_image)"
  printf '  KUBECONFIG:         %s\n' "$KUBECONFIG"
}

k8s_lab_start() {
  k8s_lab_require_docker || return 1

  if kind get clusters 2>/dev/null | grep -qx "$KIND_CLUSTER_NAME"; then
    kind export kubeconfig --name="$KIND_CLUSTER_NAME" --kubeconfig="$KUBECONFIG"
    chmod 0600 "$KUBECONFIG"
    echo "Cluster ${KIND_CLUSTER_NAME} already exists. kubeconfig exported."
    return 0
  fi

  # Kubernetes version comes from image: in cluster.yaml
  kind create cluster \
    --name="$KIND_CLUSTER_NAME" \
    --config="$K8S_LAB_ROOT/cluster.yaml" \
    --kubeconfig="$KUBECONFIG" \
    --wait=2m

  chmod 0600 "$KUBECONFIG"
}

k8s_lab_status() {
  kind get clusters
  kind get nodes --name="$KIND_CLUSTER_NAME"
  kubectl get nodes -o wide
}

k8s_lab_load_image() {
  if [[ $# -lt 1 ]]; then
    echo "usage: k8s_lab_load_image <image> [image...]" >&2
    return 1
  fi
  k8s_lab_require_docker || return 1
  kind load docker-image "$@" --name="$KIND_CLUSTER_NAME"
}

k8s_lab_delete_cluster() {
  kind delete cluster --name="$KIND_CLUSTER_NAME" --kubeconfig="$KUBECONFIG"
}

k8s_lab_deactivate() {
  if [[ -n "${K8S_LAB_OLD_PATH:-}" ]]; then
    export PATH="$K8S_LAB_OLD_PATH"
  fi

  unset K8S_LAB_OLD_PATH
  unset K8S_LAB_HOME
  unset K8S_LAB_ROOT
  unset K8S_LAB_BIN
  unset KUBECTL_VERSION
  unset KIND_VERSION
  unset KIND_CLUSTER_NAME
  unset KUBECONFIG

  unalias k 2>/dev/null || true

  unset -f k8s_lab_require_docker
  unset -f k8s_lab_node_image
  unset -f k8s_lab_info
  unset -f k8s_lab_start
  unset -f k8s_lab_status
  unset -f k8s_lab_load_image
  unset -f k8s_lab_delete_cluster
  unset -f k8s_lab_deactivate

  hash -r
  echo "Pocket Cluster environment deactivated."
}

echo "Pocket Cluster environment activated."
echo "Run 'k8s_lab_info' to inspect it."
EOF

chmod 0644 "$K8S_LAB_ROOT/activate"
```

kind has no `stop` or `pause` command. The nodes are Docker containers. To free RAM, delete the cluster (`k8s_lab_delete_cluster`). The node image stays in Docker, so the next `k8s_lab_start` is much faster than the first.

## 8. Create Stable Activation Links

The versioned installation directory may change during later upgrades. Create a stable `current` link and a stable top-level `activate` link:

```sh
if [[ -e "$K8S_LAB_HOME/current" && ! -L "$K8S_LAB_HOME/current" ]]; then
  echo "$K8S_LAB_HOME/current exists and is not a symbolic link." >&2
  return 1 2>/dev/null || exit 1
fi

if [[ -e "$K8S_LAB_HOME/activate" && ! -L "$K8S_LAB_HOME/activate" ]]; then
  echo "$K8S_LAB_HOME/activate exists and is not a symbolic link." >&2
  return 1 2>/dev/null || exit 1
fi

ln -sfn "$K8S_LAB_ROOT" "$K8S_LAB_HOME/current"
ln -sfn "current/activate" "$K8S_LAB_HOME/activate"
```

The project now has a stable entry point:

```
~/pocket-cluster/
├── activate -> current/activate
├── current -> kubectl-v1.37.0_kind-v0.33.0
└── kubectl-v1.37.0_kind-v0.33.0/
    ├── activate
    ├── cluster.yaml
    └── bin/
        ├── kubectl
        └── kind
```

From this point, type the stable activation path. You do not need the versioned directory name.

## 9. Activate the Environment

```sh
source "$HOME/pocket-cluster/activate"
```

Inspect the active environment:

```sh
k8s_lab_info
type -a kubectl
type -a kind
```

The first `kubectl` and `kind` must resolve under `$K8S_LAB_BIN`. A host kubectl, if present, stays later in `type -a kubectl`. `Kubernetes image` in `k8s_lab_info` is the first `image:` from `cluster.yaml`.

## 10. Verify the Pinned Client Versions

```sh
kubectl version --client --output=yaml
kind version
```

Expected primary versions:

```
kubectl: v1.37.0
kind:    v0.33.0
```

Strict checks:

```sh
actual_kubectl_version="$(
  kubectl version --client --output=json |
    awk -F'"' '/"gitVersion"/ { print $4; exit }'
)"

actual_kind_version="$(kind version | awk '{ print $2; exit }')"

[[ "$actual_kubectl_version" == "$KUBECTL_VERSION" ]] \
  && echo "kubectl version is correct" \
  || {
    echo "Unexpected kubectl version: $actual_kubectl_version" >&2
    return 1 2>/dev/null || exit 1
  }

[[ "$actual_kind_version" == "$KIND_VERSION" ]] \
  && echo "kind version is correct" \
  || {
    echo "Unexpected kind version: $actual_kind_version" >&2
    return 1 2>/dev/null || exit 1
  }
```

## 11. Create the Cluster

```sh
k8s_lab_start
```

kind reads [cluster.yaml](cluster.yaml) (the copy under `$K8S_LAB_ROOT`):

```
name:               pocket
nodes:              1 control-plane + 2 workers
Kubernetes version: image: kindest/node:v1.37.0 on each node
wait for Ready:     2m
kubeconfig:         $K8S_LAB_ROOT/kubeconfig
```

The first run pulls the node image. Later runs reuse Docker's cache. If the cluster already exists, the function exports kubeconfig and returns.

## 12. Verify the Cluster

```sh
k8s_lab_status
kubectl version
kubectl cluster-info
kubectl get pods --all-namespaces
kubectl get storageclass
```

Expected: three Ready nodes (`pocket-control-plane`, `pocket-worker`, `pocket-worker2`) and:

```
Client Version: v1.37.0
Server Version: v1.37.0
```

Wait for every node:

```sh
kubectl wait \
  --for=condition=Ready \
  node \
  --all \
  --timeout=180s
```

kind ships Rancher local-path provisioner. The default StorageClass is `standard`. PersistentVolumeClaims bind to disk inside the node containers.

kubectl context name is `kind-pocket`.

## 13. Confirm Isolation

```sh
printf 'kubectl=%s\n' "$(command -v kubectl)"
printf 'kind=%s\n' "$(command -v kind)"
printf 'KUBECONFIG=%s\n' "$KUBECONFIG"
printf 'KIND_CLUSTER_NAME=%s\n' "$KIND_CLUSTER_NAME"

kubectl config get-contexts
docker ps --filter "label=io.x-k8s.kind.cluster=${KIND_CLUSTER_NAME}" --format '{{.Names}} {{.Image}}'
```

Project-specific state:

```
~/pocket-cluster/
├── activate
├── current
└── kubectl-v1.37.0_kind-v0.33.0/
    ├── activate
    ├── cluster.yaml
    ├── kubeconfig
    └── bin/
        ├── kubectl
        └── kind
```

The following remain untouched:

```
any host kubectl already on PATH
~/.kube/config
```

## 14. Ship a First Application

A Deployment and a Service, with no cluster-bootstrap work. Two replicas can land on the two workers.

The `nginx:1.27` tag is a convenient example for this smoke. Pin a version tag in your own apps. The cluster version stays the `image:` in `cluster.yaml`.

```sh
kubectl create namespace demo

kubectl create deployment hello \
  --image=nginx:1.27 \
  --replicas=2 \
  -n demo

kubectl expose deployment hello \
  --port=80 \
  --target-port=80 \
  -n demo

kubectl rollout status deployment/hello -n demo --timeout=120s
kubectl get deploy,po,svc -n demo -o wide
```

Reach the Service from inside the cluster:

```sh
kubectl run curl \
  --rm -it --restart=Never \
  -n demo \
  --image=busybox:1.36 \
  -- wget -qO- http://hello
```

Expected: nginx HTML on stdout, then the curl pod exits. Tear the namespace down when you are done with this smoke:

```sh
kubectl delete namespace demo
```

---

# Part II — Daily Use and Lifecycle

This part covers normal use after the one-time setup is complete.

## 1. Start a New Terminal Session

Closing a terminal removes shell variables, PATH changes, aliases, and helper functions. It leaves the installation and the Docker containers.

In every new terminal:

```sh
source "$HOME/pocket-cluster/activate"
```

Then:

```sh
k8s_lab_info
k8s_lab_status
```

If the cluster is missing, start it:

```sh
k8s_lab_start
```

If it is already running, use it:

```sh
kubectl get nodes
kubectl get pods --all-namespaces
```

The session alias `k` is `kubectl`. Example: `k get po -A`.

## 2. Understand What Survives Terminal Closure

| Item                        | Survives terminal closure? | Location or behavior                                      |
| --------------------------- | -------------------------- | --------------------------------------------------------- |
| Pinned `kubectl` binary     | Yes                        | Under the versioned project directory                     |
| Pinned kind binary          | Yes                        | Under the versioned project directory                     |
| Stable activation link      | Yes                        | `~/pocket-cluster/activate`                               |
| Isolated kubeconfig         | Yes                        | Under the versioned project directory                     |
| kind cluster config         | Yes                        | `$K8S_LAB_ROOT/cluster.yaml` (Kubernetes `image:` lives here) |
| Running kind nodes          | Usually yes                | Docker containers, until deleted or Docker stops          |
| Node image in Docker        | Yes                        | Docker image cache                                        |
| Exported variables          | No                         | Restore by sourcing `activate`                            |
| PATH precedence             | No                         | Restore by sourcing `activate`                            |
| Helper functions and `k`    | No                         | Restore by sourcing `activate`                            |

The reactivation command is daily use, not a reinstall.

## 3. Command Reference

After activation:

| Command                          | Effect                                                              |
| -------------------------------- | ------------------------------------------------------------------- |
| `k8s_lab_info`                   | Show paths, versions, cluster name, and the `image:` from cluster.yaml |
| `k8s_lab_start`                  | Create the cluster from cluster.yaml, or export kubeconfig if it exists |
| `k8s_lab_status`                 | List kind clusters, node containers, and Kubernetes nodes           |
| `k8s_lab_load_image <image>`     | Load a local Docker image into the kind nodes                       |
| `k8s_lab_delete_cluster`         | Delete the `pocket` cluster (kind delete is idempotent)             |
| `k8s_lab_deactivate`             | Restore the shell's original PATH and variables                     |

kind has no stop/pause. Deleting the cluster frees the node containers. The next start reuses the cached node image.

## 4. Load a Local Image

kind nodes do not see images that exist only on the host Docker daemon. After `docker build` or `docker pull` on the laptop:

```sh
k8s_lab_load_image my-app:dev
```

In the Pod spec, set `image: my-app:dev` and `imagePullPolicy: IfNotPresent` (or `Never`). A unique tag per build avoids stale layers. See [kind load](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).

## 5. Deactivate Only the Current Shell

```sh
k8s_lab_deactivate
```

This restores the original `PATH` and removes the lab variables and helper functions. It leaves the kind cluster running.

Confirm the host kubectl, if any, is selected again:

```sh
command -v kubectl
kubectl version --client
```

Closing the terminal has the same shell-reset effect as deactivation.

## 6. Restart After Docker Was Stopped

After the Docker engine is running again:

```sh
source "$HOME/pocket-cluster/activate"
docker info >/dev/null && echo "Docker is ready"
kind get clusters
kubectl get nodes
```

If the node containers are gone or the nodes stay NotReady, delete and create:

```sh
k8s_lab_delete_cluster
k8s_lab_start
k8s_lab_status
```

Workloads from the old cluster are gone after delete. Treat kind as disposable: manifests live in git, the cluster is cheap to recreate.

## 7. Delete the Cluster but Keep the Tools

```sh
source "$HOME/pocket-cluster/activate"
k8s_lab_delete_cluster
```

This removes the `pocket` containers and the Docker network membership for that cluster. It leaves the pinned kubectl, kind binary, activation file, and node image.

Create a clean cluster later with:

```sh
k8s_lab_start
```

## 8. Completely Uninstall Pocket Cluster

This removes the kind cluster and the pinned toolchain. Docker Engine and any host kubectl stay.

```sh
source "$HOME/pocket-cluster/activate"

lab_home="$K8S_LAB_HOME"
install_root="$K8S_LAB_ROOT"

k8s_lab_delete_cluster
k8s_lab_deactivate

rm -f "$lab_home/activate"
rm -f "$lab_home/current"
rm -rf "$install_root"
rmdir "$lab_home" 2>/dev/null || true
```

Optional: remove the cached node image if you want that disk back:

```sh
docker image rm \
  'kindest/node:v1.37.0'
```

## 9. Optional Bash Convenience Function

The normal activation command is:

```sh
source "$HOME/pocket-cluster/activate"
```

For a shorter command, add this function to the Bash startup file this terminal uses:

```sh
k8s_lab_activate() {
  source "$HOME/pocket-cluster/activate"
}
```

After reloading that file:

```sh
k8s_lab_activate
```

This convenience function does not change `PATH` in every shell on its own. It only shortens the explicit activation.

## 10. Update Pinned Versions Later

Treat an upgrade as a new versioned installation.

1. Read the [kind release notes](https://github.com/kubernetes-sigs/kind/releases) and pick a Kubernetes node image tag from that release (`kindest/node:vX.Y.Z`).
2. Put that image on **every** `image:` line in [cluster.yaml](cluster.yaml). That is the cluster version.
3. Set `KUBECTL_VERSION` to the same minor and install that kubectl (Part I steps 3–4).
4. Recheck the CKAD exam Kubernetes version if you are studying for the exam.
5. Create a new versioned directory under `~/pocket-cluster`.
6. Copy the updated `cluster.yaml` into it.
7. Write its version-specific activation file.
8. Delete the old `pocket` cluster, or use a different `name:` in cluster.yaml.
9. Point `current` at the new versioned directory.
10. Keep the old directory for a while, then remove it after the new environment works.

After installing a new version:

```sh
ln -sfn "$NEW_K8S_LAB_ROOT" "$HOME/pocket-cluster/current"
```

The top-level activation link remains:

```
~/pocket-cluster/activate -> current/activate
```

Daily activation stays:

```sh
source "$HOME/pocket-cluster/activate"
```

Two versioned environments must not share the cluster name `pocket` at the same time. Delete the old cluster first, or pick a new name.

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
ls -la "$HOME/pocket-cluster"
```

Recreate the stable links for the installed version:

```sh
export K8S_LAB_HOME="$HOME/pocket-cluster"
export K8S_LAB_ROOT="$K8S_LAB_HOME/kubectl-v1.37.0_kind-v0.33.0"

ln -sfn "$K8S_LAB_ROOT" "$K8S_LAB_HOME/current"
ln -sfn "current/activate" "$K8S_LAB_HOME/activate"

source "$HOME/pocket-cluster/activate"
```

## The Host kubectl Is Still Selected

```sh
source "$HOME/pocket-cluster/activate"
hash -r
type -a kubectl
```

The project `bin` directory must appear before `/usr/local/bin` and `/usr/bin`.

## Docker Is Unavailable

```sh
docker context show
docker info
groups
```

Start the Docker engine. If `docker` returns permission denied, this user is missing from the `docker` group; log out and back in after `usermod -aG docker "$USER"` (that `usermod` is a host change, outside this lab's no-sudo install).

## kubectl Cannot Find the Cluster

```sh
source "$HOME/pocket-cluster/activate"
k8s_lab_info
k8s_lab_status
kubectl config get-contexts
```

The project kubeconfig should be active. Context name: `kind-pocket`.

## The Shell Variables Disappeared

Expected after closing the terminal. Restore them with:

```sh
source "$HOME/pocket-cluster/activate"
```

Skip the download steps.

## The Cluster Is Missing

```sh
source "$HOME/pocket-cluster/activate"
k8s_lab_start
```

## Host Port 8080 or 8443 Is Already in Use

kind create fails if those host ports are taken. Stop the other process, or change `hostPort` in `$K8S_LAB_ROOT/cluster.yaml` and recreate the cluster.

## A Pod Stays ImagePullBackOff for a Local Image

Load it into kind, then set `imagePullPolicy: IfNotPresent`:

```sh
k8s_lab_load_image my-app:dev
```

`--name pocket` is already inside `k8s_lab_load_image`.

## NetworkPolicy Seems to Do Nothing

Apply a default-deny in a test namespace and confirm traffic is dropped. If it is not, check `kubectl -n kube-system logs ds/kindnet`. Replacing kindnet with Calico is a later optional step (`disableDefaultCNI: true`).

## Cgroup v1

Kubernetes 1.37 and this node image expect cgroup v2. If `stat -fc %T /sys/fs/cgroup` is not `cgroup2fs`, use a host with cgroup v2, or pick an older kind node image from a kind release that still lists a 1.34/1.35 image. Change every `image:` in [cluster.yaml](cluster.yaml). This file stays on 1.37.

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
