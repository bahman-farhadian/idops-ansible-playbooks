# 05. Post-start checklist

**Goal:** What to check once `docker compose up -d` returns, and which log lines are noise vs. a real problem.

## Checks

```sh
docker compose ps                                              # all services "running" or "healthy", none "restarting"
curl -s http://localhost:9200/_cluster/health?pretty | grep status
curl -s http://localhost:5601/api/status | grep -o '"level":"[a-z]*"'   # must be "available"
docker compose logs kibana --since 2m | grep -c ERROR           # expect 0 — see below if it isn't
```

## Known harmless warnings (log once at boot, then stop)

Kibana logs these the first time it ever boots without a fixed key; they do not repeat and do not affect this lab:
- `Generating a random key for xpack.security.encryptionKey` — irrelevant, `XPACK_SECURITY_ENABLED=false` means no sessions exist to invalidate.
- `Generating a random key for xpack.reporting.encryptionKey` — irrelevant, this lab never generates a report.

## The one that is not harmless

`[ERROR][plugins.monitoring.monitoring] Unable to create alerts client because the Encrypted Saved Objects plugin is missing encryption key` repeating every ~80ms (confirmed: 1,100+ lines per 5s window) is Kibana's monitoring plugin retrying forever, not a one-time warning. Cause: `xpack.encryptedSavedObjects.encryptionKey` unset. Fix already in [compose.yaml](compose.yaml) via `KIBANA_ENCRYPTION_KEY`:

```sh
openssl rand -hex 32                     # run once, paste the output into .env
# .env: KIBANA_ENCRYPTION_KEY=<paste>
docker compose -f compose.yaml -f compose.elk.yaml up -d kibana   # recreate so the new env var takes effect
```
`restart` is not enough — Compose only re-reads `.env` substitutions when it (re)creates the container.

## Prerequisites
- [02-run-elk.md](02-run-elk.md) or [03-run-efk.md](03-run-efk.md)

## Next
- [04-smoke-test.md](04-smoke-test.md), or back to [README.md](README.md)
