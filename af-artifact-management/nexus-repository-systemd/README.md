# nexus-repository-systemd

Install Sonatype Nexus Repository Manager 3 as a **systemd** service.
This is not a Docker container.

The Nexus **host** can be Debian 12, Debian 13, Ubuntu 24.04, or
Ubuntu 26.04. APT proxies cover all four as clients.

The installed version is **pinned** (`nexus_version` in `vars/nexus.yml`).
The web UI may show a newer build. Ignore that banner unless you change
`nexus_version` and `nexus_download_checksum`, then run `make deploy`.
See the comments in `vars/nexus.yml` for the download and checksum links.

Web UI sign-in: user `admin`. The password is `nexus_admin_password` in
your local settings file. Click the user icon at the top right, then
Sign In.

Status "Default Secret Encryption Key" needs a custom key. Set
`nexus_secrets_key` in the local file (`openssl rand -base64 32`). The
playbook writes it to `/data/nexus/etc/nexus-secrets.json` and does not
put the key in git.

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

| Step | File |
| --- | --- |
| 0. Delete all test guests | `kvm-vm-provisioning/vars/settings.kvm.cleanup-all.local.yml` |
| 1. Create the Nexus VM | `kvm-vm-provisioning/vars/settings.kvm.nexus.local.yml` |
| 2. Harden Nexus pass 1 | `debian-based-os-hardening/vars/settings.harden.nexus.local.yml` |
| 3. Harden Nexus pass 2 | `debian-based-os-hardening/vars/settings.harden.nexus.pass2.local.yml` |
| 4. Install Nexus | `nexus-repository-systemd/vars/settings.nexus.local.yml` |
| 5. Create four guests via Nexus APT | `kvm-vm-provisioning/vars/settings.kvm.fleet-via-nexus.local.yml` |
| 6. Harden four guests pass 1 | `debian-based-os-hardening/vars/settings.harden.fleet-via-nexus.local.yml` |
| 7. Harden four guests pass 2 | `debian-based-os-hardening/vars/settings.harden.fleet-via-nexus.pass2.local.yml` |
| 8. Delete only the four guests | `kvm-vm-provisioning/vars/settings.kvm.cleanup-fleet.local.yml` |
| 9. Create the four guests again (cache) | same file as step 5 |

Tracked APT URLs stay on the internet. When Nexus is up, a local
settings file can set `apt_debian_repository_by_suite` and
`apt_ubuntu_repository_by_suite` so guests use this cache.

Suggested guest: `idops-nexus-repository` at `192.168.24.2`, 4 GiB RAM,
extra disk 20 GiB on `/data`. The playbook also accepts Ubuntu 24.04
or 26.04 as the Nexus host if you point `nexus_targets` at that guest.

## Full test (one file per step)

This deletes guests (disks included). Nexus guest: `idops-nexus-repository`
at `192.168.24.2`. Check guests with `virsh`, not SSH.

From the repository root:

```bash
# 0. Delete all test guests (Nexus + four clients) and their disks
cd ac-vm-provisioning/kvm-vm-provisioning
make cleanup-force-disks LOCAL_SETTINGS_FILE=vars/settings.kvm.cleanup-all.local.yml
```

```bash
# 1. Create the Nexus guest
cd ac-vm-provisioning/kvm-vm-provisioning
make provision LOCAL_SETTINGS_FILE=vars/settings.kvm.nexus.local.yml
virsh -c qemu:///system list --all
```

```bash
# 2–3. Harden the Nexus guest (pass 1, then pass 2)
cd ag-os-baseline-and-hardening/debian-based-os-hardening
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.nexus.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.nexus.pass2.local.yml
make scan LOCAL_SETTINGS_FILE=vars/settings.harden.nexus.pass2.local.yml
```

```bash
# 4. Install Nexus (admin password and encryption key are in the local file)
cd af-artifact-management/nexus-repository-systemd
make ping LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
```

```bash
# 5–7. Four guests that fill the Nexus APT cache
cd ac-vm-provisioning/kvm-vm-provisioning
make provision LOCAL_SETTINGS_FILE=vars/settings.kvm.fleet-via-nexus.local.yml
cd ag-os-baseline-and-hardening/debian-based-os-hardening
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.fleet-via-nexus.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.fleet-via-nexus.pass2.local.yml
```

```bash
# 8. Delete only the four guests. Keep Nexus.
cd ac-vm-provisioning/kvm-vm-provisioning
make cleanup-force-disks LOCAL_SETTINGS_FILE=vars/settings.kvm.cleanup-fleet.local.yml
```

```bash
# 9–11. Four guests again (packages should come from the Nexus cache)
cd ac-vm-provisioning/kvm-vm-provisioning
make provision LOCAL_SETTINGS_FILE=vars/settings.kvm.fleet-via-nexus.local.yml
cd ag-os-baseline-and-hardening/debian-based-os-hardening
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.fleet-via-nexus.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.harden.fleet-via-nexus.pass2.local.yml
```

## After Nexus is up: point guests at it

In a **new** harden local file (do not change the internet defaults
in `vars/debian-hardening.yml`):

```yaml
apt_debian_repository_by_suite:
  trixie:
    url: "http://192.168.24.2:8081/repository/debian-trixie"
    updates_url: "http://192.168.24.2:8081/repository/debian-trixie-updates"
    security_url: "http://192.168.24.2:8081/repository/debian-trixie-security"
```

Same idea for Ubuntu suites under `apt_ubuntu_repository_by_suite`.

Fill the cache once (two guests is enough), then create the four
guests with a fleet local file that uses those URLs.

## Harden the Nexus VM

Open TCP **8081** and **8082** on that host. Keep
`firewall_allow_private_networks: true` so the 10/8, 172.16/12, and
192.168/16 ranges can reach it.
