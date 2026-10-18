# 01. Install Tools

**Goal:** Put pinned kubectl, kind, Helm 3, cloud-provider-kind, and k9s under `/opt/idops-pocket-cluster`, then activate the session.

## Teaching note

The Kubernetes **cluster** version is the `image:` field on every node in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). The kubectl **client** version is `KUBECTL_VERSION` below. Match those two minors.

Work from this directory so the yaml and [activate](activate) are next to you. Each step is one short note, then one command block. Comments mark why a line is there. Stop if a checksum is not `OK`.

Older clones used `/opt/pocket-cluster`. This tree is `/opt/idops-pocket-cluster`. Run this document from the top. The kind cluster name is still `idops-pocket-k8s-cluster`.

Every command here is safe to run again. Install overwrites the same pins.

## Prerequisites

- [00-overview.md](00-overview.md)
- Linux, Bash, Docker Engine, this user in the `docker` group, cgroup v2

## Steps

**1. Confirm the host** — Linux `x86_64` or `aarch64`, Bash, cgroup v2, Docker without `sudo`. Kubernetes 1.37 needs cgroup v2. Leave any host kubectl in place; the next steps install a second binary under `/opt`.
```sh
cd /path/to/kubernetes-lab/idops-pocket-cluster
GUIDE_DIR="$(pwd)"
uname -ms                                                    # Linux plus x86_64 or aarch64
printf 'Shell: %s Bash: %s\n' "$SHELL" "$BASH_VERSION"
stat -fc %T /sys/fs/cgroup                                   # expected: cgroup2fs
id -nG                                                       # this user must be in docker
docker context show
docker info >/dev/null && echo "Docker is ready"
docker info --format 'Architecture={{.Architecture}} CPUs={{.NCPU}} MemoryBytes={{.MemTotal}}'
type -a kubectl 2>/dev/null || true                          # leave the host binary alone
```

Three kind nodes plus the node image need several GB of RAM and disk. First create pulls `kindest/node` (about a gigabyte).

**2. Pin versions and create `/opt`** — `sudo` is only here, so the directory exists and your user owns it. Daily `source` does not need root. `KUBECTL_VERSION` must stay in the same minor as the node `image:` (here both are 1.37).
```sh
export KUBECTL_VERSION="v1.37.0"
export KIND_VERSION="v0.33.0"
export KIND_CLUSTER_NAME="idops-pocket-k8s-cluster"
export HELM_VERSION="v3.22.0"
export CLOUD_PROVIDER_KIND_VERSION="v0.12.0"
export K9S_VERSION="v0.51.0"
case "$(uname -m)" in x86_64) export K8S_ARCH=amd64 ;; aarch64) export K8S_ARCH=arm64 ;; *) echo "This guide supports Linux amd64 (x86_64) and arm64 (aarch64) only." >&2; return 1 2>/dev/null || exit 1 ;; esac
[ "$(uname -s)" = Linux ] || { echo "This guide is Linux only." >&2; return 1 2>/dev/null || exit 1; }
export K8S_LAB_HOME="/opt/idops-pocket-cluster"
export K8S_LAB_ROOT="$K8S_LAB_HOME/kubectl-${KUBECTL_VERSION}_kind-${KIND_VERSION}"
export K8S_LAB_BIN="$K8S_LAB_ROOT/bin"
sudo mkdir -p "$K8S_LAB_BIN"
sudo chown -R "$USER:$USER" "$K8S_LAB_HOME"                  # daily source and kubectl do not need root
```

Layout after this step:

```
/opt/idops-pocket-cluster/
└── kubectl-v1.37.0_kind-v0.33.0/
    └── bin/
```

**3. Install kubectl** — pinned client ([install kubectl on Linux](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)). `sha256sum --check` needs two spaces between the hash and the filename. Stop if the check fails.
```sh
curl --fail --location --output "$K8S_LAB_BIN/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"
curl --fail --location --output "$K8S_LAB_ROOT/kubectl.sha256" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl.sha256"
printf '%s  %s\n' "$(cat "$K8S_LAB_ROOT/kubectl.sha256")" "$K8S_LAB_BIN/kubectl" | sha256sum --check
chmod 0755 "$K8S_LAB_BIN/kubectl"
rm -f "$K8S_LAB_ROOT/kubectl.sha256"
file "$K8S_LAB_BIN/kubectl"
"$K8S_LAB_BIN/kubectl" version --client                      # expected: v1.37.0
```

This binary is not on `PATH` until you source `activate`.

**4. Install kind** — the checksum file names `kind-linux-amd64` or `kind-linux-arm64`, so the check runs inside `bin`. Copy then delete the download so a second pass is safe ([kind quick start](https://kind.sigs.k8s.io/docs/user/quick-start/)).
```sh
curl --fail --location --output "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${K8S_ARCH}"
curl --fail --location --output "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum" "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-${K8S_ARCH}.sha256sum"
( cd "$K8S_LAB_BIN" && sha256sum --check "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum" )
cp "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "$K8S_LAB_BIN/kind"  # cp then rm, not mv
chmod 0755 "$K8S_LAB_BIN/kind"
rm -f "$K8S_LAB_BIN/kind-linux-${K8S_ARCH}" "$K8S_LAB_ROOT/kind-linux-${K8S_ARCH}.sha256sum"
file "$K8S_LAB_BIN/kind"
"$K8S_LAB_BIN/kind" version                                  # expected: kind v0.33.0
```

**5. Install Helm 3** — Debian's apt package named `helm` is Emacs. `v3.22.0` is the last Helm 3 feature release. Recheck [github.com/helm/helm/releases](https://github.com/helm/helm/releases).
```sh
curl --fail --location --output "$K8S_LAB_ROOT/helm.tgz" "https://get.helm.sh/helm-${HELM_VERSION}-linux-${K8S_ARCH}.tar.gz"
curl --fail --location --output "$K8S_LAB_ROOT/helm.sha256" "https://get.helm.sh/helm-${HELM_VERSION}-linux-${K8S_ARCH}.tar.gz.sha256"
printf '%s  %s\n' "$(cat "$K8S_LAB_ROOT/helm.sha256")" "$K8S_LAB_ROOT/helm.tgz" | sha256sum --check
tar -xzf "$K8S_LAB_ROOT/helm.tgz" -C "$K8S_LAB_ROOT" "linux-${K8S_ARCH}/helm"
cp "$K8S_LAB_ROOT/linux-${K8S_ARCH}/helm" "$K8S_LAB_BIN/helm"
chmod 0755 "$K8S_LAB_BIN/helm"
rm -rf "$K8S_LAB_ROOT/helm.tgz" "$K8S_LAB_ROOT/helm.sha256" "$K8S_LAB_ROOT/linux-${K8S_ARCH}"
"$K8S_LAB_BIN/helm" version                                  # expected: v3.22.0
```

**6. Install cloud-provider-kind** — official kind Ingress and LoadBalancer provider. Pin `v0.12.0`. Recheck [cloud-provider-kind releases](https://github.com/kubernetes-sigs/cloud-provider-kind/releases).
```sh
curl --fail --location --output "$K8S_LAB_ROOT/cloud-provider-kind_0.12.0_linux_${K8S_ARCH}.tar.gz" "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/${CLOUD_PROVIDER_KIND_VERSION}/cloud-provider-kind_0.12.0_linux_${K8S_ARCH}.tar.gz"
curl --fail --location --output "$K8S_LAB_ROOT/cloud-provider-kind.checksums.txt" "https://github.com/kubernetes-sigs/cloud-provider-kind/releases/download/${CLOUD_PROVIDER_KIND_VERSION}/cloud-provider-kind_0.12.0_checksums.txt"
( cd "$K8S_LAB_ROOT" && grep "cloud-provider-kind_0.12.0_linux_${K8S_ARCH}.tar.gz$" cloud-provider-kind.checksums.txt | sha256sum --check )
mkdir -p "$K8S_LAB_ROOT/cpk-extract"
tar -xzf "$K8S_LAB_ROOT/cloud-provider-kind_0.12.0_linux_${K8S_ARCH}.tar.gz" -C "$K8S_LAB_ROOT/cpk-extract"
cp "$K8S_LAB_ROOT/cpk-extract/cloud-provider-kind" "$K8S_LAB_BIN/cloud-provider-kind"
chmod 0755 "$K8S_LAB_BIN/cloud-provider-kind"
rm -rf "$K8S_LAB_ROOT/cpk-extract" "$K8S_LAB_ROOT/cloud-provider-kind_0.12.0_linux_${K8S_ARCH}.tar.gz" "$K8S_LAB_ROOT/cloud-provider-kind.checksums.txt"
"$K8S_LAB_BIN/cloud-provider-kind" --help >/dev/null && echo "cloud-provider-kind is installed"
```

**7. Install k9s** — terminal UI for the cluster, same kind of install as cloud-provider-kind: a pinned GitHub release tarball, checksum-verified, not a distro package. Same pin (`v0.51.0`) as the bastion k9s in the KVM HA lab (`../05-deploy-kubernetes.md`). The archive extracts a flat `k9s` binary, no subdirectory.
```sh
curl --fail --location --output "$K8S_LAB_ROOT/k9s_Linux_${K8S_ARCH}.tar.gz" "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${K8S_ARCH}.tar.gz"
curl --fail --location --output "$K8S_LAB_ROOT/k9s.checksums.sha256" "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/checksums.sha256"
( cd "$K8S_LAB_ROOT" && grep "k9s_Linux_${K8S_ARCH}.tar.gz$" k9s.checksums.sha256 | sha256sum --check )
mkdir -p "$K8S_LAB_ROOT/k9s-extract"
tar -xzf "$K8S_LAB_ROOT/k9s_Linux_${K8S_ARCH}.tar.gz" -C "$K8S_LAB_ROOT/k9s-extract"
cp "$K8S_LAB_ROOT/k9s-extract/k9s" "$K8S_LAB_BIN/k9s"
chmod 0755 "$K8S_LAB_BIN/k9s"
rm -rf "$K8S_LAB_ROOT/k9s-extract" "$K8S_LAB_ROOT/k9s_Linux_${K8S_ARCH}.tar.gz" "$K8S_LAB_ROOT/k9s.checksums.sha256"
file "$K8S_LAB_BIN/k9s"
"$K8S_LAB_BIN/k9s" version                                   # expected: v0.51.0
```

**8. Copy config and activate** — **this is where the cluster version is defined.** Open [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml). Every node has `image: kindest/node:v1.37.0`. Change the cluster version by changing every `image:` to a new `kindest/node:vX.Y.Z` from the [kind release notes](https://github.com/kubernetes-sigs/kind/releases), then recreate the cluster. Copy into `/opt` so daily use does not depend on the git clone path. App manifests stay in the clone; `/opt` is the toolchain. [k9s-config.yaml](k9s-config.yaml) and [k9s-skin-transparent.yaml](k9s-skin-transparent.yaml) are the same copy-in treatment, into their own subdirectory so they never touch `~/.config/k9s`. The skin turns off k9s's own background color (`ui.skin: transparent` in the config, pointing at this skin file) — k9s does not bundle it, so without the copy the `skin: transparent` setting has nothing to load.
```sh
cp "$GUIDE_DIR/idops-pocket-k8s-cluster.yaml" "$K8S_LAB_ROOT/idops-pocket-k8s-cluster.yaml"
cp "$GUIDE_DIR/activate" "$K8S_LAB_ROOT/activate"
chmod 0644 "$K8S_LAB_ROOT/activate"
mkdir -p "$K8S_LAB_ROOT/k9s-config/skins"
cp "$GUIDE_DIR/k9s-config.yaml" "$K8S_LAB_ROOT/k9s-config/config.yaml"
cp "$GUIDE_DIR/k9s-skin-transparent.yaml" "$K8S_LAB_ROOT/k9s-config/skins/transparent.yaml"
chmod 0644 "$K8S_LAB_ROOT/k9s-config/config.yaml" "$K8S_LAB_ROOT/k9s-config/skins/transparent.yaml"
ln -sfn "$K8S_LAB_ROOT" "$K8S_LAB_HOME/current"              # later upgrades retarget this one link
ln -sfn "current/activate" "$K8S_LAB_HOME/activate"
```

Layout:

```
/opt/idops-pocket-cluster/
├── activate -> current/activate
├── current -> kubectl-v1.37.0_kind-v0.33.0
└── kubectl-v1.37.0_kind-v0.33.0/
    ├── activate
    ├── idops-pocket-k8s-cluster.yaml
    ├── k9s-config/
    │   ├── config.yaml
    │   └── skins/
    │       └── transparent.yaml
    └── bin/
        ├── kubectl
        ├── kind
        ├── helm
        ├── cloud-provider-kind
        └── k9s
```

**9. Activate and check versions** — `activate` puts `$K8S_LAB_BIN` first on `PATH`, sets `KUBECONFIG` and `K9S_CONFIG_DIR`, aliases `k` to `kubectl`, and loads bash completion. The first `kubectl`, `kind`, `cloud-provider-kind`, and `k9s` must resolve under `$K8S_LAB_BIN`.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_info
type -a kubectl kind helm cloud-provider-kind k9s
kubectl version --client --output=yaml
kind version
helm version
k9s version
actual_kubectl_version="$(kubectl version --client --output=json | awk -F'"' '/"gitVersion"/ { print $4; exit }')"
actual_kind_version="$(kind version | awk '{ print $2; exit }')"
actual_k9s_version="$(k9s version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
[[ "$actual_kubectl_version" == "$KUBECTL_VERSION" ]] && echo "kubectl version is correct" || { echo "Unexpected kubectl version: $actual_kubectl_version" >&2; return 1 2>/dev/null || exit 1; }
[[ "$actual_kind_version" == "$KIND_VERSION" ]] && echo "kind version is correct" || { echo "Unexpected kind version: $actual_kind_version" >&2; return 1 2>/dev/null || exit 1; }
[[ "$actual_k9s_version" == "$K9S_VERSION" ]] && echo "k9s version is correct" || { echo "Unexpected k9s version: $actual_k9s_version" >&2; return 1 2>/dev/null || exit 1; }
grep -n logoless "$K9S_CONFIG_DIR/config.yaml"               # true; k9s reads this on start, no splash either
grep -n "skin: transparent" "$K9S_CONFIG_DIR/config.yaml"
ls "$K9S_CONFIG_DIR/skins/transparent.yaml"                  # must exist or the skin setting has nothing to load
```

Expected: kubectl `v1.37.0`, kind `v0.33.0`, helm `v3.22.0`, k9s `v0.51.0`. `k` is `kubectl`. Tab-complete works on `kubectl`, `k`, `kind`, `helm`, and `k9s`.

`skin: transparent` turns off k9s's own background color so every panel shows your terminal's own background. Confirm it visually: run `k9s`, look at the body/table panels, `Ctrl-c` out. This exact mechanism has regressed upstream before ([derailed/k9s#821](https://github.com/derailed/k9s/issues/821), broken again as late as v0.31.5) — if panels still show a solid background at `v0.51.0`, that's a k9s-side regression to report upstream, not a sign this config is wrong.

## Next

- [02-create-cluster.md](02-create-cluster.md)
