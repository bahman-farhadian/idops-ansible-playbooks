# nexus-repository-systemd

Install Sonatype Nexus Repository Manager 3 as a systemd service. This
is not a Docker container.

The host can be Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04.

## What it installs

- Nexus on systemd, data directory `/data/nexus` (that path must be a
  mounted disk)
- HTTP **8081** for the web UI and APT proxies
- HTTP **8082** for a Docker Hub reverse proxy
- APT proxy repositories for Debian (bookworm, trixie) and Ubuntu
  (noble, resolute), including updates/security (and Ubuntu backports)
- Cleanup policies on those **proxy caches only**: keep up to 30 days.
  A hosted/private Docker registry is out of scope.

The version is pinned in `vars/nexus.yml` (`nexus_version` and
`nexus_download_checksum`). The web UI may show a newer build. To
change version, edit those two values (links are in the comments of
that file) and run `make deploy`.

## Local settings

You must pass a `*.local.yml` file. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
```

Put the real host in `nexus_targets`. Set `nexus_admin_password` and
`nexus_secrets_key` (`openssl rand -base64 32`) in that file. Do not
put them in tracked vars.

Web UI user is `admin`. Sign in from the user icon at the top right.

## Commands

```bash
make help
make ping LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml
```

`make deploy` installs the service, sets the admin password, accepts
the Community EULA, writes the encryption key, creates the APT and
Docker Hub proxy repositories, and attaches the 30-day cleanup
policies.

The host firewall must allow TCP 8081 and 8082 from the networks that
should use the cache.

APT clients use:

`http://<nexus-host>:8081/repository/<repo-name>`

Docker clients use `<nexus-host>:8082`.
