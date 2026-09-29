# idops-ansible-playbooks

Ansible playbook monorepo for the **idops** brand (`interdisciplinary + ops`), organized as a full-stack infrastructure roadmap.

## Structure Policy

- Root playbook directories are ordered from infrastructure base to top-level delivery.
- Prefixes use alphabetical sequence: `aa`, `ab`, `ac`, ... for deterministic ordering.
- Directory names are generalized and kebab-case (no provider/vendor lock in names).
- Directory order expresses platform dependency and design layering, not a mandatory single-pass execution order.
- Every top-level domain directory must contain its own `README.md` with scope, dependencies, variables, and runbook.
- Each project has one playbook (`playbook.yml`) and puts work in `tasks/`.
- Copy `playbook-template/` when you start a new project.

## Root Stack Layout (Bottom -> Top)

1. `aa-physical-server-foundation`
2. `ab-hypervisor-host-platform`
3. `ac-vm-provisioning`
4. `ad-network-and-connectivity`
5. `ae-internal-services`
6. `af-artifact-management`
7. `ag-os-baseline-and-hardening`
8. `ah-openstack`
9. `ai-container-runtime`
10. `aj-container-orchestration`
11. `ak-traffic-management`
12. `al-databases`
13. `am-data-caching`
14. `an-message-brokers`
15. `ao-data-applications`
16. `ap-identity-and-access`
17. `aq-secrets-and-pki`
18. `ar-observability`
19. `as-centralized-logging`
20. `at-backup-and-disaster-recovery`
21. `au-security-and-compliance`
22. `av-ci-cd-automation`

## Domain Intent (Production)

A service in this list is open source, self-hosted, and production-ready. A paid product is left out even when it is the stronger product. JFrog is left out for that reason. Nexus stays. ESXi is required on this stack, so it stays even though it is not open source. Vault stays from the earlier decision. Its license is BSL 1.1, so it does not meet the open-source rule. OpenBao does.

Each domain has the playbooks below. A name with no directory yet is a decision, not an implementation. Copy `playbook-template/` only after that name is accepted.

A normal service guest is created by `ac-vm-provisioning/kvm-vm-provisioning` or `ac-vm-provisioning/esxi-vm-provisioning`, hardened by `ag-os-baseline-and-hardening/debian-based-os-hardening`, then handed to its service playbook. Most new services are one guest. A second guest for high availability is a later change inside the same playbook. The size exceptions are in the table: `debian-based-perimeter` is a pair, `opnsense-firewall` is a pair, `kafka` is three brokers, `kubernetes` is three control planes plus workers, and `elk` and `efk` are three guests each. `ah-openstack` deploys an OpenStack cluster. It is not a hypervisor and it does not create guests. The project defines the servers and the nodes. It does not use the KVM or ESXi playbooks. `ceph` is distributed storage. The project defines the monitor and OSD guests. `ilo-4-management` and `ilo-5-management` are separate playbooks on the HPE servers the project names. The iLO license, IP address, and user are set by hand first. The user supplies the SPP ISO for that generation. iLO 6 and iLO 7 are later playbooks.

Playbooks in this table are separate. They can be used together. Where a playbook is placed is the admin's decision. Guest counts in this table stay as written. The Alternatives column lists products that are not playbooks here.

| Domain | Playbook | Where it runs | Alternatives |
| --- | --- | --- | --- |
| `aa-physical-server-foundation` | `ilo-4-management` (no files yet) | iLO 4 servers the project names. iLO over HTTP after the license, IP, and user exist. User supplies that generation's SPP ISO. | Dell, Supermicro |
| `aa-physical-server-foundation` | `ilo-5-management` (no files yet) | iLO 5 servers the project names. Same HTTP path and the same hand setup. User supplies that generation's SPP ISO. | Dell, Supermicro |
| `ab-hypervisor-host-platform` | `debian-based-os-install` (no files yet) | One playbook. Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04 from the ISO the project supplies. | — |
| `ab-hypervisor-host-platform` | `kvm-host` (no files yet) | After that install. Distro comes from `gather_facts`. libvirt, pools, bridges. No guest. | — |
| `ab-hypervisor-host-platform` | `kvm-host-hardening` (no files yet) | Hardening for the KVM host. Guest hardening stays in `ag`. | — |
| `ab-hypervisor-host-platform` | `esxi-host` (no files yet) | Final playbook in this directory. Installs ESXi from the ISO the project supplies, then host setup and hardening. The Makefile checks the image against the server generation. | — |
| `ac-vm-provisioning` | `kvm-vm-provisioning` | KVM guests from Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04 cloud images. No application services. | — |
| `ac-vm-provisioning` | `esxi-vm-provisioning` (no files yet) | The same four guest releases on ESXi. No application services. | — |
| `ad-network-and-connectivity` | `opnsense-firewall` (later) | Pair. Firewall, DNS, time, and OpenVPN on the OPNsense image. The admin decides where the pair runs. No files yet. | — |
| `ae-internal-services` | `debian-based-perimeter` | Debian or Ubuntu pair. Firewall, BIND, chrony, OpenVPN. chrony is not installed yet. | — |
| `ae-internal-services` | `ceph` (no files yet) | Monitor and OSD guests. The project defines how many. | MinIO is archived |
| `ae-internal-services` | `mattermost` (no files yet) | One guest. Server and its database on that guest. Install the AGPL-3.0 build. | Zulip |
| `ae-internal-services` | `stalwart` (no files yet) | One guest. Mail, calendar, and contacts. Community edition is AGPL-3.0. | A Postfix and Dovecot stack |
| `af-artifact-management` | `nexus-repository-systemd` | One guest. APT and Docker Hub proxies. | Harbor, Pulp, apt-cacher. JFrog is paid |
| `ag-os-baseline-and-hardening` | `debian-based-os-hardening` | Guests that already exist. Lynis stays here. | No second OS family |
| `ah-openstack` | `openstack` (no files yet) | An OpenStack cluster. The project defines the servers and the nodes. Not a hypervisor and not guest creation. | — |
| `ai-container-runtime` | `docker-engine` | One guest. Swarm stays off. | Podman, containerd alone |
| `aj-container-orchestration` | `kubernetes` (no files yet) | Three control-plane guests plus workers (at least three). kubeadm and Cilium. | — |
| `aj-container-orchestration` | `docker-swarm` | Already in the repo. Swarm mode still runs. | — |
| `ak-traffic-management` | `haproxy` (no files yet) | One guest. HTTP and TCP reverse proxy. | Traefik |
| `ak-traffic-management` | `nginx` (no files yet) | One guest. HTTP and TCP reverse proxy. | Traefik |
| `al-databases` | `postgresql` (no files yet) | One guest. Extra disk for data. | MySQL |
| `al-databases` | `mariadb` (no files yet) | One guest. Extra disk for data. | MySQL |
| `al-databases` | `clickhouse` (no files yet) | One guest. Extra disk for data. | — |
| `al-databases` | `elasticsearch` (no files yet) | One guest. Extra disk for data. Application database. | OpenSearch |
| `al-databases` | `mongodb` (no files yet) | One guest. Extra disk for data. Community Server is SSPL. | — |
| `am-data-caching` | `redis` (no files yet) | One guest. Redis 8 is tri-licensed. Use the AGPL terms. | Valkey, Memcached |
| `an-message-brokers` | `rabbitmq` (no files yet) | One guest. | NATS |
| `an-message-brokers` | `kafka` (no files yet) | Three broker guests. | NATS |
| `ao-data-applications` | `metabase` (no files yet) | One guest. Its database stays on that guest. | — |
| `ao-data-applications` | `superset` (no files yet) | One guest. Its metadata database stays on that guest. | — |
| `ap-identity-and-access` | `keycloak` (no files yet) | One guest. Its database stays on that guest. | Authentik, FreeIPA |
| `aq-secrets-and-pki` | `vault` (no files yet) | One guest. Secrets and internal certificates. BSL 1.1, kept from the earlier decision. | OpenBao is the open-source match. step-ca |
| `ar-observability` | `prometheus` (no files yet) | One guest. Prometheus, Alertmanager, and Grafana. | A separate Grafana playbook. Tempo, Jaeger |
| `ar-observability` | `zabbix` (no files yet) | One guest. Server, web UI, and its database on that guest. | — |
| `as-centralized-logging` | `rsyslog` (no files yet) | One guest. Receives syslog. | Loki, OpenSearch |
| `as-centralized-logging` | `elk` (no files yet) | Elasticsearch, Logstash, and Kibana. One guest each. | Loki, OpenSearch |
| `as-centralized-logging` | `efk` (no files yet) | Elasticsearch, Fluent Bit, and Kibana. One guest each. | Fluentd, Loki, OpenSearch |
| `at-backup-and-disaster-recovery` | — | No product chosen yet. | Bareos and UrBackup are central services. restic, BorgBackup, and Kopia are engines. Veeam is paid |
| `au-security-and-compliance` | `wazuh` (no files yet) | One manager guest. Agents on existing guests come later in this playbook. | OpenSCAP, Security Onion |
| `av-ci-cd-automation` | `gitlab` (no files yet) | One guest. Git, CI, and its database stay on that guest. | Forgejo, Jenkins |

There is no storage domain in the `aa`–`av` list, so `ceph` sits in `ae-internal-services` with the other platform services. There is no chat or mail domain in that list, so `mattermost` and `stalwart` sit there too. A project uses one perimeter, `debian-based-perimeter` or `opnsense-firewall`. MX, SPF, DKIM, and DMARC for Stalwart stay on that pair. `ah-openstack` deploys an OpenStack cluster. It is not a hypervisor and it does not create guests. It does not use `kvm-vm-provisioning` or `esxi-vm-provisioning`.

Left out of this decision: MinIO, a hosted Docker registry, DHCP, MySQL, JFrog, Veeam, Valkey, and Memcached. MinIO's community repository was archived in 2026. Object storage is the Ceph object gateway. WireGuard stays a later addition on the `debian-based-perimeter` pair and on the `opnsense-firewall` pair. OpenVPN certificates stay on the pair that runs that playbook. Backup has no playbook name until that research is accepted. Disk and RAID layout is not its own playbook. Each physical server's role defines it, and that work is added when the project reaches that server.

## Why This Order

1. Infrastructure cannot be virtualized until physical servers and hypervisor hosts are ready.
2. VMs are created only after host platform capacity exists.
3. Networking and internal services are required before reliable internal package/image distribution.
4. Artifact management is placed before broad hardening and runtime rollout so systems can consume internal trusted sources.
5. OS hardening is then enforced with repo/runtime controls aligned to internal registries and mirrors.
6. OpenStack follows that baseline as its own domain, `ah-openstack`, before the container runtime.
7. Data layers are intentionally split into databases, caching, brokers, and data applications because they have different HA, scaling, and security lifecycles.
8. Orchestration, traffic, identity, secrets, observability, and resilience layers build on the secured runtime and database layers.
9. Security/compliance and CI/CD are top-level control layers that continuously govern and deliver across all lower layers.

## Execution Model (Important)

1. This repository is layered by architecture domains, not a strict one-time linear playbook chain.
2. Real production execution is iterative:
   - bootstrap wave: bring up minimum infra and artifact services
   - hardening wave: enforce baseline/hardening against internal package/image sources
   - platform wave: deploy runtime, orchestration, traffic, databases, caching, brokers, and data applications
   - continuous wave: observability, logging, backup, compliance, and CI/CD lifecycle operations
3. Some domains are re-applied multiple times (for example hardening, IAM, compliance) as infrastructure evolves.

## Notes

- Each top-level directory will become a dedicated playbook domain.
- Guest provisioning was migrated from the legacy `kvm-clone-ansible` playbook into `ac-vm-provisioning/kvm-vm-provisioning/`; the legacy `old_playbooks/` directory has since been removed now that every project it held has an adopted replacement.
- `ab-hypervisor-host-platform/` has no playbook files yet. Directory order is `debian-based-os-install`, `kvm-host`, `kvm-host-hardening`, then `esxi-host`.
- Copy `playbook-template/` when you start a new project.
- Repository contributor standards: `CONTRIBUTOR-GUIDE.md`.
- Repository-wide work queue: `TODO.md`.
- Makefile standard: every project must provide `make ping`, all user commands must appear in `make help`, Makefiles must not pass `--limit`, and every action that talks to hosts must take `LOCAL_SETTINGS_FILE` with no default (see `CONTRIBUTOR-GUIDE.md`).

## Ignore Policy

- macOS `.DS_Store` files are ignored repository-wide and must never be committed.
- Python virtual environments are ignored repository-wide: use project-local `venv/` for Makefile workflows, but do not commit any `venv/` or `.venv/` files.
- Virtual environments are machine and path specific. Contributors must recreate them locally with each project Makefile, for example `make venv`.
- Keep dependency caches separate from virtual environments. Use documented `wheelhouse/` directories for reusable wheel artifacts when a project supports them.
