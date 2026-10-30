# 03. Smoke test and teardown

**Goal:** One checklist for this lab, plus how to clean up.

## Steps — health

```sh
cd at-centralized-logging/idops-elk-lab
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty   # "status": "green" or "yellow", node count 1; credentials from .env
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cat/indices?v           # elk-lab-logs-*, with doc counts
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5601/api/status   # 200 — this endpoint doesn't need login
```

## Troubleshooting

- **Elasticsearch exits right after start, log mentions `max virtual memory areas vm.max_map_count`:** [01-install-tools.md](01-install-tools.md) step 2 wasn't applied, or didn't survive a reboot. Re-run `sysctl vm.max_map_count` and fix it before retrying.
- **Elasticsearch container exits with code 137:** OOM-killed. `mem_limit: 1g` in [compose.yaml](compose.yaml) is tight for a cold start on a busy host — raise it and `ES_JAVA_OPTS` together, then `docker compose up -d` again.
- **Kibana shows "Kibana server is not ready yet":** normal for the first 30–60s after Elasticsearch turns healthy. Re-check `curl .../api/status`; it moves from a non-200 to 200 once Kibana finishes its own startup migrations.
- **Kibana's web UI never loads, container keeps restarting, `docker compose logs kibana` shows `FATAL ERROR: ... JavaScript heap out of memory`:** Kibana 9.x loads 200+ plugins on startup and needs more heap than `mem_limit: 768m` allows — confirmed by the exact crash in this lab's logs on a first run. [compose.yaml](compose.yaml) now sets `mem_limit: 1536m` and `NODE_OPTIONS=--max-old-space-size=1280`; if your host is tighter on RAM than that, this is the one value in this lab you cannot shrink back down without the same crash.
- **Logstash exits right after `up -d`, log says `Your settings are invalid. Reason: Setting "http.host" doesn't exist`:** `logstash/config/logstash.yml` used the old `http.host` key; Logstash 8+/9.x renamed it to `api.http.host` and treats the old name as a hard startup error, not a warning. Already fixed in this lab's `logstash.yml` — if you hit this on a config you edited yourself, that's the key to check first.
- **No document shows up after sending a demo line:** check `docker compose logs logstash` first — a bad pipeline/filter config fails there, visibly, not silently. A `401`/`403` in that log means it's not reaching Elasticsearch as `log_writer` — see the next item.
- **Logstash logs a `401`/`403` writing to Elasticsearch, or Kibana logs `unable to authenticate user [kibana_system]`:** `es-security-setup` either hasn't finished or its passwords don't match `.env` anymore. `docker compose ps` should show it `exited (0)`; if it's missing or failed, `docker compose up es-security-setup` re-runs it (it's idempotent — see [00-overview.md](00-overview.md)). If you changed `ELASTIC_PASSWORD`/`KIBANA_SYSTEM_PASSWORD`/`LOG_WRITER_PASSWORD` in `.env` after the first boot, re-run it to push the new values into Elasticsearch.
- **Kibana shows "Insufficient Permissions" on some feature (e.g. Observability SLOs) while logged in as `idops` or `elastic`:** both are superusers and shouldn't hit this. If you do, confirm `XPACK_SECURITY_ENABLED=true` actually took (`docker compose logs kibana | grep -i "xpack.security"`) and that you're actually logged in as one of them, not a role you created yourself without the needed index privileges.

## Steps — teardown

Keep the data, stop the containers:
```sh
docker compose down
```

Remove everything, including the `es-data` volume (`elk-lab-logs-*` goes with it):
```sh
docker compose down -v
```

## Prerequisites
- [02-run.md](02-run.md)

## Next
- [04-post-start-checklist.md](04-post-start-checklist.md) if you haven't walked it yet, or back to [README.md](README.md), or [../README.md](../README.md) for the production `elk/` decision this lab is modeled on
