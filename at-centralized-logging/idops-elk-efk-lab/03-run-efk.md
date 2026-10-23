# 03. Run EFK

**Goal:** Same demo, Fluent Bit instead of Logstash — same Elasticsearch, same Kibana, a different index name so the two are easy to tell apart.

## Teaching note

Fluent Bit's `[FILTER] parser` stanza in [`fluent-bit/fluent-bit.conf`](fluent-bit/fluent-bit.conf) does the same job as Logstash's `grok`: turn a raw line into fields, using the `syslog-rfc3164` parser that ships built into the Fluent Bit image's own `parsers.conf`. The output index is `efk-lab-logs` (no date suffix, unlike Logstash's `elk-lab-logs-%{+YYYY.MM.dd}`) — intentionally different from [02-run-elk.md](02-run-elk.md) so a search in Kibana makes obvious which pipeline wrote which document.

**Applies to:** this directory, with [compose.yaml](compose.yaml) and [compose.efk.yaml](compose.efk.yaml) together.

## Steps — make sure ELK's overlay is down

Both overlays bind host port 5514.
```sh
docker compose -f compose.yaml -f compose.elk.yaml down 2>/dev/null || true
```

## Steps — bring the EFK overlay up

```sh
cd at-centralized-logging/idops-elk-efk-lab
docker compose -f compose.yaml -f compose.efk.yaml up -d --wait
docker compose -f compose.yaml -f compose.efk.yaml ps
```

## Steps — confirm each piece answers

```sh
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty   # credentials from .env
curl -s http://localhost:2020/                                 # Fluent Bit's own HTTP status endpoint
docker compose -f compose.yaml -f compose.efk.yaml logs fluent-bit --tail=20
```

## Steps — send a demo log line

Same port, same tools as [02-run-elk.md](02-run-elk.md) — Fluent Bit's `[INPUT] tcp` stanza listens on the same 5514:
```sh
logger -n 127.0.0.1 -P 5514 -T "demo-app[1234]: order 43 shipped"
# or: printf '<14>%s demo-app[1234]: order 43 shipped\n' "$(date '+%b %e %H:%M:%S')" | nc -q1 127.0.0.1 5514
```

## Steps — see it land

```sh
sleep 2
curl -s -u elastic:${ELASTIC_PASSWORD} "http://localhost:9200/efk-lab-logs/_search?q=order&pretty"
```

A hit means Fluent Bit's `es` output plugin wrote it through. If nothing shows up, check `docker compose ... logs fluent-bit` first — a bad `[OUTPUT]` block fails loudly there, not silently. A `401`/`403` in that log means `LOG_WRITER_PASSWORD` doesn't match between `.env` and what `es-security-setup` set — see [00-overview.md](00-overview.md).

**In Kibana** (`http://localhost:5601`): log in as `idops` / `$IDOPS_PASSWORD` from your `.env` (see [README.md](README.md#login)) if you haven't already. Create a second data view on `efk-lab-logs`, open Discover, pick it, and compare the parsed fields against the `elk-lab-logs-*` ones from [02-run-elk.md](02-run-elk.md).

## Prerequisites
- [01-install-tools.md](01-install-tools.md)

## Next
- [04-smoke-test.md](04-smoke-test.md)
