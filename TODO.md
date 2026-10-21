# TODO

Repository-wide work queue. Keep entries short; put the real design work in
the branch/PR that picks the item up, not in this file.

Domain READMEs on `main` are decided through `aw-ci-cd-automation`. The
Afarinak Swarm guests are up. The idops Kubernetes guests have local settings
only.

## Next

- idops Kubernetes guests: provision and harden using the existing local
  settings. The LAN guests need the firewall pair forwarding first.
- `debian-based-perimeter` local settings for that pair (WAN VIP
  `192.168.32.60`, LAN VIP `10.32.0.60`).
- `haproxy` playbook and local settings for the API proxy pair.
- `kubernetes` playbook (kubeadm). No files yet.
- `ceph` playbook. No files yet. OSD disks are already in the KVM settings.
- Same host as the Afarinak Swarm: 118 GB RAM and 910 GB disk in the
  Kubernetes table do not fit beside the Swarm guests.

## Playbooks with no files yet

Copy `playbook-template/` only when that name is picked up.

- `aa-physical-server-foundation`: `ilo-4-management`, `ilo-5-management`
- `ab-hypervisor-host-platform`: `debian-based-os-install`, `kvm-host`,
  `kvm-host-hardening`, `esxi-host`
- `ac-vm-provisioning`: `esxi-vm-provisioning`
- `ae-internal-services`: `mattermost`, `stalwart`
- `ah-distributed-storage`: `ceph`
- `ai-openstack`: `openstack`
- `ak-container-orchestration`: `kubernetes`
- `al-traffic-management`: `haproxy`, `nginx`, `traefik`
- `am-databases`: `postgresql`, `mariadb`, `clickhouse`, `elasticsearch`,
  `mongodb`
- `an-data-caching`: `redis`
- `ao-message-brokers`: `rabbitmq`, `kafka`
- `ap-data-applications`: `metabase`, `superset`
- `aq-identity-and-access`: `keycloak`
- `ar-secrets-and-pki`: `vault`
- `as-observability`: `prometheus`, `zabbix`, `grafana`
- `at-centralized-logging`: `rsyslog`, `elk`, `efk`, `clickstack`
- `au-backup-and-disaster-recovery`: `virtnbdbackup`
- `av-security-and-compliance`: `wazuh`
- `aw-ci-cd-automation`: `gitlab`, `jenkins`

## Later

- `ad-network-and-connectivity/opnsense-firewall`: pair, own image,
  `config.xml` or HTTPS API.
- WireGuard on `debian-based-perimeter`.
- iLO 6 and iLO 7.
- Jenkins agents, Wazuh agents, node exporter, Zabbix agent.
- Extra Nexus repository types, one type at a time.
- First virtnbdbackup boot test of a real guest. Offsite copy after that.
- Argo CD belongs with Kubernetes, not `aw-ci-cd-automation`.
- Fluent Bit version pin in `at-centralized-logging`.

## Docs leftovers

- Root catalog still says a virtnbdbackup restore test is open.
- `am-databases` still calls an Elasticsearch replica the backup copy.
- Root catalog still says a second guest for HA is a later change.
