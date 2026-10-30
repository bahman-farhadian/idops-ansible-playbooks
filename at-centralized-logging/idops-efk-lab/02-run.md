# 02. Run

**Goal:** Elasticsearch + Kibana + Fluent Bit up, one demo log line through Fluent Bit, visible in Kibana.

## Teaching note

Fluent Bit's `[FILTER] parser` stanza in [`fluent-bit/fluent-bit.conf`](fluent-bit/fluent-bit.conf) turns a raw line into fields, using the `syslog-rfc3164` parser that ships built into the Fluent Bit image's own `parsers.conf`. The output index is `efk-lab-logs` (no date suffix, unlike Logstash's `elk-lab-logs-%{+YYYY.MM.dd}` in the sibling [idops-elk-lab](../idops-elk-lab/00-overview.md)).

## Steps — bring the stack up

```sh
cd at-centralized-logging/idops-efk-lab
docker compose up -d --wait
docker compose ps
```

## Steps — drop the one-shot setup container

`es-security-setup` exits 0 once it's done and Compose leaves it sitting there as `Exited (0)` — harmless, but clutters `docker compose ps -a`. Remove it now that it's served its purpose:
```sh
docker compose rm -f es-security-setup
```

## Steps — confirm each piece answers

```sh
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty   # credentials from .env
curl -s http://localhost:2020/                                 # Fluent Bit's own HTTP status endpoint
docker compose logs fluent-bit --tail=20
```

## Steps — send a demo log line

```sh
logger -n 127.0.0.1 -P 5514 -T "demo-app[1234]: order 43 shipped"
# or: printf '<14>%s demo-app[1234]: order 43 shipped\n' "$(date '+%b %e %H:%M:%S')" | nc -q1 127.0.0.1 5514
```

## Steps — see it land

```sh
sleep 2
curl -s -u elastic:${ELASTIC_PASSWORD} "http://localhost:9200/efk-lab-logs/_search?q=order&pretty"
```

A hit means Fluent Bit's `es` output plugin wrote it through. If nothing shows up, check `docker compose logs fluent-bit` first — a bad `[OUTPUT]` block fails loudly there, not silently. A `401`/`403` in that log means `LOG_WRITER_PASSWORD` doesn't match between `.env` and what `es-security-setup` set — see [00-overview.md](00-overview.md).

**In Kibana** (`http://localhost:5601`): log in as `idops` / `$IDOPS_PASSWORD` from your `.env` (see [README.md](README.md#login)). Create a data view on `efk-lab-logs`, open Discover, pick it.

## Prerequisites
- [01-install-tools.md](01-install-tools.md)

## Next
- [03-smoke-test.md](03-smoke-test.md)
