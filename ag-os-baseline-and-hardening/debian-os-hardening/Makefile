.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help settings require-venv deps-bundle lint check ping scan harden reboot score suggestions ssh-check gap-report runtime-check \
        roles \
        role-network-identity role-boot-hardening role-grub-hardening role-prep-baseline role-common-repos \
        role-package-hardening role-service-hardening role-firewall role-kernel-hardening role-auth-hardening \
        role-banner-hardening role-ssh-hardening role-fail2ban role-auditd role-accounting-hardening \
        role-integrity-hardening role-compiler-hardening role-file-permissions role-session-logging

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= host.yml
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
LIMIT ?=
GROUP ?= hardening_targets
FORKS ?=
TAGS ?=
SKIP_TAGS ?=
EXTRA_VARS ?=
CHECK ?= false
DIFF ?= false
EXTRA_ARGS ?=
HARDENING_VARS_FILE ?= vars/debian-hardening.yml
HARDENING_LOCAL_SECRETS_FILE ?= vars/local-secrets.yml
LOCAL_SETTINGS_FILE ?= vars/settings.local.yml
FORCE ?=

BOOL_TRUE := 1 true yes TRUE YES

LIMIT_ARG := $(if $(LIMIT),-l $(LIMIT),)
FORKS_ARG := $(if $(FORKS),--forks $(FORKS),)
TAGS_ARG := $(if $(TAGS),--tags $(TAGS),)
SKIP_TAGS_ARG := $(if $(SKIP_TAGS),--skip-tags $(SKIP_TAGS),)
EXTRA_VARS_ARG := $(if $(EXTRA_VARS),-e "$(EXTRA_VARS)",)
CHECK_ARG := $(if $(filter $(CHECK),$(BOOL_TRUE)),--check,)
DIFF_ARG := $(if $(filter $(DIFF),$(BOOL_TRUE)),--diff,)
PLAY_ARGS := $(LIMIT_ARG) $(FORKS_ARG) $(TAGS_ARG) $(SKIP_TAGS_ARG) $(EXTRA_VARS_ARG) $(CHECK_ARG) $(DIFF_ARG) $(EXTRA_ARGS)
ADHOC_ARGS := $(LIMIT_ARG) $(FORKS_ARG) $(EXTRA_ARGS)
ADHOC_VARS_ARGS := -e @$(HARDENING_VARS_FILE) $(if $(wildcard $(HARDENING_LOCAL_SECRETS_FILE)),-e @$(HARDENING_LOCAL_SECRETS_FILE),)

help:
	@printf "Available targets:\n"
	@printf "  %-24s %s\n" "make help" "show this help"
	@printf "  %-24s %s\n" "(venv)" "shared env: create once at the repository root (make venv)"
	@printf "  %-24s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-24s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-24s %s\n" "make lint" "run ansible-lint"
	@printf "  %-24s %s\n" "make settings" "create vars/settings.local.yml for this machine"
	@printf "  %-24s %s\n" "make ping" "test connectivity to hardening targets"
	@printf "  %-24s %s\n" "make scan" "run Lynis baseline scan workflow"
	@printf "  %-24s %s\n" "make harden" "run Debian/Ubuntu hardening workflow"
	@printf "  %-24s %s\n" "make reboot" "reboot hardening targets"
	@printf "  %-24s %s\n" "make score" "show Lynis hardening_index values"
	@printf "  %-24s %s\n" "make suggestions" "show Lynis suggestions from collected reports"
	@printf "  %-24s %s\n" "make ssh-check" "inspect effective sshd hardening settings"
	@printf "  %-24s %s\n" "make gap-report" "show focused Lynis warning/suggestion gaps"
	@printf "  %-24s %s\n" "make runtime-check" "collect runtime state diagnostics from targets"
	@printf "\nPer-role targets (run a single role from the harden workflow):\n"
	@printf "  %-32s %s\n" "make roles" "list all available role targets"
	@printf "  %-32s %s\n" "make role-network-identity" "apply network_identity role only"
	@printf "  %-32s %s\n" "make role-boot-hardening" "apply boot_hardening role only"
	@printf "  %-32s %s\n" "make role-grub-hardening" "apply grub_hardening role only"
	@printf "  %-32s %s\n" "make role-prep-baseline" "apply prep_baseline role only"
	@printf "  %-32s %s\n" "make role-common-repos" "apply common_repos role only"
	@printf "  %-32s %s\n" "make role-package-hardening" "apply package_hardening role only"
	@printf "  %-32s %s\n" "make role-service-hardening" "apply service_hardening role only"
	@printf "  %-32s %s\n" "make role-firewall" "apply firewall role only"
	@printf "  %-32s %s\n" "make role-kernel-hardening" "apply kernel_hardening role only"
	@printf "  %-32s %s\n" "make role-auth-hardening" "apply auth_hardening role only"
	@printf "  %-32s %s\n" "make role-banner-hardening" "apply banner_hardening role only"
	@printf "  %-32s %s\n" "make role-ssh-hardening" "apply ssh_hardening role only"
	@printf "  %-32s %s\n" "make role-fail2ban" "apply fail2ban role only"
	@printf "  %-32s %s\n" "make role-auditd" "apply auditd role only"
	@printf "  %-32s %s\n" "make role-accounting-hardening" "apply accounting_hardening role only"
	@printf "  %-32s %s\n" "make role-integrity-hardening" "apply integrity_hardening role only"
	@printf "  %-32s %s\n" "make role-compiler-hardening" "apply compiler_hardening role only"
	@printf "  %-32s %s\n" "make role-file-permissions" "apply file_permissions_hardening role only"
	@printf "  %-32s %s\n" "make role-session-logging" "apply session_logging role only"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_or_group>" "limit inventory scope"
	@printf "  %-28s %s\n" "GROUP=<inventory_group>" "target inventory group for ad-hoc checks"
	@printf "  %-28s %s\n" "FORKS=<n>" "set Ansible fork parallelism"
	@printf "  %-28s %s\n" "TAGS=<tag1,tag2>" "run only selected tags"
	@printf "  %-28s %s\n" "SKIP_TAGS=<tag1,tag2>" "skip selected tags"
	@printf "  %-28s %s\n" "EXTRA_VARS='k=v ...'" "pass extra vars"
	@printf "  %-28s %s\n" "CHECK=true" "enable Ansible --check"
	@printf "  %-28s %s\n" "DIFF=true" "enable Ansible --diff"
	@printf "  %-28s %s\n" "EXTRA_ARGS='<raw args>'" "pass raw ansible args"

settings:
	@if [ ! -f "$(LOCAL_SETTINGS_FILE)" ] || [ "$(FORCE)" = "1" ]; then \
		$(PYTHON) $(PROJECT_ROOT)/scripts/generate-local-settings.py \
			--vars-dir vars --output "$(LOCAL_SETTINGS_FILE)" \
			$(if $(filter 1,$(FORCE)),--force,); \
	else \
		$(PYTHON) $(PROJECT_ROOT)/scripts/generate-local-settings.py \
			--vars-dir vars --output "$(LOCAL_SETTINGS_FILE)"; \
	fi

require-venv:
	@test -f "$(VENV)/bin/activate" || { \
		echo "Shared Python venv not found at $(VENV)."; \
		echo "Create it once from the repository root with: make venv"; \
		exit 1; \
	}

deps-bundle: require-venv
	$(VENV_ACTIVATE) && pip download -r $(PROJECT_ROOT)/requirements.txt -d $(WHEELHOUSE)

lint: require-venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --syntax-check

ping: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=ping $(PLAY_ARGS)

scan: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=scan $(PLAY_ARGS)

harden: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden $(PLAY_ARGS)

reboot: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=reboot $(PLAY_ARGS)

score:
	@grep '^hardening_index=' artifacts/lynis/*/lynis-report.dat || true

suggestions:
	@grep '^suggestion\[\]=' artifacts/lynis/*/lynis-report.dat || true

ssh-check: require-venv
	$(VENV_ACTIVATE) && ansible -i $(INVENTORY) $(ADHOC_ARGS) $(ADHOC_VARS_ARGS) $(GROUP) -b -m shell -a "sshd -T | egrep 'permitrootlogin|passwordauthentication|banner|printmotd|printlastlog|loglevel|maxauthtries|maxsessions'"

gap-report:
	@grep -E '^hardening_index=|^warning\[]=|^suggestion\[]=|^details\[]=(KRNL-6000|SSH-7408|FIRE-4513|NETW-2705|NAME-4028|NAME-4404|LOGG-2154|BOOT-5122|FILE-6310|PKGS-7346|ACCT-9630)' artifacts/lynis/*/lynis-report.dat || true

runtime-check: require-venv
	$(VENV_ACTIVATE) && ansible -i $(INVENTORY) $(ADHOC_ARGS) $(ADHOC_VARS_ARGS) $(GROUP) -b -m shell -a "echo '== sshd -T =='; sshd -T | egrep 'port|permitrootlogin|passwordauthentication|banner|printmotd|printlastlog|maxauthtries|maxsessions|loglevel'; echo '== issue.net =='; sed -n '1,120p' /etc/issue.net; echo '== pam_motd refs =='; grep -n pam_motd /etc/pam.d/sshd || true; echo '== ssh command hook =='; ls -l /etc/profile.d/99-ssh-command-logging.sh 2>/dev/null || true; echo '== rsyslog ssh logging =='; sed -n '1,200p' /etc/rsyslog.d/30-ssh-session-logging.conf 2>/dev/null || true; echo '== last ssh command logs =='; tail -n 20 /var/log/ssh_commands.log 2>/dev/null || true; echo '== firewall v4 =='; iptables -S; echo '== firewall v6 =='; ip6tables -S; echo '== dns =='; cat /etc/resolv.conf; echo '== hosts =='; cat /etc/hosts; echo '== sysctl =='; sysctl fs.protected_fifos kernel.modules_disabled; echo '== audit rules =='; auditctl -l || true; echo '== residual rc packages =='; dpkg -l | awk '/^rc/{print $$2}'"

# ── Per-role targets ──────────────────────────────────────────────────────────
# Each target runs the full harden workflow scoped to a single role via --tags.
# Accepts all standard runtime options: LIMIT, FORKS, CHECK, DIFF, EXTRA_ARGS.

roles:
	@printf "Available role targets:\n"
	@printf "  make role-network-identity\n"
	@printf "  make role-boot-hardening\n"
	@printf "  make role-grub-hardening\n"
	@printf "  make role-prep-baseline\n"
	@printf "  make role-common-repos\n"
	@printf "  make role-package-hardening\n"
	@printf "  make role-service-hardening\n"
	@printf "  make role-firewall\n"
	@printf "  make role-kernel-hardening\n"
	@printf "  make role-auth-hardening\n"
	@printf "  make role-banner-hardening\n"
	@printf "  make role-ssh-hardening\n"
	@printf "  make role-fail2ban\n"
	@printf "  make role-auditd\n"
	@printf "  make role-accounting-hardening\n"
	@printf "  make role-integrity-hardening\n"
	@printf "  make role-compiler-hardening\n"
	@printf "  make role-file-permissions\n"
	@printf "  make role-session-logging\n"

role-network-identity: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags network_identity $(PLAY_ARGS)

role-boot-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags boot_hardening $(PLAY_ARGS)

role-grub-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags grub_hardening $(PLAY_ARGS)

role-prep-baseline: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags prep_baseline $(PLAY_ARGS)

role-common-repos: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags common_repos $(PLAY_ARGS)

role-package-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags package_hardening $(PLAY_ARGS)

role-service-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags service_hardening $(PLAY_ARGS)

role-firewall: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags firewall $(PLAY_ARGS)

role-kernel-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags kernel_hardening $(PLAY_ARGS)

role-auth-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags auth_hardening $(PLAY_ARGS)

role-banner-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags banner_hardening $(PLAY_ARGS)

role-ssh-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags ssh_hardening $(PLAY_ARGS)

role-fail2ban: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags fail2ban $(PLAY_ARGS)

role-auditd: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags auditd $(PLAY_ARGS)

role-accounting-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags accounting_hardening $(PLAY_ARGS)

role-integrity-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags integrity_hardening $(PLAY_ARGS)

role-compiler-hardening: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags compiler_hardening $(PLAY_ARGS)

role-file-permissions: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags file_permissions_hardening $(PLAY_ARGS)

role-session-logging: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags session_logging $(PLAY_ARGS)
