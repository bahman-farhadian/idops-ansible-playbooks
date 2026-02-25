# idops-ansible-playbooks

Ansible playbook monorepo for the **idops** brand (`interdisciplinary + ops`), organized as a full-stack infrastructure roadmap.

## Structure Policy

- Root playbook directories are ordered from infrastructure base to top-level delivery.
- Prefixes use alphabetical sequence: `aa`, `ab`, `ac`, ... for deterministic ordering.
- Directory names are generalized and kebab-case (no provider/vendor lock in names).
- Directory order expresses platform dependency and design layering, not a mandatory single-pass execution order.
- Legacy content stays in `old_playbooks/` and is not modified during layout migration.
- Every top-level domain directory must contain its own `README.md` with scope, dependencies, variables, and runbook.
- Implementation projects use one playbook entrypoint (`playbook.yml`) and organize workflows via `tasks/`.

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

- `aa-physical-server-foundation`: rack-level baseline, firmware/BIOS policy, storage/RAID, and hardware prep standards.
- `ab-hypervisor-host-platform`: hypervisor host build (Debian+KVM, ESXi host integration, host-level prerequisites).
- `ac-vm-provisioning`: VM lifecycle creation and allocation for workload environments.
- `ad-network-and-connectivity`: routing, addressing, segmentation, firewall paths, and connectivity enforcement.
- `ae-internal-services`: core in-house platform services (DNS, DHCP, NTP, internal supporting services).
- `af-artifact-management`: internal package/image/repository cache and registry services.
- `ag-os-baseline-and-hardening`: OS baseline + security hardening for hosts and VMs.
- `ah-container-runtime`: Docker/containerd runtime rollout and policy.
- `ai-container-orchestration`: Kubernetes and cluster-level orchestration controls.
- `aj-traffic-management`: ingress/reverse proxy/load-balancing and service exposure controls.
- `ak-databases`: stateful data platforms and high-availability database services.
- `al-data-caching`: cache platforms (Redis/Valkey/Memcached) for application and database acceleration patterns.
- `am-message-brokers`: event and queue platforms (Kafka, RabbitMQ, NATS, Redis streams).
- `an-data-applications`: data-facing platform apps (Metabase, Superset, and similar internal data products).
- `ao-identity-and-access`: authentication, authorization, and access control integration.
- `ap-secrets-and-pki`: secrets lifecycle, key management, certificates, and trust chains.
- `aq-observability`: metrics/traces/alerts instrumentation and collection.
- `ar-centralized-logging`: centralized log transport, retention, and query paths.
- `as-backup-and-disaster-recovery`: backup policy, restore automation, and DR execution paths.
- `at-security-and-compliance`: posture scanning, benchmarks, remediation policy, and evidence generation.
- `au-ci-cd-automation`: delivery automation and promotion pipelines.

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
- `old_playbooks/` is kept as reference material while the new idops layout is built incrementally.
- Guest provisioning legacy `old_playbooks/kvm-clone-ansible/` is migrated into `ac-vm-provisioning/kvm-vm-provisioning/`.
- Repository contributor standards: `CONTRIBUTOR-GUIDE.md`.
- Makefile standard: every project must provide `make ping`, and all user commands must appear in `make help`.
