# docker-engine

Install Docker Engine on one host and leave Swarm off. A host that is
already a Swarm member keeps that membership. This playbook does not
initialize a cluster. Use `ai-container-orchestration/docker-swarm` for
that, after this engine is installed with `live_restore: false`.

The host can be Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04,
and the CPU must be x86_64. Deploy gathers host facts, prints that
release, and refuses any other guest.

## What it installs

Pinned from `vars/docker-engine.yml`:

- `docker-ce` and `docker-ce-cli` `29.8.1`
- `containerd.io` `2.3.5`
- `docker-buildx-plugin` `0.37.1`
- `docker-compose-plugin` `5.5.1`

That set is the newest Docker CE stable build published for bookworm,
trixie, noble, and resolute at the time of the pin. The guest installs
it from a Nexus apt proxy. Deploy does not contact `download.docker.com`.
The signing key shipped in `files/docker.asc` is Docker's apt key,
fingerprint `9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88`.

Before the first deploy, publish one Nexus apt proxy per suite. The
proxy caches Docker's stable component and keeps Docker's signature.

| Suite | Upstream | Nexus repository name to use |
| --- | --- | --- |
| bookworm | `https://download.docker.com/linux/debian` | `docker-ce-debian-bookworm` |
| trixie | `https://download.docker.com/linux/debian` | `docker-ce-debian-trixie` |
| noble | `https://download.docker.com/linux/ubuntu` | `docker-ce-ubuntu-noble` |
| resolute | `https://download.docker.com/linux/ubuntu` | `docker-ce-ubuntu-resolute` |

Distribution equals the suite. Component is `stable`. Put each proxy
URL in `docker_engine_apt_uris`.

Deploy also:

- Formats an unformatted data disk as XFS and mounts it at `/docker`
  (`ftype=1`, `uquota`, `pquota`). The disk must not be the root disk.
- Copies an existing `/var/lib/docker` tree onto that disk when the
  engine was already installed somewhere else.
- Writes `/etc/docker/daemon.json` (`overlay2`, `icc` false,
  `no-new-privileges` true, json-file logs `10m` / 3 files).
  `registry-mirrors` is the Nexus Docker Hub proxy from
  `docker_engine_registry_mirrors`. Docker Hub image pulls use that
  proxy. An HTTP mirror is also added to `insecure-registries`.
- Holds the five packages so a later apt upgrade cannot move them.
- Sends dockerd syslog to `/var/log/docker`.

`live_restore` defaults to true. Set `live_restore: false` on a host
that will join a Swarm, and do that on the first deploy.

To move the pin, edit `vars/docker-engine.yml` only after the same
upstream versions exist for all four suites, then run `make deploy`.
Deploy installs that version. It does not install whatever apt calls
latest.

`make restart` restarts dockerd so the `DOCKER` and `DOCKER-USER`
chains come back after a host firewall reload. It does not reformat
the disk and it does not leave or join a Swarm.

## Local settings

You must pass a `*.local.yml` file. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.docker-engine.local.yml
```

Put real hosts in `docker_engine_targets`. Set `data_disk` to the
extra disk (`/dev/vdb` or a `/dev/disk/by-id/` path). Leave that disk
unformatted. An empty `data_disk` is used only when the host has
exactly one non-root disk with no signature.

Do not put real addresses in tracked vars.

## Commands

```bash
make help
make ping LOCAL_SETTINGS_FILE=vars/settings.docker-engine.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.docker-engine.local.yml
make restart LOCAL_SETTINGS_FILE=vars/settings.docker-engine.local.yml
```

`make deploy` runs one host at a time and stops at the first failure.
