# 02. Run ELK

**Goal:** Elasticsearch + Kibana + Logstash up, one demo log line through Logstash, visible in Kibana.

## Teaching note

Logstash's `grok` filter is the part worth watching here: a raw string in, a structured field out. The `elk-lab-logs-%{+YYYY.MM.dd}` index pattern in [`logstash/pipeline/logstash.conf`](logstash/pipeline/logstash.conf) is the same daily-index habit real syslog pipelines use, so old days are easy to drop without touching today's data.

**Applies to:** this directory, with [compose.yaml](compose.yaml) and [compose.elk.yaml](compose.elk.yaml) together.

## Steps — bring the stack up

```sh
cd at-centralized-logging/idops-elk-efk-lab
docker compose -f compose.yaml -f compose.elk.yaml up -d --wait   # --wait blocks until healthchecks pass
docker compose -f compose.yaml -f compose.elk.yaml ps
```

`--wait` needs Compose v2.17+; if your Compose is older, drop it and poll by hand:
```sh
until curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health | grep -q '"status":"yellow"\|"status":"green"'; do
  sleep 2
done
echo "Elasticsearch is up"
```

## Steps — confirm each piece answers

```sh
curl -s -u elastic:${ELASTIC_PASSWORD} http://localhost:9200/_cluster/health?pretty   # status, node count (1); credentials from .env
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:5601/api/status   # Kibana; 200 once it's ready — this endpoint doesn't need login
docker compose -f compose.yaml -f compose.elk.yaml logs logstash --tail=20  # Logstash's own startup log
```

## Steps — send a demo log line

Logstash listens on TCP and UDP 5514. `logger` (util-linux) writes over the network without you installing anything extra; `nc` is the fallback on hosts whose `logger` build has no network flags.

```sh
logger -n 127.0.0.1 -P 5514 -T "demo-app[1234]: order 42 shipped"     # TCP
# or, if logger has no -n/-T on this host:
printf '<14>%s demo-app[1234]: order 42 shipped\n' "$(date '+%b %e %H:%M:%S')" | nc -q1 127.0.0.1 5514
```

## Steps — see it land

```sh
sleep 2                                                        # Logstash flush interval
curl -s -u elastic:${ELASTIC_PASSWORD} "http://localhost:9200/elk-lab-logs-$(date +%Y.%m.%d)/_search?q=order&pretty"
```

A hit with `"log_message": "demo-app[1234]: order 42 shipped"` and a parsed `log_timestamp` confirms the `grok` filter matched. A `_grokparsefailure_demo` tag instead means the line didn't look like syslog — the document still landed, just unparsed; check the exact line against the `grok` pattern in [`logstash/pipeline/logstash.conf`](logstash/pipeline/logstash.conf). If no document landed at all and `docker compose ... logs logstash` shows a `401`/`403` from the `elasticsearch` output, re-check `LOG_WRITER_PASSWORD` matches between `.env` and what `es-security-setup` actually set — see [00-overview.md](00-overview.md).

**In Kibana** (`http://localhost:5601`): log in as `idops` / `$IDOPS_PASSWORD` from your `.env` (see [README.md](README.md#login)). Then Stack Management → Data Views → create one on `elk-lab-logs-*`, open Discover, pick it. The line you sent shows up as a document with `log_timestamp` and `log_message` fields broken out.

## Before switching to EFK

Logstash and Fluent Bit both claim host port 5514. Stop this overlay first:
```sh
docker compose -f compose.yaml -f compose.elk.yaml down       # Elasticsearch/Kibana data volume is untouched
```

## Prerequisites
- [01-install-tools.md](01-install-tools.md)

## Next
- [03-run-efk.md](03-run-efk.md), or [04-smoke-test.md](04-smoke-test.md) to wrap up here
