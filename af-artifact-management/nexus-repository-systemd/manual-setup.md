# Manual Nexus Repository setup

This guide follows `playbook.yml`, `tasks/`, `templates/`, and
`vars/nexus.yml`. Ansible is the repeatable deployment and repository
reconciliation path. This manual walkthrough explains the installation
sequence and the checks behind it. Use it for learning or a controlled
recovery, then return the service to Ansible management.

The supported host is Debian 12/13 or Ubuntu 24.04/26.04 on x86_64. The
configured version and SHA-256 checksum in `vars/nexus.yml` are the source
of truth. The data directory `/data/nexus` must be on the mounted extra
disk before installation. Keep `nexus_admin_password` and
`nexus_secrets_key` in a protected local secret store, never in Git.

## 1. Prepare the host and data disk

Confirm the configured data disk is mounted at the configured mount point
and the CPU architecture is supported:

```bash
findmnt /data
df -h /data
uname -m
```

The expected architecture is `x86_64`. The pinned archive includes its
JDK. Do not format a disk as part of this procedure unless its identity
and empty state have been confirmed separately. Install utilities used
by the service setup:

```bash
sudo apt-get update
sudo apt-get install -y curl ca-certificates tar
```

## 2. Download and verify the pinned archive

Download once on the control host, matching the repository's large-file
policy, and verify the archive with the checksum from `vars/nexus.yml`.
Then copy the verified file to the Nexus host. Do not download a different
version because the UI displays an update notice.

```bash
NEXUS_VERSION='3.95.4-01'
ARCHIVE="nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
curl --fail --location --retry 6 --retry-delay 20 --max-time 600 \
  --output "$ARCHIVE" "https://download.sonatype.com/nexus/3/$ARCHIVE"
printf '%s  %s\n' 'CHECKSUM_FROM_vars/nexus.yml' "$ARCHIVE" | sha256sum --check
```

Replace the checksum token with the tracked pin. Copy the verified archive
to `/var/cache/nexus` on the guest.

## 3. Install the service account and files

Follow `tasks/install.yml`: create the system `nexus` group and user with
no login shell; create the install, cache, and data directories; unpack
the archive under `/opt`; and point `/opt/nexus` at the pinned release.
Keep the data, temporary, and log paths under the mounted `/data/nexus`.
Set ownership to `nexus:nexus` and apply the modes from the task file.

Set `nexus.vmoptions` data, temp, and JVM log paths to the values in
`vars/nexus.yml`. Set the configured heap only when `nexus_heap` is
nonempty. Set the HTTP application port and listen address, and render
`templates/nexus.service.j2` to `/etc/systemd/system/nexus.service`.

Render `templates/nexus-secrets.json.j2` with the protected
`nexus_secrets_key_id` and `nexus_secrets_key`, mode `0600`, then set
`nexus.secrets.file` in `/data/nexus/etc/nexus.properties`. Do not place
the rendered secret file in the repository or terminal history.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nexus
sudo systemctl status nexus --no-pager
```

Wait for the local status API to return HTTP 200 before configuring the
repositories:

```bash
curl --fail --silent --show-error http://127.0.0.1:8081/service/rest/v1/status
```

## 4. Set the admin account and security settings

On first start, Nexus writes its initial password to
`/data/nexus/admin.password`. Use it once to set the chosen admin password
from a protected prompt or secret store. Do not print either password.
The API steps and accepted response codes are in `tasks/configure.yml`:

1. Confirm the configured admin user has the `nx-admin` role.
2. Set active realms to `NexusAuthenticatingRealm` followed by
   `DockerToken`.
3. Read and accept the Community Edition EULA.
4. Enable anonymous reads for APT and Docker if
   `nexus_anonymous_access` is true.
5. Re-encrypt stored secrets with the configured key ID.
6. Confirm the default encryption-key health check is healthy.

Use the published REST paths in `tasks/configure.yml`. The Community
Edition does not expose the public Cleanup Policies REST resource; do not
use an undocumented `/service/rest/internal/` endpoint.

## 5. Create the proxy repositories and cleanup policies

Read `tasks/repositories.yml` before running the playbook against an
existing Nexus instance: its current first step deletes **every** existing
repository, then recreates the proxies in vars. The manual path below
describes those declared proxies; keep unrelated hosted or proxy
repositories backed up before any Ansible deployment.

Create the APT proxies listed in `nexus_apt_proxy_repositories` in
`vars/nexus.yml`. This includes Debian bookworm/trixie, Ubuntu
noble/resolute, their updates/security/backports where listed, and the
Docker CE stable proxies. Create the Docker Hub proxy `docker-hub` on
HTTP 8082. Every proxy has `autoBlock: false` because a missing optional
translation index must not disable a shared repository.

Follow `tasks/repositories.yml` for the repository formats, components,
distributions, remote URLs, and Docker proxy connector. Attach the
30-day cleanup policies to proxy caches only. The playbook uses its
published Script API helper in `files/ensure_cleanup_policies.groovy`,
then turns script creation off again. Do not leave
`nexus.scripts.allowCreation=true`.

Check the repository list through the REST API or UI. Confirm all expected
proxies exist, are online, have auto-block disabled, and the cleanup
policies apply only to the APT and Docker Hub proxy caches.

## 6. Verify service access

From the Nexus guest, check local status and admin sign-in. If the guest
is on an isolated libvirt network, check on loopback; the control host may
not have an HTTP route to the guest:

```bash
curl --fail --silent --show-error http://127.0.0.1:8081/service/rest/v1/status
ss -lnt | grep -E ':(8081|8082)\b'
systemctl --failed
```

From a client allowed by the host firewall, fetch a package index through
`http://NEXUS_HOST:8081/repository/REPOSITORY_NAME/` and test Docker Hub
pulls through `NEXUS_HOST:8082`. Allow TCP 8081 and 8082 only from the
networks that need the cache.

For repeatable changes, use the Ansible project. It verifies the archive,
keeps configuration in the tracked vars/templates, and reconciles the
proxy set without downloading the archive on every guest run.
