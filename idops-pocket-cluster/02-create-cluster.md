# 02. Create the Cluster

**Goal:** Start Pocket Cluster, confirm four Ready nodes, and know the daily commands.

## Teaching note

kind reads `$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml`: name `idops-pocket-k8s-cluster`, one control plane, three workers, image `kindest/node:v1.37.0`. The first run pulls that image.

`k8s_lab_start` creates the cluster if it is missing. If the cluster exists and the worker count matches the yaml, it only exports kubeconfig. If the yaml wants a different worker count, it deletes and recreates. After the cluster is up it caps each Docker node (`docker update`), labels workers, taints the control plane (`node-role.kubernetes.io/control-plane:NoSchedule`), and starts Cloud Provider KIND so Ingress gets an ADDRESS on the docker network. Application Pods run on workers. `k8s_lab_load_image` loads images onto workers only.

Do not put a worker role label in the yaml: kubelet will refuse it at join.

kind names the first worker `{cluster}-worker`, then `{cluster}-worker2`, `{cluster}-worker3`. That is the container hostname and the Kubernetes node name.

kind ships Rancher local-path provisioner. Default StorageClass is `standard`. kubectl context name is `kind-idops-pocket-k8s-cluster`.

Every command here is safe to run again.

## Prerequisites

- [01-install-tools.md](01-install-tools.md) finished, `source /opt/idops-pocket-cluster/activate` succeeded

## Steps

**1. Create the cluster** — first create waits on the node image pull. An old cluster named `pocket` is leftover from an earlier name; kind delete is a no-op if that name is already gone.
```sh
source /opt/idops-pocket-cluster/activate
kind delete cluster --name pocket                            # leftover name; skip if you never used it
k8s_lab_start
tail -n 20 "$K8S_LAB_ROOT/cloud-provider-kind.log"           # Cloud Provider KIND must be running
```

**2. Verify** — expected names: `idops-pocket-k8s-cluster-control-plane`, `idops-pocket-k8s-cluster-worker`, `idops-pocket-k8s-cluster-worker2`, `idops-pocket-k8s-cluster-worker3`. Client and server `v1.37.0`. Worker `ROLES` is `worker`. Control plane taint is `node-role.kubernetes.io/control-plane:NoSchedule`. `docker stats` LIMIT is `2GiB` on each node.
```sh
k8s_lab_status
kubectl version
kubectl cluster-info
kubectl get pods --all-namespaces
kubectl get storageclass
kubectl wait --for=condition=Ready node --all --timeout=180s
kubectl get nodes
printf 'kubectl=%s kind=%s KUBECONFIG=%s\n' "$(command -v kubectl)" "$(command -v kind)" "$KUBECONFIG"
kubectl config get-contexts
docker ps --filter "label=io.x-k8s.kind.cluster=${KIND_CLUSTER_NAME}" --format '{{.Names}} {{.Image}}'
```

Project-specific state is under `/opt/idops-pocket-cluster`. Host kubectl and `~/.kube/config` stay untouched.

**3. Daily session** — closing a terminal drops `PATH`, `KUBECONFIG`, `k`, and the helper functions. Binaries, kubeconfig on disk, and Docker containers stay. `k` is `kubectl`. Tab-complete works on both after `source`.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_info
k8s_lab_start                                                # create if missing; export kubeconfig if it exists
kubectl get nodes
kubectl get pods --all-namespaces
k9s                                                          # TUI, same KUBECONFIG, logo- and splash-free
```

`k9s` with no arguments reads `$KUBECONFIG`, the same file `kubectl` uses — no separate setup. `:q` or `Ctrl-c` exits back to the shell.

| Item                          | Survives terminal closure? | Location or behavior                             |
| ----------------------------- | -------------------------- | ------------------------------------------------ |
| Pinned binaries               | Yes                        | `/opt/idops-pocket-cluster/.../bin`              |
| Stable activation link        | Yes                        | `/opt/idops-pocket-cluster/activate`             |
| Isolated kubeconfig           | Yes                        | under the versioned directory                    |
| Isolated k9s config           | Yes                        | `$K9S_CONFIG_DIR/config.yaml`, under the versioned directory |
| kind cluster config           | Yes                        | `$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml`    |
| Running kind nodes            | Usually yes                | Docker containers, until deleted or Docker stops |
| Node image in Docker          | Yes                        | Docker image cache                               |
| Exported variables, PATH, `k` | No                         | Restore by sourcing `activate`                   |

After activation:

| Command                      | Effect                                                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `k8s_lab_info`               | Show paths, versions, cluster name, and the `image:` from the yaml                                                 |
| `k8s_lab_start`              | Create or reuse the cluster; cap Docker CPU/RAM; label workers; taint the control plane; start Cloud Provider KIND |
| `k8s_lab_status`             | List kind clusters, node containers, Kubernetes nodes, taints, and `docker stats`                                  |
| `k8s_lab_load_image <image>` | Load a local Docker image onto worker nodes only                                                                   |
| `k8s_lab_delete_cluster`     | Delete `idops-pocket-k8s-cluster` (kind delete is idempotent)                                                      |
| `k8s_lab_deactivate`         | Restore the shell's original PATH and variables                                                                    |

Optional shorter activate in your Bash startup file:

```sh
k8s_lab_activate() { source /opt/idops-pocket-cluster/activate; }
```

**4. Load a local image** — kind worker nodes do not see images that exist only on the host Docker daemon. `k8s_lab_load_image` loads onto workers only; the control plane is skipped. In the Pod spec, set `imagePullPolicy: IfNotPresent` (or `Never`). See [kind load](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).
```sh
k8s_lab_load_image my-app:dev
```

**5. Restart after Docker was stopped** — if node containers are gone or nodes stay NotReady, delete and create again. Workloads from the old cluster are gone after delete.
```sh
source /opt/idops-pocket-cluster/activate
docker info >/dev/null && echo "Docker is ready"
kind get clusters
kubectl get nodes
k8s_lab_delete_cluster                                       # only if nodes are gone or stay NotReady
k8s_lab_start
k8s_lab_status
```

**6. Delete the cluster but keep the tools** — removes the `idops-pocket-k8s-cluster` containers. kubectl, kind, and `/opt/idops-pocket-cluster` stay.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_delete_cluster
```

To create it again, run `k8s_lab_start`.

**7. Completely uninstall** — Docker Engine and any host kubectl stay. `/opt` needs root to remove. Confirm before you run `rm -rf`.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_delete_cluster
k8s_lab_deactivate
sudo rm -rf /opt/idops-pocket-cluster
docker image rm kindest/node:v1.37.0 2>/dev/null || true     # optional: free the cached node image
```

If `/opt/pocket-cluster` is left from an older install, remove it the same way after this tree works: `sudo rm -rf /opt/pocket-cluster`.

**8. Update pinned versions later** — treat an upgrade as a new versioned directory under `/opt/idops-pocket-cluster`.

1. Pick a `kindest/node:vX.Y.Z` from the [kind release notes](https://github.com/kubernetes-sigs/kind/releases).
2. Put that tag on every `image:` line in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml).
3. Set `KUBECTL_VERSION` to the same minor and re-run [01-install-tools.md](01-install-tools.md) into the new directory.
4. Recheck the CKAD exam Kubernetes version if you are studying for the exam.
5. Copy `idops-pocket-k8s-cluster.yaml`, `activate`, and `k9s-config.yaml` (into a new `k9s-config/config.yaml`) into the new versioned directory. `K9S_VERSION` is independent of the cluster version — recheck [github.com/derailed/k9s/releases](https://github.com/derailed/k9s/releases) on its own schedule, it does not need to move just because the cluster did.
6. Delete the old cluster, or use a different `name:` in the yaml.
7. Point `current` at the new directory: `ln -sfn "$NEW_K8S_LAB_ROOT" /opt/idops-pocket-cluster/current`.

Daily activation stays `source /opt/idops-pocket-cluster/activate`. Two versioned environments must not share the cluster name `idops-pocket-k8s-cluster` at the same time.

## Troubleshooting

**Activation file missing**
```sh
ls -la /opt/idops-pocket-cluster
ln -sfn /opt/idops-pocket-cluster/kubectl-v1.37.0_kind-v0.33.0 /opt/idops-pocket-cluster/current
ln -sfn current/activate /opt/idops-pocket-cluster/activate
source /opt/idops-pocket-cluster/activate
```

**Host kubectl is still selected** — `/opt/idops-pocket-cluster/.../bin` must appear before `/usr/local/bin` and `/usr/bin`.
```sh
source /opt/idops-pocket-cluster/activate
hash -r
type -a kubectl
```

**Docker is unavailable** — start the engine. If `docker` returns permission denied, this user is missing from the `docker` group. After `sudo usermod -aG docker "$USER"`, log out and back in.
```sh
docker context show
docker info
groups
```

**kubectl cannot find the cluster** — context name is `kind-idops-pocket-k8s-cluster`. Closing a terminal drops the session; source `activate` again and skip the download steps.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_info
k8s_lab_status
kubectl config get-contexts
k8s_lab_start                                                # if the cluster is missing
```

**Joining workers failed / kubelet healthz** — kind create can sit on "Joining worker nodes" for about four minutes, then delete the cluster. kubeadm reports kubelet healthz on `127.0.0.1:10248` connection refused. Do not put `node-role.kubernetes.io/worker` (or any reserved `kubernetes.io` label) in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml) `labels:`. Copy the repo yaml and [activate](activate) into `/opt/idops-pocket-cluster` again, then retry `k8s_lab_start`.

**Worker names are not worker1** — kind sets the hostname to `idops-pocket-k8s-cluster-worker`, then `...-worker2`, `...-worker3`. kind has no hostname field. `docker rename` and `hostname` inside the container do not retarget kubelet.

**Cgroup v1** — Kubernetes 1.37 expects cgroup v2. If `stat -fc %T /sys/fs/cgroup` is not `cgroup2fs`, use a host with cgroup v2, or pick an older `kindest/node` tag and change every `image:` in the yaml. This lab stays on 1.37.

**Docker stats show the whole laptop RAM** — kind YAML cannot set `--memory` or `--cpus` on the Cluster object. Caps are the `PocketResources` document in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). `k8s_lab_start` applies them with `docker update`. Confirm with `docker stats` (`180MiB / 2GiB` means the cap is 2GiB). `docker ps` has no memory column. kubelet may still print host RAM in `kubectl get nodes`.

**Ingress ADDRESS stays empty** — Cloud Provider KIND is not running, or it cannot talk to Docker.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_start
tail -n 50 "$K8S_LAB_ROOT/cloud-provider-kind.log"
```

**NetworkPolicy seems to do nothing** — apply a default-deny in a test namespace and confirm traffic is dropped. If it is not, check `kubectl -n kube-system logs ds/kindnet`. Replacing kindnet with Calico is a later optional step (`disableDefaultCNI: true`).

**A Pod stays ImagePullBackOff for a local image**
```sh
k8s_lab_load_image my-app:dev                                # workers only; --name is already inside the helper
```

Set `imagePullPolicy: IfNotPresent`.

## Next

- [03-hello-nginx.md](03-hello-nginx.md)
