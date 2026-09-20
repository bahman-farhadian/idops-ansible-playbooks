# debian-based-os-hardening

Debian/Ubuntu hardening project migrated from:
`old_playbooks/debian-based-hardening-ansible`

This project follows repository standards:

- Single top-level entrypoint: `playbook.yml`
- Workflow logic in `tasks/`
- User-editable settings in `vars/debian-hardening.yml`
- One Makefile UX with `make help` and `make ping`

## Supported Targets

- Debian 12
- Debian 13
- Ubuntu 22.04
- Ubuntu 24.04

## Project Layout

- `playbook.yml`
- `tasks/` (`preflight.yml`, `ping.yml`, `scan.yml`, `harden.yml`, `reboot.yml`,
  `ssh-check.yml`, `runtime-check.yml`)
- `roles/` (migrated hardening and Lynis roles)
- `vars/debian-hardening.yml`
- `host.yml`
- `ansible.cfg`
- `requirements.txt`
- `Makefile`

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

Tracked files in `vars/` carry generic defaults. The playbook refuses to run
without a `*.local.yml` file (default `vars/settings.local.yml`), generated
by `make settings`. Targets are declared there, not in `host.yml`: `host.yml`
is a static, empty placeholder, and real hosts are added to the
`hardening_targets` inventory group dynamically at runtime, the same pattern
`kvm-vm-provisioning` uses for its hypervisor fleet. Never hand-edit
`host.yml` with a real host's address, user or password - that would put
real infrastructure data in a tracked file. Do not use `--limit` / `LIMIT=`
to pick a subset of hosts; keep a second local file for that job:

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

Leave `become_password` empty when connecting as root or when sudo is
passwordless on that host.

## Primary User Rename (Cloud Images)

Cloud images often start with a default user (for example `debian`) that is actively used by the SSH session.
Renaming that same active account in one pass can fail with:
`usermod: user <name> is currently used by process ...`.

Recommended two-pass flow:

1. First pass (bootstrap with default user):
   - Keep `prep_primary_user_desired_name` empty (or equal to current cloud user).
   - Run `make harden` with the target's `user` in `debian_hardening_targets`
     (`vars/settings.local.yml`) set to the default cloud user.
2. Second pass (rename from root session):
   - Set `prep_primary_user_desired_name` to the final username (for example `idops`).
   - Set that target's `user` to `root` and `port` to the hardened SSH port
     (default `2222`) in `debian_hardening_targets`.
   - Run `make harden` again.

Notes:

- If you plan to use root SSH for pass two, ensure root SSH is allowed and root has an authorized key (`prep_root_authorized_keys`).
- If root login shows `Please login as the user "debian" rather than the user "root".`, your image/provider still enforces default-user-only SSH. Complete pass one first, then enable root SSH access through this playbook settings and rerun.

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
make scan LOCAL_SETTINGS_FILE=vars/settings.local.yml
make harden LOCAL_SETTINGS_FILE=vars/settings.local.yml
make reboot LOCAL_SETTINGS_FILE=vars/settings.local.yml
```

`scan` and `harden` are explicit, separate workflows.

## Firewall: Trusting Your Private Network

The default firewall policy drops everything not explicitly allowed, which
also blocks other hosts on your own LAN or libvirt guest network unless they
happen to be reaching an allowed port. Set
`firewall_allow_private_networks: true` in `vars/settings.local.yml` to
accept all traffic (any port, any protocol) from RFC1918 IPv4 ranges
(`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) and IPv6 ULA
(`fc00::/7`), without needing to list ports one at a time. Traffic from
outside those ranges is unaffected and still has to go through the normal
SSH/port allow-lists.

## Dist-Upgrade Network Retry Controls

`package_hardening` uses bounded APT network timeouts and retries for `dist-upgrade`.
Override these in `vars/debian-hardening.yml` when needed:

- `package_hardening_apt_network_timeout_seconds` (default `120`)
- `package_hardening_apt_network_retries` (default `2`)
- `package_hardening_dist_upgrade_task_retries` (default `2`)
- `package_hardening_dist_upgrade_task_retry_delay_seconds` (default `15`)

## Offline Lynis Bundle Mode

For targets without internet access, enable offline Lynis delivery in `vars/debian-hardening.yml`:

- `lynis_offline_bundle_from_control_node: true`
- `lynis_control_cache_dir: "{{ playbook_dir }}/artifacts/cache/lynis"`

Behavior in offline mode:

- Control node clones/updates Lynis from `lynis_repo_url`.
- Control node creates commit-tagged tarball bundles in temp cache:
  - `lynis-<commit>.tar.gz`
- Bundle is copied to each target under `/tmp/` and extracted to `lynis_install_path`.
- Existing bundles are reused by commit name, so unchanged commits are not re-bundled.

## Artifacts

Lynis reports are collected under:

- `artifacts/lynis/<hostname>/`

## Secrets

Sensitive values (for example the GRUB password, `grub_password_plaintext`)
are settings like any other: generate `vars/settings.local.yml` with
`make settings` and set them there. That file is git-ignored, so nothing
sensitive is ever committed.
