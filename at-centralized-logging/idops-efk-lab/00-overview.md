# 00. Overview

**Goal:** Know what this lab is, what it deliberately leaves out, and which versions it pins.

## Teaching note

The domain decision in [`../README.md`](../README.md) is precise about shape: one logging Elasticsearch (one guest, a cluster, or a sharded cluster), one Kibana, and a collector — Logstash for `elk/`, Fluent Bit for `efk/` — that runs on the `rsyslog/` central receiver, not on its own guest. A project picks `elk/` or `efk/`, never both; this lab and [`../idops-elk-lab/`](../idops-elk-lab/00-overview.md) mirror that split as two separate directories.

This lab keeps the `efk/` shape but drops everything that only matters at production scale: no second guest, no HAProxy pair, no real rsyslog receiver forwarding real host logs. Instead, a single Elasticsearch container, a single Kibana container, and Fluent Bit listening on one TCP port, fed by a line you type yourself with `logger` or `nc`. Same contract — a raw log line goes in, a document comes out the other side in Elasticsearch — small enough to run on a laptop and reset in seconds.

## What this lab is not

- Not the `efk/` Ansible playbook. No files here touch a `*.local.yml`, an inventory, or a remote host. `make check-local` at the repo root has nothing to find in this directory.
- Not a from-source AGPL-3.0 build. The playbook builds Elasticsearch and Kibana from a pinned 9.x source release specifically to land on that license; this lab pulls the official `docker.elastic.co`/`fluent` images instead, which is the normal way to run Elastic's stack locally. If that distinction matters for your use, read `../README.md` before treating anything here as a production reference.
- Not HA. `discovery.type: single-node`. One Elasticsearch, one Kibana, one Fluent Bit.

## Follow order

| Doc | Covers |
| --- | --- |
| [00-overview.md](00-overview.md) | This file |
| [01-install-tools.md](01-install-tools.md) | Host prerequisites: Docker Engine, Compose plugin, `vm.max_map_count` |
| [02-run.md](02-run.md) | `compose.yaml`: Elasticsearch, Kibana, Fluent Bit |
| [03-smoke-test.md](03-smoke-test.md) | Health checks, teardown |
| [04-post-start-checklist.md](04-post-start-checklist.md) | What to check right after `up`, which log lines are noise vs. a real bug |

## Pinned version matrix

Pins checked against upstream on **2026-10-21**. Re-check before you run: [Elastic release notes](https://www.elastic.co/guide/en/welcome-to-elastic/current/new.html), [Elasticsearch Docker Hub tags](https://hub.docker.com/_/elasticsearch/tags), [Fluent Bit announcements](https://fluentbit.io/announcements/).

| Component | Version | Where it is set |
| --- | --- | --- |
| Elasticsearch | 9.5.2 | `ELASTIC_VERSION` in [`.env.example`](.env.example) (copy to `.env`) |
| Kibana | 9.5.2 | same `ELASTIC_VERSION`, [`compose.yaml`](compose.yaml) |
| Fluent Bit | 5.0.8 | `FLUENT_BIT_VERSION` in [`.env.example`](.env.example) (copy to `.env`), [`compose.yaml`](compose.yaml) |

No command in this lab uses `latest` or an unpinned tag.

## Why single-node, X-Pack security on (but ML/CCR off)

- `discovery.type: single-node` skips Elasticsearch's master-election and shard-replica machinery entirely. The domain's cluster and sharded-cluster layouts are about surviving a guest failure; a single Docker container has no such guarantee to teach here.
- `xpack.security.enabled: true` on Elasticsearch, `XPACK_SECURITY_ENABLED=true` on Kibana: a **lab-only** divergence from the domain decision in `../README.md`, which keeps X-Pack out permanently and plans Kibana login through Keycloak. This lab turns security on anyway because features like Observability SLOs enforce real role-based privileges and fail confusingly ("Insufficient Permissions") without it — see the "Login" section in [README.md](README.md). `xpack.ml.enabled: false` stays off regardless; ML/cross-cluster replication were never the point of flipping security on.
- Elasticsearch's own settings (`node.name`, `discovery.type`, both `xpack.*` toggles) live in a mounted, git-tracked [`elasticsearch/config/elasticsearch.yml`](elasticsearch/config/elasticsearch.yml) — not as Docker `environment:` entries in [compose.yaml](compose.yaml). Only two things stay as env vars there: `ELASTIC_PASSWORD` (a bootstrap-only variable the entrypoint consumes directly — there's no matching `elasticsearch.yml` key) and `ES_JAVA_OPTS` (a JVM heap flag, not an Elasticsearch config setting at all). Don't set the same setting in both places — the entrypoint only auto-writes an env var into the file when the file doesn't already define that key.
- Four built-in/created users do the work: `elastic` (the bootstrap superuser — kept as a break-glass fallback, not for daily login), `idops` (a named superuser, created the same way, for you to actually log into Kibana as), `kibana_system` (Kibana's own service account, never for human login), and `log_writer` (a role scoped to `create_index`/`write`/`manage` on just this lab's index, plus the cluster-level `monitor` and `manage_index_templates` privileges Fluent Bit's own health check and startup template install need). A one-shot `es-security-setup` service in [compose.yaml](compose.yaml) sets all of these passwords and creates the `log_writer` role once Elasticsearch is healthy, before Kibana or Fluent Bit starts. It exits 0 and stays around as `Exited (0)` until removed — [02-run.md](02-run.md) `rm -f`s it right after `up` so it doesn't linger in `docker compose ps -a`.

## Next

- [01-install-tools.md](01-install-tools.md)
