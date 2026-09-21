.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help settings settings-clean settings-clean-force settings-clean-force-all venv require-venv require-local-settings deps-bundle lint check ping scan harden reboot score suggestions ssh-check gap-report runtime-check \
        roles \
        role-network-identity role-boot-hardening role-grub-hardening role-prep-baseline role-terminal-dotfiles role-common-repos \
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
FORKS ?=
TAGS ?=
SKIP_TAGS ?=
EXTRA_VARS ?=
CHECK ?= false
DIFF ?= false
EXTRA_ARGS ?=
FORCE ?=
SETTINGS_ARG := -e debian_local_settings_file="$(LOCAL_SETTINGS_FILE)"
MAKE_GOAL := $(firstword $(MAKECMDGOALS))

BOOL_TRUE := 1 true yes TRUE YES

FORKS_ARG := $(if $(FORKS),--forks $(FORKS),)
TAGS_ARG := $(if $(TAGS),--tags $(TAGS),)
SKIP_TAGS_ARG := $(if $(SKIP_TAGS),--skip-tags $(SKIP_TAGS),)
EXTRA_VARS_ARG := $(if $(EXTRA_VARS),-e "$(EXTRA_VARS)",)
CHECK_ARG := $(if $(filter $(CHECK),$(BOOL_TRUE)),--check,)
DIFF_ARG := $(if $(filter $(DIFF),$(BOOL_TRUE)),--diff,)
PLAY_ARGS := $(SETTINGS_ARG) $(FORKS_ARG) $(TAGS_ARG) $(SKIP_TAGS_ARG) $(EXTRA_VARS_ARG) $(CHECK_ARG) $(DIFF_ARG) $(EXTRA_ARGS)

help:
	@printf "debian-based-os-hardening - harden Debian and Ubuntu hosts\n\n"
	@printf "Available targets:\n"
	@printf "  %-24s %s\n" "make help" "show this help"
	@printf "  %-24s %s\n" "make venv" "create or update the shared venv/ at the repo root"
	@printf "  %-24s %s\n" "make deps-bundle" "download Python wheels into wheelhouse/"
	@printf "  %-24s %s\n" "make check" "check playbook.yml syntax"
	@printf "  %-24s %s\n" "make lint" "run ansible-lint"
	@printf "  %-24s %s\n" "make settings" "create or update your local settings file"
	@printf "  %-24s %s\n" "make settings-clean" "list local settings files"
	@printf "  %-24s %s\n" "make settings-clean-force" "delete backup files only (keeps *.local.yml)"
	@printf "  %-24s %s\n" "make settings-clean-force-all" "delete the named local settings file (cannot undo)"
	@printf "  %-24s %s\n" "make ping" "test SSH to the hardening targets"
	@printf "  %-24s %s\n" "make scan" "run Lynis; fail if the score is below 86 (lynis_min_hardening_index)"
	@printf "  %-24s %s\n" "make harden" "harden Debian and Ubuntu hosts"
	@printf "  %-24s %s\n" "make reboot" "reboot the hardening targets"
	@printf "  %-24s %s\n" "make score" "print Lynis scores from artifacts/lynis/"
	@printf "  %-24s %s\n" "make suggestions" "print Lynis suggestions from artifacts/lynis/"
	@printf "  %-24s %s\n" "make ssh-check" "show the live sshd settings"
	@printf "  %-24s %s\n" "make gap-report" "print selected Lynis warnings from artifacts/lynis/"
	@printf "  %-24s %s\n" "make runtime-check" "check the guest; fail if UFW, cloud-init, or public SMTP is still there"
	@printf "\nPer-role targets (run a single role from the harden workflow):\n"
	@printf "  %-32s %s\n" "make roles" "list all role targets"
	@printf "  %-32s %s\n" "make role-network-identity" "run only the network_identity role"
	@printf "  %-32s %s\n" "make role-boot-hardening" "run only the boot_hardening role"
	@printf "  %-32s %s\n" "make role-grub-hardening" "run only the grub_hardening role"
	@printf "  %-32s %s\n" "make role-prep-baseline" "run only the prep_baseline role"
	@printf "  %-32s %s\n" "make role-terminal-dotfiles" "run only the terminal_dotfiles role"
	@printf "  %-32s %s\n" "make role-common-repos" "run only the common_repos role"
	@printf "  %-32s %s\n" "make role-package-hardening" "run only the package_hardening role"
	@printf "  %-32s %s\n" "make role-service-hardening" "run only the service_hardening role"
	@printf "  %-32s %s\n" "make role-firewall" "run only the firewall role"
	@printf "  %-32s %s\n" "make role-kernel-hardening" "run only the kernel_hardening role"
	@printf "  %-32s %s\n" "make role-auth-hardening" "run only the auth_hardening role"
	@printf "  %-32s %s\n" "make role-banner-hardening" "run only the banner_hardening role"
	@printf "  %-32s %s\n" "make role-ssh-hardening" "run only the ssh_hardening role"
	@printf "  %-32s %s\n" "make role-fail2ban" "run only the fail2ban role"
	@printf "  %-32s %s\n" "make role-auditd" "run only the auditd role"
	@printf "  %-32s %s\n" "make role-accounting-hardening" "run only the accounting_hardening role"
	@printf "  %-32s %s\n" "make role-integrity-hardening" "run only the integrity_hardening role"
	@printf "  %-32s %s\n" "make role-compiler-hardening" "run only the compiler_hardening role"
	@printf "  %-32s %s\n" "make role-file-permissions" "run only the file_permissions_hardening role"
	@printf "  %-32s %s\n" "make role-session-logging" "run only the session_logging role"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LOCAL_SETTINGS_FILE=<path>" "you must pass a *.local.yml file; there is no default"
	@printf "  %-28s %s\n" "FORKS=<n>" "set Ansible fork parallelism"
	@printf "  %-28s %s\n" "TAGS=<tag1,tag2>" "run only selected tags"
	@printf "  %-28s %s\n" "SKIP_TAGS=<tag1,tag2>" "skip selected tags"
	@printf "  %-28s %s\n" "EXTRA_VARS='k=v ...'" "pass extra vars"
	@printf "  %-28s %s\n" "CHECK=true" "enable Ansible --check"
	@printf "  %-28s %s\n" "DIFF=true" "enable Ansible --diff"
	@printf "  %-28s %s\n" "EXTRA_ARGS='<raw args>'" "pass raw ansible args"

settings: require-local-settings
	@$(PYTHON) $(PROJECT_ROOT)/scripts/generate-local-settings.py \
		--vars-dir vars --output "$(LOCAL_SETTINGS_FILE)" \
		$(if $(filter 1,$(FORCE)),--force,)

settings-clean:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars

settings-clean-force:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars --remove-disposable

settings-clean-force-all: require-local-settings
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars --remove-active --output "$(LOCAL_SETTINGS_FILE)"

venv:
	$(MAKE) -C $(PROJECT_ROOT) venv

require-venv:
	@test -f "$(VENV)/bin/activate" || { \
		echo "Python environment not found at $(VENV)."; \
		echo "From the repository root, run: make venv"; \
		exit 1; \
	}

require-local-settings:
	@if [ -z "$(strip $(LOCAL_SETTINGS_FILE))" ]; then \
		printf '%s\n' \
			"LOCAL_SETTINGS_FILE is required. There is no default." \
			"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.local.yml" \
			"     or: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml" \
			"Create one with: make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml"; \
		exit 1; \
	fi
	@case "$(LOCAL_SETTINGS_FILE)" in \
		*.local.yml) ;; \
		*) \
			printf '%s\n' \
				"LOCAL_SETTINGS_FILE must end with .local.yml (got $(LOCAL_SETTINGS_FILE))." \
				"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.local.yml"; \
			exit 1 ;; \
	esac

deps-bundle: require-venv
	$(VENV_ACTIVATE) && pip download -r $(PROJECT_ROOT)/requirements.txt -d $(WHEELHOUSE)

lint: require-venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --syntax-check $(SETTINGS_ARG)

ping: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=ping $(PLAY_ARGS)

scan: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=scan $(PLAY_ARGS)

harden: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden $(PLAY_ARGS)

reboot: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=reboot $(PLAY_ARGS)

score:
	@grep '^hardening_index=' artifacts/lynis/*/lynis-report.dat || true

suggestions:
	@grep '^suggestion\[\]=' artifacts/lynis/*/lynis-report.dat || true

ssh-check: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=ssh-check $(PLAY_ARGS)

gap-report:
	@grep -E '^hardening_index=|^warning\[]=|^suggestion\[]=|^details\[]=(KRNL-6000|SSH-7408|FIRE-4513|NETW-2705|NAME-4028|NAME-4404|LOGG-2154|BOOT-5122|FILE-6310|PKGS-7346|ACCT-9630)' artifacts/lynis/*/lynis-report.dat || true

runtime-check: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=runtime-check $(PLAY_ARGS)

# ── Per-role targets ──────────────────────────────────────────────────────────
# Each target runs the full harden workflow scoped to a single role via --tags.
# Accepts all standard runtime options: LOCAL_SETTINGS_FILE, FORKS, CHECK, DIFF, EXTRA_ARGS.

roles:
	@printf "Available role targets:\n"
	@printf "  make role-network-identity\n"
	@printf "  make role-boot-hardening\n"
	@printf "  make role-grub-hardening\n"
	@printf "  make role-prep-baseline\n"
	@printf "  make role-terminal-dotfiles\n"
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

role-network-identity: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags network_identity $(PLAY_ARGS)

role-boot-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags boot_hardening $(PLAY_ARGS)

role-grub-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags grub_hardening $(PLAY_ARGS)

role-prep-baseline: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags prep_baseline $(PLAY_ARGS)

role-terminal-dotfiles: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags terminal_dotfiles $(PLAY_ARGS)

role-common-repos: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags common_repos $(PLAY_ARGS)

role-package-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags package_hardening $(PLAY_ARGS)

role-service-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags service_hardening $(PLAY_ARGS)

role-firewall: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags firewall $(PLAY_ARGS)

role-kernel-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags kernel_hardening $(PLAY_ARGS)

role-auth-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags auth_hardening $(PLAY_ARGS)

role-banner-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags banner_hardening $(PLAY_ARGS)

role-ssh-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags ssh_hardening $(PLAY_ARGS)

role-fail2ban: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags fail2ban $(PLAY_ARGS)

role-auditd: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags auditd $(PLAY_ARGS)

role-accounting-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags accounting_hardening $(PLAY_ARGS)

role-integrity-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags integrity_hardening $(PLAY_ARGS)

role-compiler-hardening: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags compiler_hardening $(PLAY_ARGS)

role-file-permissions: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags file_permissions_hardening $(PLAY_ARGS)

role-session-logging: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e debian_hardening_action=harden --tags session_logging $(PLAY_ARGS)
