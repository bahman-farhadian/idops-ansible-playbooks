# nexus-repository-systemd

Install Sonatype Nexus Repository Manager 3 as a **systemd** service.
This is not a Docker container.

It runs on the lab LAN only: HTTP port **8081** for the web UI and APT,
and port **8082** for a Docker Hub reverse proxy. Private networks
(`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) can use it. Do not
put this host on the public internet.

## What it creates

APT reverse proxies (Debian and Ubuntu):

| Client | URL |
| --- | --- |
| Debian 12 | `http://<nexus-ip>:8081/repository/debian-bookworm` |
| Debian 13 | `http://<nexus-ip>:8081/repository/debian-trixie` |
| Ubuntu 24.04 | `http://<nexus-ip>:8081/repository/ubuntu-noble` |
| Ubuntu 26.04 | `http://<nexus-ip>:8081/repository/ubuntu-resolute` |

Each suite also has `-updates` and `-security` (Ubuntu also `-backports`).

Docker Hub reverse proxy:

```
<nexus-ip>:8082
```

A hosted Docker repo is not created yet. The list
`nexus_docker_proxy_repositories` in `vars/nexus.yml` is the place to
add one later.

Data lives on **`/data/nexus`**. The guest must have an extra disk
mounted at `/data`.

## Named local settings (one file per step)

Do not edit the four-guest `settings.kvm.local.yml` file for this.
Each step has its own `*.local.yml` file.

| Step | File | Playbook |
| --- | --- | --- |
| 1. Create the Nexus VM | `ac-vm-provisioning/kvm-vm-provisioning/vars/settings.kvm.nexus.local.yml` | kvm-vm-provisioning |
| 2. Harden pass 1 (cloud user, port 22) | `ag-os-baseline-and-hardening/debian-based-os-hardening/vars/settings.harden.nexus.local.yml` | debian-based-os-hardening |
| 3. Harden pass 2 (root, port 2222) | `.../vars/settings.harden.nexus.pass2.local.yml` | debian-based-os-hardening |
| 4. Install Nexus | `af-artifact-management/nexus-repository-systemd/vars/settings.nexus.local.yml` | this project |
| Later: four guests via Nexus APT | `.../vars/settings.kvm.fleet-via-nexus.local.yml` | kvm-vm-provisioning |

Tracked APT URLs stay on the internet. When Nexus is up, a local
settings file can set `apt_debian_repository_by_suite` and
`apt_ubuntu_repository_by_suite` so guests use this cache.

Suggested guest: `debian-13-nexus` at `192.168.24.10`, 4 GiB RAM,
extra disk 100 GiB on `/data`. Change the IP in the local files if
you need a different address.

## Commands

Create the local file for this playbook, then set the admin password
and the real host:

```bash
cd af-artifact-management/nexus-repository-systemd
make settings LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
# set nexus_targets and nexus_admin_password in that file
make ping LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
```

`make deploy` downloads Nexus (pinned version in `vars/nexus.yml`),
installs the systemd unit, waits until port 8081 answers, sets the
admin password, turns on anonymous pull, and creates the APT and
Docker proxy repositories.

## After Nexus is up: point guests at it

In a **new** harden local file (do not change the internet defaults
in `vars/debian-hardening.yml`):

```yaml
apt_debian_repository_by_suite:
  trixie:
    url: "http://192.168.24.10:8081/repository/debian-trixie"
    updates_url: "http://192.168.24.10:8081/repository/debian-trixie-updates"
    security_url: "http://192.168.24.10:8081/repository/debian-trixie-security"
```

Same idea for Ubuntu suites under `apt_ubuntu_repository_by_suite`.

Fill the cache once (two guests is enough), then create the four
guests with a fleet local file that uses those URLs.

## Harden the Nexus VM

Open TCP **8081** and **8082** on that host. Keep
`firewall_allow_private_networks: true` so the 10/8, 172.16/12, and
192.168/16 ranges can reach it.
