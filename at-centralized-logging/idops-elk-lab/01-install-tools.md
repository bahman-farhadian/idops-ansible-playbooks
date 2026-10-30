# 01. Install tools

**Goal:** A Docker host that can run this lab, with the one kernel setting Elasticsearch insists on.

## Teaching note

Elasticsearch memory-maps a lot of files and refuses to start below a kernel limit on how many memory-map areas one process may own. This is not a container limit Docker can raise for you — it is a host (or, on Linux, host-namespace-shared) sysctl, so it is set once, outside Compose, before the first `up`.

## Prerequisites
- A Linux host (or a Linux VM — Docker Desktop on macOS/Windows sets this value inside its own VM automatically) with Docker Engine and the Compose plugin. If this is the same workstation as [idops-pocket-cluster](../../ak-container-orchestration/idops-kubernetes-lab/idops-pocket-cluster/00-overview.md), you already have both.

## Steps

**1. Confirm Docker Engine and the Compose plugin.**
```sh
docker info >/dev/null && echo "Docker Engine OK"
docker compose version                 # must be the v2 plugin, not standalone docker-compose
```

**2. Set `vm.max_map_count` and make it survive a reboot.**
```sh
sysctl vm.max_map_count                                    # current value; Elasticsearch needs >= 262144
sudo tee /etc/sysctl.d/99-idops-elk-lab.conf <<'EOF'
vm.max_map_count=262144
EOF
sudo sysctl --system                                        # applies every file under /etc/sysctl.d
sysctl vm.max_map_count                                     # confirm it took
```

**3. Clone or `cd` into this directory, then create your `.env` and confirm the pinned version.**
```sh
cd at-centralized-logging/idops-elk-lab
cp .env.example .env                                         # .env is gitignored; .env.example is the tracked template
cat .env                                                     # ELASTIC_VERSION
docker compose config >/dev/null && echo "compose.yaml is valid"
```

Five values in `.env` start blank and must be filled before the first `up` — Elasticsearch and Kibana won't start with an empty password, and Logstash will fail to write without one. [`.env.example`](.env.example) has the exact `openssl` command for each:
```sh
sed -i "s/^KIBANA_ENCRYPTION_KEY=$/KIBANA_ENCRYPTION_KEY=$(openssl rand -hex 32)/" .env
sed -i "s/^KIBANA_SECURITY_ENCRYPTION_KEY=$/KIBANA_SECURITY_ENCRYPTION_KEY=$(openssl rand -hex 32)/" .env
sed -i "s/^ELASTIC_PASSWORD=$/ELASTIC_PASSWORD=$(openssl rand -hex 18)/" .env
sed -i "s/^KIBANA_SYSTEM_PASSWORD=$/KIBANA_SYSTEM_PASSWORD=$(openssl rand -hex 18)/" .env
sed -i "s/^LOG_WRITER_PASSWORD=$/LOG_WRITER_PASSWORD=$(openssl rand -hex 18)/" .env
sed -i "s/^IDOPS_PASSWORD=$/IDOPS_PASSWORD=$(openssl rand -hex 18)/" .env
```

`docker compose` reads `.env` in this directory automatically — no `--env-file` flag needed as long as you run every command from here.

**That auto-read is Compose-only.** Every `curl -u elastic:${ELASTIC_PASSWORD}`-style command in these docs (02–04) uses a *shell* variable, which your interactive shell does not get from `.env` on its own — it has to be exported. Do this once per shell session, in this directory:
```sh
set -a; source .env; set +a
```
Skip this and `${ELASTIC_PASSWORD}` silently expands to empty, `curl` sends `elastic:` with no password, Elasticsearch replies `401`, and anything polling on `grep -q status` (like the `until` loop in [02-run.md](02-run.md)) spins forever instead of failing loudly — it looks like a stuck container when it's actually just a missing shell variable.

## Prerequisites
- [00-overview.md](00-overview.md)

## Next
- [02-run.md](02-run.md)
