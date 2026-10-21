# 04. Smoke test and teardown

**Goal:** One checklist that works whichever overlay (ELK or EFK) is currently up, plus how to clean up.

## Steps — health, whichever overlay is running

```sh
cd at-centralized-logging/elk-efk-lab
curl -s http://localhost:9200/_cluster/health?pretty           # "status": "green" or "yellow", node count 1
curl -s http://localhost:9200/_cat/indices?v                   # elk-lab-logs-* and/or efk-lab-logs, with doc counts
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5601/api/status   # 200
```

## Steps — compare the two pipelines

If you've walked both [02-run-elk.md](02-run-elk.md) and [03-run-efk.md](03-run-efk.md) (one at a time, since both claim port 5514), the indices from each run survive in the same `es-data` volume until you remove it:
```sh
curl -s "http://localhost:9200/elk-lab-logs-*/_count?pretty"
curl -s "http://localhost:9200/efk-lab-logs/_count?pretty"
```
Same source line, two different collectors, two index names — Elasticsearch and Kibana don't care which one wrote a document.

## Troubleshooting

- **Elasticsearch exits right after start, log mentions `max virtual memory areas vm.max_map_count`:** [01-install-tools.md](01-install-tools.md) step 2 wasn't applied, or didn't survive a reboot. Re-run `sysctl vm.max_map_count` and fix it before retrying.
- **Elasticsearch container exits with code 137:** OOM-killed. `mem_limit: 1g` in [compose.yaml](compose.yaml) is tight for a cold start on a busy host — raise it and `ES_JAVA_OPTS` together, then `docker compose up -d` again.
- **Kibana shows "Kibana server is not ready yet":** normal for the first 30–60s after Elasticsearch turns healthy. Re-check `curl .../api/status`; it moves from a non-200 to 200 once Kibana finishes its own startup migrations.
- **No document shows up after sending a demo line:** check `docker compose ... logs logstash` or `... logs fluent-bit` first — a bad pipeline/filter config fails there, visibly, not silently. Then confirm you're hitting the port that overlay is actually listening on (only one overlay can hold 5514 at a time).

## Steps — teardown

Keep the data, stop the containers:
```sh
docker compose -f compose.yaml -f compose.elk.yaml down 2>/dev/null || true
docker compose -f compose.yaml -f compose.efk.yaml down 2>/dev/null || true
```

Remove everything, including the `es-data` volume (both `elk-lab-logs-*` and `efk-lab-logs` go with it):
```sh
docker compose -f compose.yaml -f compose.elk.yaml down -v 2>/dev/null || true
docker compose -f compose.yaml -f compose.efk.yaml down -v 2>/dev/null || true
```

## Prerequisites
- [02-run-elk.md](02-run-elk.md) or [03-run-efk.md](03-run-efk.md)

## Next
- Back to [README.md](README.md), or [../README.md](../README.md) for the production `elk/`/`efk/` decision this lab is modeled on
