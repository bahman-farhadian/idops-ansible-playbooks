# at-centralized-logging

Domain status: decision only (no playbook files yet)

## Purpose

Log collection for the stack. `rsyslog/`, `elk/`, and `efk/` are different playbooks. Running one does not install the other. A project can run `rsyslog/`. It runs `elk/` or `efk/`, and it does not run both. The Elasticsearch here is the logging cluster. The application database is `am-databases/elasticsearch`. Hardening already installs rsyslog on each guest. `rsyslog/` here is only the central receiver.

## Logging Elasticsearch

`elk/` and `efk/` use the same Elasticsearch decisions as `am-databases/elasticsearch`. A project runs only one of those playbooks, so it has one logging cluster.

- The playbook builds a pinned 9.x source release and chooses AGPL-3.0. It does not install Elastic's package. Snapshots, alphas, betas, and release candidates stay out. The pin moves only to another maintained 9.x release. X-Pack stays out, including the built-in login, machine learning, and cross-cluster replication. The JDK used to compile does not stay on the guest
- Three layouts. The project picks one in local settings. One guest. A cluster. A sharded cluster. Elasticsearch elects its own masters and stores its own shard copies. A master count of two is refused
- One guest is a local-settings choice. That guest has no second copy. Each guest has an extra disk for its data. The disk size stays in local settings
- The cluster is 3 guests. Each guest can be master and hold data. One guest can fail, the other two still elect a master, and each shard has a replica on another guest. A document is written on two of the three guests
- The sharded cluster is those same 3 guests. The index is split into primary shards, and each primary has a replica on another of those guests. That replica does not get its own virtual machine. Elasticsearch places the shards. One guest can fail and the replica on a remaining guest is promoted. The odd count is for guests that can be master. A layout of 3 master-only guests plus at least 2 data guests is a later size change, when the data outgrows these 3. Added data guests do not have to keep the total odd
- Clients use one address. That address is required for every layout, including one Elasticsearch guest. Two choices, picked in local settings. A new pair is 2 HAProxy guests. `al-traffic-management/haproxy` installs HAProxy. This playbook writes the configuration and sets up keepalived on those guests, so clients have one address. One new HAProxy guest is refused. An existing HAProxy is addresses in local settings. This playbook writes the logging backend there and does not install HAProxy. The pair is not part of the Elasticsearch count
- This playbook does not create the guests and does not call provisioning or hardening

| Scenario | Elasticsearch VMs | Kibana VMs | New HAProxy VMs |
| --- | --- | --- | --- |
| One guest, selected in local settings | 1 | 1 | 2, or 0 when the project uses an existing HAProxy |
| Cluster | 3 | 1 | 2, or 0 when the project uses an existing HAProxy |
| Sharded cluster | 3. The same guests | 1 | 2, or 0 when the project uses an existing HAProxy |

Logstash or Fluent Bit is not in this table. Those programs run on guests that already exist.

## Playbook

- `rsyslog/`
  - One guest. This is the central receiver
  - `ag-os-baseline-and-hardening/debian-based-os-hardening` already installs rsyslog on each hardened guest, keeps local logs, and can forward them. Forwarding stays off until that guest's hardening settings name this receiver. This playbook does not install rsyslog on those guests
  - The Docker Engine playbook also installs rsyslog, for the Docker daemon log on that guest
  - This playbook does not create the guest and does not call provisioning or hardening
- `elk/`
  - A project runs this playbook or `efk/`, not both
  - Elasticsearch, as written above
  - One Kibana guest. Kibana is the front end. The playbook builds the same pinned 9.x source release as this Elasticsearch and chooses AGPL-3.0. It does not install Elastic's package. X-Pack stays out, so Kibana has no built-in login
  - Logstash runs on the guests that produce the logs. The administrator names those guests. This playbook installs Logstash there and does not create them. The task uses its own local settings file. Logstash is pinned to the same maintained 9.x line and uses the Apache 2.0 package
  - This playbook does not install Fluent Bit
- `efk/`
  - A project runs this playbook or `elk/`, not both
  - Elasticsearch, as written above. Its own cluster, used only when this playbook is the one the project runs
  - One Kibana guest, with the same Kibana build as `elk/`
  - Fluent Bit runs on the guests that produce the logs. The administrator names those guests. This playbook installs Fluent Bit there and does not create them. The task uses its own local settings file. Fluent Bit is the collector. The playbook pins a stable release. Snapshots, alphas, betas, and release candidates stay out
  - This playbook does not install Logstash

## Alternatives

- Loki and OpenSearch. Fluentd is the collector `efk/` does not use.

## Left out

- Running `elk/` and `efk/` in the same project
- Loki and OpenSearch
- Fluentd
- A second Kibana guest
- Kibana login, and pointing Kibana at Keycloak. X-Pack stays out
- A Logstash or Fluent Bit guest of its own. Those programs run on guests that already produce logs
- A logging Elasticsearch with no single address
- One new HAProxy guest. A new pair is 2. An existing HAProxy is used through its addresses

## Dependencies

- Upstream: the guests the administrator provides. This playbook does not create them
- Downstream: people reading logs in Kibana

## Status

- Playbook files: no
- Review: rsyslog is the central receiver. Hardening already installs rsyslog on each guest. One of ELK or EFK, the Elasticsearch layout, one Kibana, and a required single address are decided
