# debian-based-os-hardening

Debian/Ubuntu hardening project migrated from:
`old_playbooks/debian-based-hardening-ansible`

How this project is laid out:

- One playbook: `playbook.yml`
- Tasks in `tasks/`
- Safe defaults in `vars/debian-hardening.yml`
- Real hosts and keys in a named `*.local.yml` file (you must pass it; there is no default)
- Run it with `make help` and `make ping`

## Supported Targets

- Debian 12
- Debian 13
- Ubuntu 22.04
- Ubuntu 24.04
- Ubuntu 26.04

## Project Layout

- `playbook.yml`
- `tasks/` (`preflight.yml`, `ping.yml`, `scan.yml`, `harden.yml`, `reboot.yml`,
  `ssh-check.yml`, `runtime-check.yml`)
- `roles/` (hardening and Lynis roles)
- `vars/debian-hardening.yml`
- `host.yml` (empty on purpose; do not put real hosts here)
- `ansible.cfg`
- `Makefile`
- `<repository-root>/requirements.txt` (shared pinned dependencies)

## Quick Start

```bash
cd ag-os-baseline-and-hardening/debian-based-os-hardening
make venv
make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml
# edit the real values that file just wrote
# for a second deployment: make settings LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml
make check LOCAL_SETTINGS_FILE=vars/settings.local.yml
make ping LOCAL_SETTINGS_FILE=vars/settings.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.local.yml
```

## Inventory

Tracked files in `vars/` have safe generic defaults. They do not name your
real machines.

You must pass a `*.local.yml` file on every run. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml
```

Put hosts in that file, not in `host.yml`. `host.yml` stays empty. The
playbook adds hosts to the `hardening_targets` group at runtime.

Do not use `--limit`. For a second set of hosts, use a second file:

```bash
make harden LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml
```

Set `debian_hardening_targets` in the selected local file, one list entry
per host:

```yaml
debian_hardening_targets:
  - name: "web-01"          # Inventory hostname.
    address: "203.0.113.10" # SSH target host/IP. Falls back to name if omitted.
    user: "idops"           # SSH user for this host.
    port: 22                # SSH port. Falls back to 22 if omitted.
    become_password: ""     # Optional per-host sudo password.
```

Leave `become_password` empty if you connect as root, or if sudo does not
ask for a password.

## Primary User Rename (Cloud Images)

Guests should first-boot as `idops` (set `kvm_default_cloud_init_user`
in kvm-vm-provisioning). Do not use the vendor cloud users `debian` or
`ubuntu`.

Renaming the same account that is logged in can fail with:
`usermod: user <name> is currently used by process ...`.

Recommended two-pass flow:

1. First pass (bootstrap as `idops`):
   - Set `prep_primary_user_desired_name` to `idops` (the tracked default).
   - Run `make harden` with the target's `user` in `debian_hardening_targets`
     set to `idops` on port 22.
2. Second pass (finish from a root session):
   - Keep `prep_primary_user_desired_name` as `idops`.
   - Set that target's `user` to `root` and `port` to the hardened SSH port
     (default `2222`) in `debian_hardening_targets`.
   - Run `make harden` again.

Notes:

- If you plan to use root SSH for pass two, ensure root SSH is allowed and root has an authorized key (`prep_root_authorized_keys`).
- If root login shows `Please login as the user "idops"` rather than root, complete pass one first, then enable root SSH through this playbook and rerun.
- Ubuntu 24.04+ often uses `ssh.socket`. Pass one stops that unit so
  `sshd_config` `Port` (shipped default `2222`) is the listener.
- After pass one, ping on port 22 fails. Pass two uses the hardened port.

## Terminal Dotfiles

The primary user (and, by default, root) get a shared tmux/vim/bash setup,
adopted from
[linux_terminal_dotfiles_configuration](https://github.com/bahman-farhadian/linux_terminal_dotfiles_configuration).
Only the parts shared across every machine in that repository were brought
over — the source project documents itself as three per-host configurations,
not a distributable package, so this is a deliberate subset. Ownership is
split across two roles because each already owned part of this ground:

- **`prep_baseline`** deploys `.bash_profile`, `.bash_aliases` and `.bashrc`
  in full — a Gruvbox prompt (git branch/status, venv, exit code), automatic
  tmux session handling over SSH, extended history settings, and CLI
  completions (kubectl, helm, docker, tmux, vendored from
  [tmux-bash-completion](https://github.com/imomaliev/tmux-bash-completion)
  since Debian ships none). These three files are replaced outright on every
  run rather than templated from a handful of configurable aliases/prompt
  lines, so this fully replaces `prep_baseline`'s previous, much smaller
  aliases-and-prompt setup; a manual edit on the target does not survive the
  next hardening run (`backup: true` keeps a timestamped copy of whatever
  was there first). It also appends the source project's SSH *client*
  defaults (`StrictHostKeyChecking no`, `UserKnownHostsFile /dev/null`) to
  `~/.ssh/config` as a marked block at the end of the file, the same way the
  source project's own installer does — never a full replace, since ssh
  takes the first value it finds for each keyword and a personal `Host`
  entry has to stay above these defaults to win. This is a deliberate
  trade-off for a homelab of frequently rebuilt VMs: it removes MITM
  protection on outbound SSH from this host.
- **`terminal_dotfiles`** deploys `.tmux.conf` as-is, and `.vimrc` with the
  Gruvbox colorscheme and the lightline/NERDTree plugins, installed as
  native Vim 8 packages (no plugin manager needed).

Deliberately **not** brought over, and left to the roles that already own
that ground:

- The SSH login banner and `/etc/motd` — `banner_hardening` sets these, and
  this project's own text, not the source repository's personal one.
- SSH server policy (`PermitRootLogin`, and similar) — `ssh_hardening` owns
  this. The adopted `~/.ssh/config` is a *client* default only; it has no
  effect on how this host's own sshd behaves.
- The one host-specific bash alias block (GNOME keyboard-layout switching on
  a single machine) and every other desktop-only piece (GNOME shortcuts,
  the keyboard-lock service, GTK theming) — none of it applies to a
  headless guest.

Toggle the tmux/vim half with `terminal_dotfiles_enabled` and
`terminal_dotfiles_configure_root` in `vars/debian-hardening.yml`, or run it
alone with `make role-terminal-dotfiles`. The bash half is part of
`prep_baseline`, toggled with `prep_enabled`.

## Main Commands

```bash
make ping LOCAL_SETTINGS_FILE=vars/settings.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.local.yml
make scan LOCAL_SETTINGS_FILE=vars/settings.local.yml
make reboot LOCAL_SETTINGS_FILE=vars/settings.local.yml
make ssh-check LOCAL_SETTINGS_FILE=vars/settings.local.yml
make runtime-check LOCAL_SETTINGS_FILE=vars/settings.local.yml
make score
make suggestions
make gap-report
```

`make scan` and `make harden` are separate. `make scan` fails if the Lynis
score is below `lynis_min_hardening_index` (default `86`).

`make score`, `make suggestions`, and `make gap-report` only read files in
`artifacts/lynis/`. They do not need `LOCAL_SETTINGS_FILE`.

`make runtime-check` prints live SSH and firewall state. It fails if UFW is
still installed, leftover UFW paths exist, cloud-init sudoers is still
there, cloud-init is still enabled, or SMTP listens on `0.0.0.0:25`.

`make role-firewall` (and other `make role-*` targets) run only that role.
You still must pass `LOCAL_SETTINGS_FILE`.

## Firewall

This project uses iptables (`iptables-persistent`). It does not use UFW.

By default (`firewall_purge_ufw: true`) it removes the UFW package and these
leftover paths: `/etc/ufw`, `/etc/default/ufw`, `/var/lib/ufw`.

Fail2ban uses iptables on `ssh_port` (default `2222`).

INPUT and FORWARD default to DROP. `firewall_allow_private_networks` is
`true`: hosts on private IPv4 (`10.0.0.0/8`, `172.16.0.0/12`,
`192.168.0.0/16`) and IPv6 ULA (`fc00::/7`) can reach any port. Set it to
`false` in your local file if those hosts must use the SSH and port lists
instead.

## Cloud-init and mail

By default (`prep_disable_cloud_init: true`) the playbook turns cloud-init
off after first boot. It writes `/etc/cloud/cloud-init.disabled`, masks the
units, and removes `/etc/sudoers.d/90-cloud-init-users` after the primary
sudoers file exists. If cloud-init stays on, it can rewrite sudoers on the
next boot.

By default (`service_hardening_bind_mta_loopback: true`) Postfix/Exim listen
on loopback only. Ubuntu Postfix starts listening on all addresses; the role
restarts Postfix so the change takes effect (reload is not enough). Debian
Exim is usually already loopback-only.

## Dist-Upgrade Network Retry Controls

`package_hardening` uses bounded APT network timeouts and retries for `dist-upgrade`.
Override these in `vars/debian-hardening.yml` when needed:

- `package_hardening_apt_network_timeout_seconds` (default `120`)
- `package_hardening_apt_network_retries` (default `2`)
- `package_hardening_dist_upgrade_task_retries` (default `2`)
- `package_hardening_dist_upgrade_task_retry_delay_seconds` (default `15`)

## Offline Lynis Bundle Mode

Lynis is cloned once on the machine that runs `make`, then copied to
each guest. That is the default (`lynis_offline_bundle_from_control_node: true`).

- `lynis_control_cache_dir: "{{ playbook_dir }}/artifacts/cache/lynis"`

Behavior:

- Control node clones/updates Lynis from `lynis_repo_url`.
- Control node creates commit-tagged tarball bundles:
  - `lynis-<commit>.tar.gz`
- Bundle is copied to each target under `/var/tmp/` and extracted to `lynis_install_path`.
- Existing bundles are reused by commit name, so unchanged commits are not re-bundled.

## Artifacts

Lynis reports are collected under:

- `artifacts/lynis/<hostname>/`

## Secrets

Secrets (for example the GRUB password, `grub_password_plaintext`) go in a
named `*.local.yml` file:

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml
```

That file is gitignored. Do not put secrets in tracked files.
