# idops-elk-lab

A Docker Compose lab for the ELK pipeline shape decided in [`../README.md`](../README.md) (the `at-centralized-logging` domain): one Elasticsearch, one Kibana, one Logstash collector.

## Teaching note

This is a lab, not the `elk/` Ansible playbook. That stays decision-only in the domain catalog until someone builds it for real guests. This directory exists to learn how Elasticsearch, Kibana, and Logstash actually fit together — mappings, indices, the `grok` filter, the Kibana Discover flow — on a single Docker host, in minutes, before any of that is worth automating. It is also a safe place to break things: delete a volume, change a parser, watch what happens.

See [`../idops-efk-lab/`](../idops-efk-lab/00-overview.md) for the Fluent Bit equivalent — same Elasticsearch/Kibana shape, a different collector. The two are independent, self-contained labs (they used to be overlays of one shared stack); don't run both at once, they bind the same host ports.

Same relationship as [`../../ak-container-orchestration/idops-kubernetes-lab/idops-pocket-cluster/`](../../ak-container-orchestration/idops-kubernetes-lab/idops-pocket-cluster/00-overview.md) is to the production kubeadm spine: a small, fast, independent stand-in for practice, not a shortcut that skips the real build.

## Scope

- One Elasticsearch node, one Kibana, one Logstash. Single-node, not the domain's cluster or sharded-cluster layout — this lab is about the pipeline shape, not HA.
- Official `docker.elastic.co` images, pulled as prebuilt binaries. The domain's own `elk/` playbook instead builds Elasticsearch and Kibana from a pinned 9.x source release to land on AGPL-3.0 specifically — see `../README.md`. This lab does not reproduce that build step.
- Docker Compose only. No Ansible, no systemd units, no `*.local.yml`.

## Login

X-Pack security is **on** (`xpack.security.enabled: true`) — this is a deliberate lab-only divergence from `../README.md`'s domain decision, which keeps X-Pack out permanently and plans Kibana login through Keycloak instead. That decision still stands for the real `elk/` playbook. This lab turns X-Pack on anyway because some Kibana features (Observability SLOs, for one) gate themselves on real role-based privileges and show a confusing "Insufficient Permissions" error with security off — there's no meaningful RBAC to teach or debug without it.

Log into `http://localhost:5601` as `idops` / the `IDOPS_PASSWORD` value in your `.env` — a named superuser created for day-to-day login, so you're not driving the `elastic` bootstrap account directly. `elastic` / `ELASTIC_PASSWORD` still works and is the one to fall back on if `idops` ever gets locked out or its role gets mangled. See [`.env.example`](.env.example) for how every credential is generated, and [00-overview.md](00-overview.md) for how the pieces fit together.

## Layout

| Doc | Covers |
| --- | --- |
| [00-overview.md](00-overview.md) | What this lab is and isn't, version pins, doc index |
| [01-install-tools.md](01-install-tools.md) | Docker Engine/Compose check, `vm.max_map_count`, directory |
| [02-run.md](02-run.md) | Bring up Elasticsearch + Kibana + Logstash, feed a demo log, see it in Kibana |
| [03-smoke-test.md](03-smoke-test.md) | Health checks, teardown |
| [04-post-start-checklist.md](04-post-start-checklist.md) | Post-`up` checks, noise vs. real errors |

Walk 00 → 04.

## Next

- [00-overview.md](00-overview.md)
