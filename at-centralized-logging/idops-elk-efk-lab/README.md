# idops-elk-efk-lab

A Docker Compose lab for the log-pipeline shape decided in [`../README.md`](../README.md) (the `at-centralized-logging` domain): one Elasticsearch, one Kibana, and a collector that is either Logstash (ELK) or Fluent Bit (EFK), never both at once.

## Teaching note

This is a lab, not the `elk/` or `efk/` Ansible playbook. Those stay decision-only in the domain catalog until someone builds them for real guests. This directory exists to learn how Elasticsearch, Kibana, Logstash, and Fluent Bit actually fit together — mappings, indices, parsers, the Kibana Discover flow — on a single Docker host, in minutes, before any of that is worth automating. It is also a safe place to break things: delete a volume, change a parser, watch what happens.

Same relationship as [`../../ak-container-orchestration/kubernetes-lab/idops-pocket-cluster/`](../../ak-container-orchestration/kubernetes-lab/idops-pocket-cluster/00-overview.md) is to the production kubeadm spine: a small, fast, independent stand-in for practice, not a shortcut that skips the real build.

## Scope

- One Elasticsearch node, one Kibana. Single-node, not the domain's cluster or sharded-cluster layout — this lab is about the pipeline shape, not HA.
- Official `docker.elastic.co` images, pulled as prebuilt binaries. The domain's own `elk/`/`efk/` playbook instead builds Elasticsearch and Kibana from a pinned 9.x source release to land on AGPL-3.0 specifically — see `../README.md`. This lab does not reproduce that build step.
- X-Pack stays off (`xpack.security.enabled: false`), matching the domain decision: no built-in login.
- ELK adds Logstash; EFK adds Fluent Bit. Only one is ever running — bring the other overlay down first.
- Docker Compose only. No Ansible, no systemd units, no `*.local.yml`.

## Layout

| Doc | Covers |
| --- | --- |
| [00-overview.md](00-overview.md) | What this lab is and isn't, version pins, doc index |
| [01-install-tools.md](01-install-tools.md) | Docker Engine/Compose check, `vm.max_map_count`, directory |
| [02-run-elk.md](02-run-elk.md) | Bring up Elasticsearch + Kibana + Logstash, feed a demo log, see it in Kibana |
| [03-run-efk.md](03-run-efk.md) | Swap Logstash for Fluent Bit, same demo | 
| [04-smoke-test.md](04-smoke-test.md) | Health checks, comparing the two paths, teardown |

Walk 00 → 04. [02](02-run-elk.md) and [03](03-run-efk.md) are independent once you've read [00](00-overview.md) and [01](01-install-tools.md) — do either first, or both in turn to compare them, which is the point of the lab.

## Next

- [00-overview.md](00-overview.md)
