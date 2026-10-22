# 00. Overview

**Goal:** Know what this lab is, what it deliberately leaves out, and which versions it pins.

## Teaching note

The domain decision in [`../README.md`](../README.md) is precise about shape: one logging Elasticsearch (one guest, a cluster, or a sharded cluster), one Kibana, and a collector — Logstash for `elk/`, Fluent Bit for `efk/` — that runs on the `rsyslog/` central receiver, not on its own guest. A project picks `elk/` or `efk/`, never both.

This lab keeps that shape but drops everything that only matters at production scale: no second guest, no HAProxy pair, no real rsyslog receiver forwarding real host logs. Instead, a single Elasticsearch container, a single Kibana container, and either Logstash or Fluent Bit listening on one TCP/UDP port, fed by a line you type yourself with `logger` or `nc`. Same contract — a raw log line goes in, a document comes out the other side in Elasticsearch — small enough to run on a laptop and reset in seconds.

## What this lab is not

- Not the `elk/`/`efk/` Ansible playbook. No files here touch a `*.local.yml`, an inventory, or a remote host. `make check-local` at the repo root has nothing to find in this directory.
- Not a from-source AGPL-3.0 build. The playbook builds Elasticsearch and Kibana from a pinned 9.x source release specifically to land on that license; this lab pulls the official `docker.elastic.co` images instead, which is the normal way to run Elastic's stack locally. If that distinction matters for your use, read `../README.md` before treating anything here as a production reference.
- Not HA. `discovery.type: single-node`. One Elasticsearch, one Kibana, one collector.

## Follow order

| Doc | Covers |
| --- | --- |
| [00-overview.md](00-overview.md) | This file |
| [01-install-tools.md](01-install-tools.md) | Host prerequisites: Docker Engine, Compose plugin, `vm.max_map_count` |
| [02-run-elk.md](02-run-elk.md) | `compose.yaml` + `compose.elk.yaml`: Elasticsearch, Kibana, Logstash |
| [03-run-efk.md](03-run-efk.md) | `compose.yaml` + `compose.efk.yaml`: Elasticsearch, Kibana, Fluent Bit |
| [04-smoke-test.md](04-smoke-test.md) | Health checks, comparing the two indices, teardown |

## Pinned version matrix

Pins checked against upstream on **2026-10-21**. Re-check before you run: [Elastic release notes](https://www.elastic.co/guide/en/welcome-to-elastic/current/new.html), [Elasticsearch Docker Hub tags](https://hub.docker.com/_/elasticsearch/tags), [Fluent Bit announcements](https://fluentbit.io/announcements/).

| Component | Version | Where it is set |
| --- | --- | --- |
| Elasticsearch | 9.5.2 | `ELASTIC_VERSION` in [`.env.example`](.env.example) (copy to `.env`) |
| Kibana | 9.5.2 | same `ELASTIC_VERSION`, [`compose.yaml`](compose.yaml) |
| Logstash | 9.5.2 | same `ELASTIC_VERSION`, [`compose.elk.yaml`](compose.elk.yaml) |
| Fluent Bit | 5.0.8 | `FLUENT_BIT_VERSION` in [`.env.example`](.env.example) (copy to `.env`), [`compose.efk.yaml`](compose.efk.yaml) |

Kibana and Logstash always track the same `ELASTIC_VERSION` as Elasticsearch — Elastic does not support mixing minors across that trio. No command in this lab uses `latest` or an unpinned tag.

## Why single-node, X-Pack off

- `discovery.type=single-node` skips Elasticsearch's master-election and shard-replica machinery entirely. The domain's cluster and sharded-cluster layouts are about surviving a guest failure; a single Docker container has no such guarantee to teach here.
- `xpack.security.enabled=false` on Elasticsearch, `XPACK_SECURITY_ENABLED=false` on Kibana: matches the domain decision that X-Pack (built-in login, ML, cross-cluster replication) stays out. Kibana opens with no sign-in screen.

## Next

- [01-install-tools.md](01-install-tools.md)
