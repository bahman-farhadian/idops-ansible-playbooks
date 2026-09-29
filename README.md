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
8. `ah-container-runtime`
9. `ai-container-orchestration`
10. `aj-traffic-management`
11. `ak-databases`
12. `al-data-caching`
13. `am-message-brokers`
14. `an-data-applications`
15. `ao-identity-and-access`
16. `ap-secrets-and-pki`
17. `aq-observability`
18. `ar-centralized-logging`
19. `as-backup-and-disaster-recovery`
20. `at-security-and-compliance`
21. `au-ci-cd-automation`

## Domain Intent (Production)

A service in this list is open source, self-hosted, and production-ready. A paid product is left out even when it is the stronger product. JFrog is left out for that reason. Nexus stays. ESXi is required on this stack, so it stays even though it is not open source. Vault stays from the earlier decision. Its license is BSL 1.1, so it does not meet the open-source rule. OpenBao does.

Each domain has the playbooks below. A name with no directory yet is a decision, not an implementation. Copy `playbook-template/` only after that name is accepted.

A normal service guest is created by `ac-vm-provisioning/kvm-vm-provisioning` or `ac-vm-provisioning/esxi-vm-provisioning`, hardened by `ag-os-baseline-and-hardening/debian-based-os-hardening`, then handed to its service playbook. Most new services are one guest. A second guest for high availability is a later change inside the same playbook. The size exceptions are in the table: `debian-based-perimeter` is a pair, `kafka` is three brokers, `kubernetes` is three control planes plus workers, and `elk` and `efk` are three guests each. `openstack` deploys an OpenStack cluster, and `ceph` is distributed storage. The project defines the servers and the nodes for both. OpenStack does not use the KVM or ESXi playbooks. `ilo-management` is one playbook on the physical servers the project names.

Playbooks in this table are separate. They can be used together. The Alternatives column lists products that are not playbooks here.

| Domain | Playbook | Where it runs | Alternatives |
| --- | --- | --- | --- |
| `aa-physical-server-foundation` | `ilo-management` (no files yet) | One playbook. BIOS settings, BIOS update, and HPE iLO on the physical servers the project names. | — |
| `ab-hypervisor-host-platform` | `kvm-host` (no files yet) | Installed Debian or Ubuntu host. libvirt, pools, bridges. No guest. | — |
| `ab-hypervisor-host-platform` | `esxi-host` (no files yet) | Installed ESXi host. Datastores and port groups. No guest. | — |
| `ac-vm-provisioning` | `kvm-vm-provisioning` | Creates KVM guests. | — |
| `ac-vm-provisioning` | `esxi-vm-provisioning` (no files yet) | Creates the same four guest releases on ESXi. | — |
| `ac-vm-provisioning` | `openstack` (no files yet) | Deploys an OpenStack cluster. The project defines the servers and the nodes. | — |
| `ad-network-and-connectivity` | `opnsense-firewall` (later) | Its own install image. No files yet. | — |
| `ae-internal-services` | `debian-based-perimeter` | Debian or Ubuntu pair. Firewall, BIND, chrony, OpenVPN. chrony is not installed yet. | — |
| `ae-internal-services` | `ceph` (no files yet) | Monitor and OSD guests. The project defines how many. | MinIO is archived |
| `ae-internal-services` | `mattermost` (no files yet) | One guest. Server and its database on that guest. Install the AGPL-3.0 build. | Zulip |
| `af-artifact-management` | `nexus-repository-systemd` | One guest. APT and Docker Hub proxies. | Harbor, Pulp, apt-cacher. JFrog is paid |
| `ag-os-baseline-and-hardening` | `debian-based-os-hardening` | Guests that already exist. Lynis stays here. | No second OS family |
| `ah-container-runtime` | `docker-engine` | One guest. Swarm stays off. | Podman, containerd alone |
| `ai-container-orchestration` | `kubernetes` (no files yet) | Three control-plane guests plus workers (at least three). kubeadm and Cilium. | — |
| `ai-container-orchestration` | `docker-swarm` | Already in the repo. Swarm mode still runs. | — |
| `aj-traffic-management` | `haproxy` (no files yet) | One guest. HTTP and TCP reverse proxy. | Traefik |
| `aj-traffic-management` | `nginx` (no files yet) | One guest. HTTP and TCP reverse proxy. | Traefik |
| `ak-databases` | `postgresql` (no files yet) | One guest. Extra disk for data. | MySQL |
| `ak-databases` | `mariadb` (no files yet) | One guest. Extra disk for data. | MySQL |
| `ak-databases` | `clickhouse` (no files yet) | One guest. Extra disk for data. | — |
| `ak-databases` | `elasticsearch` (no files yet) | One guest. Extra disk for data. Application database. | OpenSearch |
| `ak-databases` | `mongodb` (no files yet) | One guest. Extra disk for data. Community Server is SSPL. | — |
| `al-data-caching` | `redis` (no files yet) | One guest. Redis 8 is tri-licensed. Use the AGPL terms. | Valkey, Memcached |
| `am-message-brokers` | `rabbitmq` (no files yet) | One guest. | NATS |
| `am-message-brokers` | `kafka` (no files yet) | Three broker guests. | NATS |
| `an-data-applications` | `metabase` (no files yet) | One guest. Its database stays on that guest. | — |
| `an-data-applications` | `superset` (no files yet) | One guest. Its metadata database stays on that guest. | — |
| `ao-identity-and-access` | `keycloak` (no files yet) | One guest. Its database stays on that guest. | Authentik, FreeIPA |
| `ap-secrets-and-pki` | `vault` (no files yet) | One guest. Secrets and internal certificates. BSL 1.1, kept from the earlier decision. | OpenBao is the open-source match. step-ca |
| `aq-observability` | `prometheus` (no files yet) | One guest. Prometheus, Alertmanager, and Grafana. | A separate Grafana playbook. Tempo, Jaeger |
| `aq-observability` | `zabbix` (no files yet) | One guest. Server, web UI, and its database on that guest. | — |
| `ar-centralized-logging` | `rsyslog` (no files yet) | One guest. Receives syslog. | Loki, OpenSearch |
| `ar-centralized-logging` | `elk` (no files yet) | Elasticsearch, Logstash, and Kibana. One guest each. | Loki, OpenSearch |
| `ar-centralized-logging` | `efk` (no files yet) | Elasticsearch, Fluent Bit, and Kibana. One guest each. | Fluentd, Loki, OpenSearch |
| `as-backup-and-disaster-recovery` | — | No product chosen yet. | Bareos and UrBackup are central services. restic, BorgBackup, and Kopia are engines. Veeam is paid |
| `at-security-and-compliance` | `wazuh` (no files yet) | One manager guest. Agents on existing guests come later in this playbook. | OpenSCAP, Security Onion |
| `au-ci-cd-automation` | `gitlab` (no files yet) | One guest. Git, CI, and its database stay on that guest. | Forgejo, Jenkins |

There is no storage domain in the `aa`–`au` list, so `ceph` sits in `ae-internal-services` with the other platform services. There is no chat domain in that list, so `mattermost` sits there too. `openstack` sits in `ac-vm-provisioning` and deploys an OpenStack cluster. It does not use `kvm-vm-provisioning` or `esxi-vm-provisioning`.

Left out of this decision: MinIO, a hosted Docker registry, DHCP, MySQL, JFrog, Veeam, Valkey, and Memcached. MinIO's community repository was archived in 2026. Object storage is the Ceph object gateway. WireGuard stays a later addition on the `debian-based-perimeter` pair. OpenVPN certificates stay in that playbook. Backup has no playbook name until that research is accepted. RAID is not a playbook.

## Why This Order

1. Infrastructure cannot be virtualized until physical servers and hypervisor hosts are ready.
2. VMs are created only after host platform capacity exists.
3. Networking and internal services are required before reliable internal package/image distribution.
4. Artifact management is placed before broad hardening and runtime rollout so systems can consume internal trusted sources.
5. OS hardening is then enforced with repo/runtime controls aligned to internal registries and mirrors.
6. Data layers are intentionally split into databases, caching, brokers, and data applications because they have different HA, scaling, and security lifecycles.
7. Orchestration, traffic, identity, secrets, observability, and resilience layers build on the secured runtime and database layers.
8. Security/compliance and CI/CD are top-level control layers that continuously govern and deliver across all lower layers.

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
- `ab-hypervisor-host-platform/` has no playbook files yet. The decided playbooks are `kvm-host` and `esxi-host`.
- Copy `playbook-template/` when you start a new project.
- Repository contributor standards: `CONTRIBUTOR-GUIDE.md`.
- Repository-wide work queue: `TODO.md`.
- Makefile standard: every project must provide `make ping`, all user commands must appear in `make help`, Makefiles must not pass `--limit`, and every action that talks to hosts must take `LOCAL_SETTINGS_FILE` with no default (see `CONTRIBUTOR-GUIDE.md`).

## Ignore Policy

- macOS `.DS_Store` files are ignored repository-wide and must never be committed.
- Python virtual environments are ignored repository-wide: use project-local `venv/` for Makefile workflows, but do not commit any `venv/` or `.venv/` files.
- Virtual environments are machine and path specific. Contributors must recreate them locally with each project Makefile, for example `make venv`.
- Keep dependency caches separate from virtual environments. Use documented `wheelhouse/` directories for reusable wheel artifacts when a project supports them.
