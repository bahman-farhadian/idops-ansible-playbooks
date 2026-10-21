# 01. Install tools

**Goal:** A Docker host that can run this lab, with the one kernel setting Elasticsearch insists on.

## Teaching note

Elasticsearch memory-maps a lot of files and refuses to start below a kernel limit on how many memory-map areas one process may own. This is not a container limit Docker can raise for you — it is a host (or, on Linux, host-namespace-shared) sysctl, so it is set once, outside Compose, before the first `up`.

## Prerequisites
- A Linux host (or a Linux VM — Docker Desktop on macOS/Windows sets this value inside its own VM automatically) with Docker Engine and the Compose plugin. If this is the same workstation as [idops-pocket-cluster](../../ak-container-orchestration/kubernetes-lab/idops-pocket-cluster/00-overview.md), you already have both.

## Steps

**1. Confirm Docker Engine and the Compose plugin.**
```sh
docker info >/dev/null && echo "Docker Engine OK"
docker compose version                 # must be the v2 plugin, not standalone docker-compose
```

**2. Set `vm.max_map_count` and make it survive a reboot.**
```sh
sysctl vm.max_map_count                                    # current value; Elasticsearch needs >= 262144
sudo tee /etc/sysctl.d/99-elk-efk-lab.conf <<'EOF'
vm.max_map_count=262144
EOF
sudo sysctl --system                                        # applies every file under /etc/sysctl.d
sysctl vm.max_map_count                                     # confirm it took
```

**3. Clone or `cd` into this directory, then confirm the pinned versions.**
```sh
cd at-centralized-logging/elk-efk-lab
cat .env                                                     # ELASTIC_VERSION and FLUENT_BIT_VERSION
docker compose config >/dev/null && echo "compose.yaml is valid"
```

`docker compose` reads `.env` in this directory automatically — no `--env-file` flag needed as long as you run every command from here.

## Prerequisites
- [00-overview.md](00-overview.md)

## Next
- [02-run-elk.md](02-run-elk.md), or [03-run-efk.md](03-run-efk.md) first if you want to start with Fluent Bit
