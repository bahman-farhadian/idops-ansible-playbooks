.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help settings settings-clean settings-clean-force settings-clean-force-all venv require-venv require-local-settings deps-bundle lint check ping deploy

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= host.yml
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
FORCE ?=
EXTRA_ARGS ?=
SETTINGS_ARG := -e nexus_local_settings_file="$(LOCAL_SETTINGS_FILE)"
MAKE_GOAL := $(firstword $(MAKECMDGOALS))

help:
	@printf "nexus-repository-systemd - install Nexus with systemd\n\n"
	@printf "Available targets:\n"
	@printf "  %-28s %s\n" "make help" "show this help"
	@printf "  %-28s %s\n" "make settings" "create or update your local settings file"
	@printf "  %-28s %s\n" "make settings-clean" "list local settings files"
	@printf "  %-28s %s\n" "make settings-clean-force" "delete backup files only (keeps *.local.yml)"
	@printf "  %-28s %s\n" "make settings-clean-force-all" "delete the named local settings file (cannot undo)"
	@printf "  %-28s %s\n" "make venv" "create or update the shared venv/ at the repo root"
	@printf "  %-28s %s\n" "make deps-bundle" "download Python wheels into wheelhouse/"
	@printf "  %-28s %s\n" "make check" "check playbook.yml syntax"
	@printf "  %-28s %s\n" "make lint" "run ansible-lint"
	@printf "  %-28s %s\n" "make ping" "test SSH to the Nexus host"
	@printf "  %-28s %s\n" "make deploy" "install Nexus, start systemd, create APT and Docker proxies"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LOCAL_SETTINGS_FILE=<path>" "you must pass a *.local.yml file; there is no default"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "extra ansible-playbook arguments"

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
			"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml" \
			"     or: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml" \
			"Create one with: make settings LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml"; \
		exit 1; \
	fi
	@case "$(LOCAL_SETTINGS_FILE)" in \
		*.local.yml) ;; \
		*) \
			printf '%s\n' \
				"LOCAL_SETTINGS_FILE must end with .local.yml (got $(LOCAL_SETTINGS_FILE))." \
				"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.nexus.local.yml"; \
			exit 1 ;; \
	esac

deps-bundle: require-venv
	$(VENV_ACTIVATE) && pip download -r $(PROJECT_ROOT)/requirements.txt -d $(WHEELHOUSE)

lint: require-venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --syntax-check $(SETTINGS_ARG)

ping: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e nexus_action=ping $(SETTINGS_ARG) $(EXTRA_ARGS)

deploy: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e nexus_action=deploy $(SETTINGS_ARG) $(EXTRA_ARGS)
