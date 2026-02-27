.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv deps-bundle lint check ping scan harden reboot score suggestions ssh-check gap-report runtime-check

INVENTORY ?= host.yml
PLAYBOOK_FILE ?= playbook.yml
VENV ?= venv
WHEELHOUSE ?= wheelhouse
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
	@printf "  %-24s %s\n" "make venv" "create venv/ and install dependencies"
	@printf "  %-24s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-24s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-24s %s\n" "make lint" "run ansible-lint"
	@printf "  %-24s %s\n" "make ping" "test connectivity to hardening targets"
	@printf "  %-24s %s\n" "make scan" "run Lynis baseline scan workflow"
	@printf "  %-24s %s\n" "make harden" "run Debian/Ubuntu hardening workflow"
	@printf "  %-24s %s\n" "make reboot" "reboot hardening targets"
	@printf "  %-24s %s\n" "make score" "show Lynis hardening_index values"
	@printf "  %-24s %s\n" "make suggestions" "show Lynis suggestions from collected reports"
	@printf "  %-24s %s\n" "make ssh-check" "inspect effective sshd hardening settings"
	@printf "  %-24s %s\n" "make gap-report" "show focused Lynis warning/suggestion gaps"
	@printf "  %-24s %s\n" "make runtime-check" "collect runtime state diagnostics from targets"
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

$(VENV)/bin/activate:
	$(PYTHON) -m venv $(VENV)

$(VENV)/.deps.installed: requirements.txt $(VENV)/bin/activate
	$(PIP) install --upgrade pip
	@if find $(WHEELHOUSE) -maxdepth 1 -type f ! -name '.gitkeep' | grep -q .; then \
		echo "Installing dependencies from local wheelhouse/ cache"; \
		if ! $(PIP) install --no-index --find-links $(WHEELHOUSE) -r requirements.txt; then \
			echo "Wheelhouse cache is incomplete; falling back to remote package index"; \
			$(PIP) install -r requirements.txt; \
		fi; \
	else \
		echo "Installing dependencies from remote package index"; \
		$(PIP) install -r requirements.txt; \
	fi
	@touch $(VENV)/.deps.installed

venv: $(VENV)/.deps.installed

deps-bundle: venv
	$(VENV_ACTIVATE) && pip download -r requirements.txt -d $(WHEELHOUSE)

lint: venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --syntax-check

ping: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=ping $(PLAY_ARGS)

scan: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=scan $(PLAY_ARGS)

harden: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden $(PLAY_ARGS)

reboot: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=reboot $(PLAY_ARGS)

score:
	@grep '^hardening_index=' artifacts/lynis/*/lynis-report.dat || true

suggestions:
	@grep '^suggestion\[\]=' artifacts/lynis/*/lynis-report.dat || true

ssh-check: venv
	$(VENV_ACTIVATE) && ansible -i $(INVENTORY) $(ADHOC_ARGS) $(ADHOC_VARS_ARGS) $(GROUP) -b -m shell -a "sshd -T | egrep 'permitrootlogin|passwordauthentication|banner|printmotd|printlastlog|loglevel|maxauthtries|maxsessions'"

gap-report:
	@grep -E '^hardening_index=|^warning\[]=|^suggestion\[]=|^details\[]=(KRNL-6000|SSH-7408|FIRE-4513|NETW-2705|NAME-4028|NAME-4404|LOGG-2154|BOOT-5122|FILE-6310|PKGS-7346|ACCT-9630)' artifacts/lynis/*/lynis-report.dat || true

runtime-check: venv
	$(VENV_ACTIVATE) && ansible -i $(INVENTORY) $(ADHOC_ARGS) $(ADHOC_VARS_ARGS) $(GROUP) -b -m shell -a "echo '== sshd -T =='; sshd -T | egrep 'port|permitrootlogin|passwordauthentication|banner|printmotd|printlastlog|maxauthtries|maxsessions|loglevel'; echo '== issue.net =='; sed -n '1,120p' /etc/issue.net; echo '== pam_motd refs =='; grep -n pam_motd /etc/pam.d/sshd || true; echo '== ssh command hook =='; ls -l /etc/profile.d/99-ssh-command-logging.sh 2>/dev/null || true; echo '== rsyslog ssh logging =='; sed -n '1,200p' /etc/rsyslog.d/30-ssh-session-logging.conf 2>/dev/null || true; echo '== last ssh command logs =='; tail -n 20 /var/log/ssh_commands.log 2>/dev/null || true; echo '== firewall v4 =='; iptables -S; echo '== firewall v6 =='; ip6tables -S; echo '== dns =='; cat /etc/resolv.conf; echo '== hosts =='; cat /etc/hosts; echo '== sysctl =='; sysctl fs.protected_fifos kernel.modules_disabled; echo '== audit rules =='; auditctl -l || true; echo '== residual rc packages =='; dpkg -l | awk '/^rc/{print $$2}'"
