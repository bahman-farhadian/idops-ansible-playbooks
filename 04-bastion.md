# 04. Bastion

**Goal:** On `k8s-bastion` only, install a **single-node Docker Engine** and run **three separate Compose projects** — one directory and one `compose.yaml` each:

## Teaching note

Keep Docker off the Kubernetes nodes. kubelet and Docker both want to own cgroups and iptables. This VM is admin only: jump, cache, metrics UI. Three Compose projects mean you can restart Grafana without touching Nexus. There is one bastion, so this is not HA. kubectl and k9s come later, after the API exists.

| App        | Directory         | Host ports                             |
| ---------- | ----------------- | -------------------------------------- |
| Nexus      | `/opt/nexus`      | 8081 (UI/apt), 8082 (docker connector) |
| Prometheus | `/opt/prometheus` | 9090                                   |
| Grafana    | `/opt/grafana`    | 3000                                   |

Do **not** put all three in one Compose file. Upgrade and restart stay independent.

kubelet/containerd/Ceph/keepalived/HAProxy stay **systemd** on their own VMs. HAProxy is the API pair (`k8s-lb-1` / `k8s-lb-2`), not this VM. Do not install Docker on control-plane or worker nodes.

The first `docker compose pull` for these three images still hits the internet (via the firewall pair). After Nexus is up, apt and **cluster** image pulls go through the cache.

`kubectl`, k9s, and Helm are not installed in this file. The API does not exist yet. [05-deploy-kubernetes.md](05-deploy-kubernetes.md) installs `kubectl` and k9s here, writes `~/.kube/config`, and points it at `https://10.0.1.10:6443`. k9s reads that same file. Its own config sets `logoless: true`, so the top bar does not show the k9s name. This VM is on the cluster LAN, so that connection does not use the VPN. `kubectl` and k9s on any other host reach the same address only through the site VPN, which enters at the firewall pair. The VPN server is outside this repo.

**Applies to:** `k8s-bastion` only.

## Why Docker here and systemd on the cluster

Docker Engine on this VM is the host daemon for lab-support processes. It is not Kubernetes' container runtime. Mixing Docker with kubelet on the same node is out of scope.

## Steps — Docker Engine

**1. Install a pinned Docker Engine** from Docker's apt repo. `docker-ce` is not in Debian or Ubuntu's own repos — `apt-cache madison docker-ce` is empty until this repo exists. Docker documents Debian 13 (Trixie) and Ubuntu Resolute 26.04; the suite comes from `/etc/os-release` so the same block covers both ([Debian](https://docs.docker.com/engine/install/debian/), [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)).

```sh
sudo apt update
sudo apt install -y ca-certificates curl          # Docker's repo is fetched over HTTPS
sudo install -m 0755 -d /etc/apt/keyrings         # keyring directory, mode 0755
. /etc/os-release
case "$ID" in
  debian)
    DOCKER_URL=https://download.docker.com/linux/debian
    DOCKER_SUITE=$VERSION_CODENAME
    ;;
  ubuntu)
    DOCKER_URL=https://download.docker.com/linux/ubuntu
    DOCKER_SUITE=${UBUNTU_CODENAME:-$VERSION_CODENAME}
    ;;
  *) echo "unsupported ID=$ID" >&2; exit 1 ;;
esac
sudo curl -fsSL "$DOCKER_URL/gpg" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
cat /etc/apt/sources.list.d/docker.sources 2>/dev/null || true        # read before replace
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: ${DOCKER_URL}
Suites: ${DOCKER_SUITE}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
cat /etc/apt/sources.list.d/docker.sources                            # apt reads this file
sudo apt update
apt-cache madison docker-ce docker-ce-cli containerd.io docker-compose-plugin
DOCKER_CE_VERSION="<version from madison>"          # docker-ce and docker-ce-cli share this string
CONTAINERD_IO_VERSION="<containerd.io from madison>"
COMPOSE_PLUGIN_VERSION="<docker-compose-plugin from madison>"
sudo apt install -y docker-ce=${DOCKER_CE_VERSION} docker-ce-cli=${DOCKER_CE_VERSION} \
  containerd.io=${CONTAINERD_IO_VERSION} docker-compose-plugin=${COMPOSE_PLUGIN_VERSION}
sudo apt-mark hold docker-ce docker-ce-cli containerd.io docker-compose-plugin   # freeze the pin
sudo systemctl enable --now docker                                                # start the engine
sudo docker info                                                                   # daemon answers
sudo mkdir -p /opt/nexus /opt/prometheus /opt/grafana                              # one directory per compose project
```

`containerd.io` here is Docker's runtime on the **bastion only**. Cluster nodes use distro `containerd` from [05-deploy-kubernetes.md](05-deploy-kubernetes.md).

Pin image tags (confirm on Docker Hub; examples below were current-ish in 2026-09).

## Steps — `/opt/nexus/compose.yaml`

Read any file already there, write this one, then `compose up` loads it. `restart: unless-stopped` is what brings Nexus back after a reboot.
```sh
ls -l /opt/nexus/compose.yaml 2>/dev/null || true
sudo tee /opt/nexus/compose.yaml <<'EOF'
services:
  nexus:
    image: sonatype/nexus3:3.96.3
    restart: unless-stopped
    ports:
      - "8081:8081"
      - "8082:8082"
    volumes:
      - nexus-data:/nexus-data
    ulimits:
      nofile: 65536

volumes:
  nexus-data:
EOF
cd /opt/nexus && sudo docker compose up -d
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8081
```

First start can take a minute. Change the admin password in the UI (`http://k8s-bastion:8081`). **Do not commit it.**

## Steps — `/opt/prometheus`

`/opt/prometheus/prometheus.yml` scrapes every node in the [02-prepare.md](02-prepare.md) hosts file (example LAN). External etcd: drop `.14`, add `.15` `.16` `.17`. GPU: add `.24`. Ceph VMs `.25` `.26` `.27` are already in the list. Targets stay `DOWN` until [08-observability.md](08-observability.md) installs `node_exporter`. Write both files, then `compose up` loads them.
```sh
ls -l /opt/prometheus/prometheus.yml /opt/prometheus/compose.yaml 2>/dev/null || true
sudo tee /opt/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: node
    static_configs:
      - targets:
          - 10.0.1.1:9100
          - 10.0.1.2:9100
          - 10.0.1.8:9100
          - 10.0.1.9:9100
          - 10.0.1.11:9100
          - 10.0.1.12:9100
          - 10.0.1.13:9100
          - 10.0.1.14:9100
          - 10.0.1.21:9100
          - 10.0.1.22:9100
          - 10.0.1.23:9100
          - 10.0.1.25:9100
          - 10.0.1.26:9100
          - 10.0.1.27:9100
EOF
sudo tee /opt/prometheus/compose.yaml <<'EOF'
services:
  prometheus:
    image: prom/prometheus:v2.55.1
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus

volumes:
  prometheus-data:
EOF
cd /opt/prometheus && sudo docker compose up -d
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:9090/-/ready
```

## Steps — `/opt/grafana/compose.yaml`

Grafana cannot use Compose DNS `prometheus` because it is a different project. Reach Prometheus on the host. The admin password stays in a local env file, not in this repo.
```sh
ls -l /opt/grafana/compose.yaml 2>/dev/null || true
sudo tee /opt/grafana/compose.yaml <<'EOF'
services:
  grafana:
    image: grafana/grafana:11.5.2
    restart: unless-stopped
    ports:
      - "3000:3000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - grafana-data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_USER: admin
      # GF_SECURITY_ADMIN_PASSWORD from a local env file — do not commit it

volumes:
  grafana-data:
EOF
cd /opt/grafana && sudo docker compose up -d
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3000
```

Datasource URL from inside Grafana: `http://host.docker.internal:9090`. From a browser on the LAN: `http://k8s-bastion:3000`.

## Steps — Nexus proxy repositories

Create apt proxies for the distro of *this* cluster only, plus docker proxies. Enable a LAN HTTP docker connector on **8082**.

| Name (example)                       | Format | Remote URL                                     |
| ------------------------------------ | ------ | ---------------------------------------------- |
| `apt-debian` / `apt-debian-security` | apt    | Debian mirrors (Debian 13 instance only)       |
| `apt-ubuntu`                         | apt    | Ubuntu archive (Ubuntu 26 instance only)       |
| `apt-kubernetes`                     | apt    | `https://pkgs.k8s.io/core:/stable:/v1.36/deb/` (same minor as [05](05-deploy-kubernetes.md)) |
| `apt-ceph`                           | apt    | `https://download.ceph.com/debian-umbrella/` (Debian 13) |
| `docker-dockerio`                    | docker | `https://registry-1.docker.io`                 |
| `docker-k8s`                         | docker | `https://registry.k8s.io`                      |
| `docker-quay`                        | docker | `https://quay.io`                              |

## Steps — point the cluster at Nexus

Not a command in this pass. The repository table above is the list to create in the Nexus UI. When a node is switched over, it is still a file change: read the current apt list or containerd config, write the file that tool reads, then `apt update` or `systemctl restart containerd`. Keep the upstream `signed-by` keyrings. Do not `export` a mirror or edit a running daemon only in memory.

Apt URI host, once a proxy exists: `http://k8s-bastion:8081/repository/<name>/`. containerd has no `hosts.toml` in this manual yet. [05-deploy-kubernetes.md](05-deploy-kubernetes.md) does not install one.

## Prerequisites
- [03-firewall.md](03-firewall.md)

## Next
- [05-deploy-kubernetes.md](05-deploy-kubernetes.md)
