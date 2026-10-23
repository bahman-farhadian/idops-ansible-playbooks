# 05. Post-start checklist

**Goal:** What to check once `docker compose up -d` returns, and which log lines are noise vs. a real problem.

## Checks

```sh
docker compose ps                                              # all services "running" or "healthy", none "restarting"; es-security-setup shows "exited (0)", not "restarting"
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty | grep status
curl -s http://localhost:5601/api/status | grep -o '"level":"[a-z]*"'   # must be "available" — this endpoint doesn't require login
docker compose logs kibana --since 2m | grep -c ERROR           # expect 0 — see below if it isn't
```

## Known harmless warning (logs once at boot, then stops)

- `Generating a random key for xpack.reporting.encryptionKey` — irrelevant, this lab never generates a report.

`Generating a random key for xpack.security.encryptionKey` is **not** on this list anymore: with `XPACK_SECURITY_ENABLED=true`, real sessions exist, and a random key invalidates every one of them on each restart. [compose.yaml](compose.yaml) pins this via `KIBANA_SECURITY_ENCRYPTION_KEY` — if you see this warning, that env var is unset or empty in your `.env`.

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
