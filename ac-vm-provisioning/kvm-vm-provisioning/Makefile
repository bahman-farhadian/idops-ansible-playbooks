.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv deps-bundle lint check ping image-cache provision-check provision cleanup cleanup-force cleanup-force-disks

INVENTORY ?= host.yml
PLAYBOOK_FILE ?= playbook.yml
VENV ?= venv
WHEELHOUSE ?= wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
ANSIBLE_PLAYBOOK := $(VENV)/bin/ansible-playbook
VENV_ACTIVATE := . $(VENV)/bin/activate
LIMIT ?=
EXTRA_ARGS ?=

help:
	@printf "Available targets:\n"
	@printf "  %-28s %s\n" "make venv" "create venv/ and install dependencies"
	@printf "  %-28s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-28s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-28s %s\n" "make lint" "run ansible-lint"
	@printf "  %-28s %s\n" "make ping" "test connectivity to hypervisor"
	@printf "  %-28s %s\n" "make image-cache" "download/verify cached cloud images for referenced profiles"
	@printf "  %-28s %s\n" "make provision" "execute full provisioning workflow"
	@printf "  %-28s %s\n" "make provision-check" "run preflight stage in --check mode (no mutation by default)"
	@printf "  %-28s %s\n" "make cleanup" "preview cleanup scope (declared instance names only)"
	@printf "  %-28s %s\n" "make cleanup-force" "execute cleanup for declared instance names only (keeps disks by default)"
	@printf "  %-28s %s\n" "make cleanup-force-disks" "execute cleanup and remove declared instance disks"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_pattern>" "limit inventory scope"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"

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
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

image-cache: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision -e kvm_provision_stage=image-cache $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision-check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --check -e kvm_action=provision -e kvm_provision_stage=preflight $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force-disks: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true -e kvm_cleanup_remove_instance_disks=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
