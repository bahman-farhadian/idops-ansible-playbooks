# Manual OS hardening (no Ansible)

This is the same baseline as `make harden` in this directory, written as
shell commands so you can learn what each role does. Work as **root** on
Debian 12, Debian 13, Ubuntu 24.04, or Ubuntu 26.04. Copy files from this
git tree. Ansible is not required.

Tracked defaults live in `vars/debian-hardening.yml` and each role's
`defaults/main.yml`. The order below matches
`roles/os_hardening/tasks/main.yml`.

The role tasks and templates are the exact baseline. This walkthrough names
their destination files and values, but a `.j2` file is not ready to install
until its Jinja expressions have been rendered with the selected settings.
Use the chosen deployment's local settings for addresses, users, ports, and
policy overrides; do not copy real values into this repository. For daily
convergence and audit output, use the Ansible playbook.

Set this once (path to this playbook directory):

```bash
REPO=/path/to/idops-ansible-playbooks/ad-os-baseline-and-hardening/debian-based-os-hardening
```

If you are connected over SSH on port 22, do **not** restart `sshd` until
the SSH section, and keep a console or a second session. Pass one of the
Ansible playbook writes `Port 2222` while still on 22 and only restarts
when the run is already on 2222.

After every section, run the **Check** commands. Expected output is on
the next line.

---

## 0. Guest

```bash
. /etc/os-release
echo "$ID $VERSION_ID"
uname -m
```

Expect `debian 12`, `debian 13`, `ubuntu 24.04`, or `ubuntu 26.04`, and
`x86_64` or `amd64`.

---

## 1. Network identity (`network_identity`)

Set the short hostname. Use `hostnamectl` (not `hostname` on a 1 GiB
guest: `/tmp` is tmpfs).

```bash
hostnamectl set-hostname "$(hostname -s)"
hostnamectl status
```

Expect `Static hostname:` equal to the short name.

Edit `/etc/hosts` so the primary IPv4 maps to that name. Do not use a
`.local` zone (systemd-resolved sends `.local` to mDNS).

```bash
getent hosts "$(hostname -s)"
```

Expect one IPv4 line.

---

## 2. Boot target (`boot_hardening`)

```bash
systemctl set-default multi-user.target
systemctl get-default
```

Expect `multi-user.target`.

On Debian 13 only:

```bash
systemctl enable --now systemd-update-utmp.service
systemctl enable --now systemd-update-utmp-runlevel.service
```

---

## 3. GRUB password (`grub_hardening`)

Skipped when `grub_password_plaintext` is empty (the tracked default).
To match a real local settings file, set a password, hash it, and write
`/etc/grub.d/01-idops-hardening` from
`roles/grub_hardening/templates/01-idops-hardening.j2`, then
`update-grub`.

```bash
grub-mkpasswd-pbkdf2
```

Expect a `grub.pbkdf2.sha512.` hash. Do not put that hash in git.

---

## 4. APT sources (`common_repos`)

Debian 12/13 uses deb822 under `/etc/apt/sources.list.d/debian.sources`.
Ubuntu 24.04/26.04 uses `/etc/apt/sources.list.d/ubuntu.sources`.
Templates: `roles/common_repos/templates/debian.sources.j2` and
`ubuntu.sources.j2`. Tracked URIs are the public archives. Optional
`apt_debian_repository_by_suite` / `apt_ubuntu_repository_by_suite` in a
local file point each suite at a cache (for example Nexus).

```bash
apt-get update
```

Expect `Reading package lists... Done` and no `404` on the suites you
enabled.

---

## 5. Baseline packages and cloud-init (`prep_baseline`)

```bash
apt-get install -y passwd sudo curl git rsync tmux tree vim wget jq net-tools duf ipcalc bash-completion btop
```

Optional: `lshw progress unrar sshuttle`.

Copy bash files from `roles/prep_baseline/files/` to `/root` and to the
primary user home (`idops`, UID 1000 by default):

```bash
install -m 0644 "$REPO/roles/prep_baseline/files/bashrc" /root/.bashrc
install -m 0644 "$REPO/roles/prep_baseline/files/bash_profile" /root/.bash_profile
install -m 0644 "$REPO/roles/prep_baseline/files/bash_aliases" /root/.bash_aliases
```

Repeat for `/home/idops` as user `idops:idops` if that account exists.

Disable cloud-init after first boot so it cannot rewrite sudoers:

```bash
touch /etc/cloud/cloud-init.disabled
systemctl mask cloud-init.service cloud-init-local.service cloud-config.service cloud-final.service
rm -f /etc/sudoers.d/90-cloud-init-users
```

Check:

```bash
test -f /etc/cloud/cloud-init.disabled && echo PASS
systemctl is-enabled cloud-init.service || true
test ! -e /etc/sudoers.d/90-cloud-init-users && echo PASS
```

Expect `PASS`, then `masked` or `not found`, then `PASS`.

---

## 6. zram swap (`zram_swap`)

Same policy as first-boot KVM: half of RAM, zstd, `vm.swappiness` 100.

On Ubuntu, install extra modules only if the module is missing:

```bash
modprobe -n zram || apt-get install -y "linux-modules-extra-$(uname -r)"
```

```bash
printf 'vm.swappiness=100\n' > /etc/sysctl.d/99-idops-zram-swappiness.conf
sysctl --system
printf 'PERCENT=50\nALGO=zstd\nPRIORITY=100\n' > /etc/default/idops-zram-swap
install -m 0755 "$REPO/roles/zram_swap/files/idops-zram-swap" /usr/local/sbin/idops-zram-swap
install -m 0644 "$REPO/roles/zram_swap/files/idops-zram-swap.service" /etc/systemd/system/idops-zram-swap.service
systemctl daemon-reload
systemctl reset-failed idops-zram-swap.service || true
systemctl enable --now idops-zram-swap.service
```

`systemctl restart` of this unit is a stop then a start (the helper
`hot_add`s a new `zram0`).

Check:

```bash
swapon --show
sysctl vm.swappiness
```

Expect a `zram` line and `vm.swappiness = 100`.

---

## 7. Terminal files (`terminal_dotfiles`)

Copy from `roles/terminal_dotfiles/files/` to `/root` and `/home/idops`:

- `.tmux.conf`
- `.vimrc` and `~/.vim/pack/dist/start/` (lightline, NERDTree, Gruvbox)
- `~/.config/btop/btop.conf` and `~/.config/btop/themes/gruvbox_dark_v2.theme`

```bash
grep 'color_theme' /root/.config/btop/btop.conf
```

Expect `color_theme = "gruvbox_dark_v2"`.

---

## 8. Packages (`package_hardening`)

```bash
apt-get install -y unattended-upgrades logrotate python3-systemd bsd-mailx
apt-get dist-upgrade -y
```

If `/sys/module/apparmor/parameters/enabled` is `Y`:

```bash
apt-get install -y apparmor apparmor-utils
systemctl enable --now apparmor.service
```

Purge leftover `rc` packages (`dpkg -l | awk '/^rc/{print $2}'`).

Check:

```bash
systemctl is-enabled unattended-upgrades
```

Expect `enabled`.

---

## 9. Service drop-ins (`service_hardening`)

For `ssh.service`, `fail2ban.service`, `rsyslog.service`, `cron.service`,
and `unattended-upgrades.service`, install
`/etc/systemd/system/<unit>.d/90-hardening.conf` from
`roles/service_hardening/templates/hardening-dropin.conf.j2`
(`NoNewPrivileges`, `PrivateTmp`, and the other Restrict* keys).

Bind MTA to loopback (Ubuntu Postfix defaults to all addresses):

```bash
postconf -e 'inet_interfaces = loopback-only' 2>/dev/null || true
systemctl restart postfix 2>/dev/null || true
ss -lnt | grep ':25' || true
```

Expect SMTP on `127.0.0.1:25` only, or no `:25` listener.

---

## 10. Firewall (`firewall`)

Ubuntu images ship UFW. This project owns the filter table with
iptables-persistent only.

```bash
systemctl stop ufw 2>/dev/null || true
apt-get purge -y ufw
rm -rf /etc/ufw /etc/default/ufw /var/lib/ufw
apt-get install -y iptables iptables-persistent netfilter-persistent
```

Write `/etc/iptables/rules.v4` from `roles/firewall/templates/rules.v4.j2`
with the tracked defaults: INPUT/FORWARD `DROP`, OUTPUT `ACCEPT`, loopback,
`ESTABLISHED,RELATED`, ICMP, RFC1918 (`10.0.0.0/8`, `172.16.0.0/12`,
`192.168.0.0/16`) because `firewall_allow_private_networks` is true, SSH
on **2222** (and **22** until you finish the SSH step), then `-A INPUT -j DROP`.
Leave FORWARD extra rules empty unless this host is a perimeter pair
(`tun-admin` → LAN plus LAN → WAN).

IPv6: `roles/firewall/templates/rules.v6.j2` (ULA `fc00::/7` when private
networks are on).

```bash
iptables-restore < /etc/iptables/rules.v4
ip6tables-restore < /etc/iptables/rules.v6
netfilter-persistent save
```

Check:

```bash
dpkg-query -W -f='${Status}\n' ufw 2>/dev/null || echo PASS
iptables -S | head
```

Expect no UFW package, then `-P INPUT DROP` and an SSH `--dport 2222` ACCEPT
(after the SSH step, 22 may go away).

---

## 11. Kernel sysctl (`kernel_hardening`)

Copy the map in `roles/kernel_hardening/defaults/main.yml`
(`kernel_sysctl_settings`) to `/etc/sysctl.d/99-zz-hardening.conf`.
Do **not** set `kernel.modules_disabled = 1` (tracked default is false;
it is one-way until reboot).

Blacklist `dccp sctp rds tipc` in
`/etc/modprobe.d/99-hardening-blacklist.conf`. Disable `usb-storage` and
FireWire storage as in the role templates.

```bash
sysctl --system
sysctl fs.protected_fifos kernel.kptr_restrict
```

Expect `fs.protected_fifos = 2` and `kernel.kptr_restrict = 2`.

---

## 12. Passwords (`auth_hardening`)

```bash
apt-get install -y libpam-pwquality
```

In `/etc/login.defs`: `PASS_MAX_DAYS 90`, `PASS_MIN_DAYS 1`,
`PASS_WARN_AGE 7`, `UMASK 027`, `SHA_CRYPT_MIN_ROUNDS 640000`,
`SHA_CRYPT_MAX_ROUNDS 640000`.

```bash
printf 'INACTIVE=30\n' >> /etc/default/useradd
# or replace the existing INACTIVE= line
```

PAM (`/etc/pam.d/common-password`):

```
password requisite pam_pwquality.so retry=3 minlen=14 difok=4
```

Apply aging to local users (UID ≥ 1000, plus root):

```bash
chage -M 90 -m 1 -W 7 idops
chage -M 90 -m 1 -W 7 root
chage -l idops
```

Expect `Maximum number of days between password change` = 90.

---

## 13. Banner (`banner_hardening`)

Write `/etc/issue` and `/etc/issue.net` from
`roles/banner_hardening/defaults/main.yml` (`banner_issue_text` /
`banner_issue_net_text`).

```bash
head -n 3 /etc/issue.net
```

Expect `AUTHORIZED SSH ACCESS ONLY`.

---

## 14. SSH (`ssh_hardening`)

Tracked port is **2222**. Install OpenSSH, disable `ssh.socket` on Ubuntu
so `sshd_config` `Port` wins, write
`/etc/ssh/sshd_config.d/99-zzz-idops-hardening.conf` from
`roles/ssh_hardening/templates/sshd_hardening.conf.j2`:

- `Port 2222`
- `PermitRootLogin prohibit-password`
- `PasswordAuthentication no`
- `PubkeyAuthentication yes`
- `MaxAuthTries 3`
- `Banner /etc/issue.net`

Ensure `/etc/ssh/sshd_config` has `Include /etc/ssh/sshd_config.d/*.conf`
at the top.

```bash
sshd -t
systemctl disable --now ssh.socket 2>/dev/null || true
systemctl reload ssh || systemctl reload sshd
sshd -T | egrep 'port|permitrootlogin|passwordauthentication'
ss -lnt | grep ':2222'
```

Expect `port 2222`, `permitrootlogin prohibit-password`,
`passwordauthentication no`, and a listener on 2222.

If this session is still on 22, open a **new** login on 2222 before you
close the old one.

---

## 15. Fail2ban (`fail2ban`)

```bash
apt-get install -y fail2ban
```

Write `/etc/fail2ban/jail.local` from
`roles/fail2ban/templates/jail.local.j2` with `port = 2222`,
`bantime = 1h`, `findtime = 10m`, `maxretry = 5`,
`banaction = iptables-multiport`.

```bash
systemctl enable --now fail2ban
fail2ban-client status sshd
```

Expect jail `sshd` and the filter running.

---

## 16. auditd (`auditd`)

```bash
apt-get install -y auditd audispd-plugins
install -m 0640 "$REPO/roles/auditd/templates/hardening.rules.j2" /etc/audit/rules.d/hardening.rules
```

Render the jinja (`{{ }}` lines) or copy the file after `make` has
already deployed it once. Then:

```bash
systemctl enable --now auditd
augenrules --load || true
auditctl -l | head
```

Expect rules, not an empty list.

---

## 17. Accounting (`accounting_hardening`)

```bash
apt-get install -y acct sysstat
sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat
systemctl enable --now sysstat
```

Check:

```bash
systemctl is-active sysstat
```

Expect `active`.

---

## 18. AIDE / rkhunter / chkrootkit (`integrity_hardening`)

```bash
apt-get install -y aide aide-common rkhunter chkrootkit
update-aide.conf || true
aideinit || true
```

Check:

```bash
dpkg -l aide rkhunter chkrootkit | awk '/^ii/'
```

Expect three `ii` lines.

---

## 19. Compilers (`compiler_hardening`)

Restrict compiler binaries to root:

```bash
chmod 0700 /usr/bin/gcc /usr/bin/g++ /usr/bin/cc /usr/bin/make /usr/bin/as /usr/bin/ld 2>/dev/null || true
ls -l /usr/bin/gcc /usr/bin/make
```

Expect `-rwx------` and owner `root`.

---

## 20. File modes (`file_permissions_hardening`)

```bash
chmod 0600 /etc/ssh/sshd_config /etc/crontab 2>/dev/null || true
chmod 0700 /etc/cron.d /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly 2>/dev/null || true
stat -c '%a %n' /etc/ssh/sshd_config
```

Expect `600 /etc/ssh/sshd_config`.

---

## 21. Session logs (`session_logging`)

```bash
apt-get install -y rsyslog
```

Write `/etc/rsyslog.d/30-ssh-session-logging.conf` from
`roles/session_logging/templates/ssh-session-rsyslog.conf.j2` with
`file="/var/log/ssh_sessions.log"` and the command hook on `local6` /
tag `ssh-command` into `/var/log/ssh_commands.log`. Copy
`roles/session_logging/templates/ssh-command-logging.sh.j2` to
`/etc/profile.d/99-ssh-command-logging.sh` (fill the jinja tag and
facility).

```bash
touch /var/log/ssh_sessions.log /var/log/ssh_commands.log
chown root:adm /var/log/ssh_sessions.log /var/log/ssh_commands.log
chmod 0640 /var/log/ssh_sessions.log /var/log/ssh_commands.log
systemctl restart rsyslog
test -f /etc/profile.d/99-ssh-command-logging.sh && echo PASS
```

Expect `PASS`. Remote forward stays off (`remote_syslog_enabled: false`).

---

## 22. Runtime check (same as `make runtime-check`)

```bash
sshd -T | egrep 'port|permitrootlogin|passwordauthentication'
iptables -S | head
test ! -e /etc/ufw && echo PASS_ufw
test -f /etc/cloud/cloud-init.disabled && echo PASS_cloud
ss -lnt | grep ':25' || echo PASS_smtp
swapon --show
```

Expect port 2222, no UFW path, cloud-init disabled, SMTP not on
`0.0.0.0:25`, and a zram swap line.

---

## 23. Lynis (same as `make scan`)

The playbook copies a control-node clone to `/opt/lynis`. By hand:

```bash
apt-get install -y git ca-certificates
git clone https://github.com/CISOfy/lynis /opt/lynis
cd /opt/lynis
./lynis audit system --quick
grep hardening_index /var/log/lynis-report.dat
```

Expect `hardening_index=` **86** or higher (`lynis_min_hardening_index`).
Save the report; `make score` only reads
`artifacts/lynis/<hostname>/` after an Ansible scan.

---

## What this file is not

It does not replace `make harden`. Templates with jinja still need values
filled in. Perimeter extras (`firewall_forward_ipv4_enabled`,
`tun-admin` → LAN) stay in that guest's local overlay. Do not put
passwords, keys, or live addresses in this file.
