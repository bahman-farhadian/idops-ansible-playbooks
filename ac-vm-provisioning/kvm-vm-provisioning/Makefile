.DEFAULT_GOAL := help
.PHONY: help venv deps-bundle lint check ping provision-check provision cleanup cleanup-force

INVENTORY ?= inventory.ini
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
	@echo "Available targets:"
	@echo "  make venv          - create venv/ and install dependencies"
	@echo "  make deps-bundle   - download wheel artifacts into wheelhouse/"
	@echo "  make lint          - run ansible-lint"
	@echo "  make check         - syntax-check playbook entrypoint"
	@echo "  make ping          - test connectivity to hypervisor"
	@echo "  make provision-check - preflight provisioning check (--check, no mutation by default)"
	@echo "  make provision     - execute provisioning workflow"
	@echo "  make cleanup       - preview cleanup workflow (kvm_cleanup_confirmed default is false)"
	@echo "  make cleanup-force - execute cleanup with kvm_cleanup_confirmed=true"
	@echo ""
	@echo "Runtime options:"
	@echo "  LIMIT=<host_pattern>         - limit inventory scope"
	@echo "  EXTRA_ARGS=\"-e key=value\"   - pass extra ansible arguments"

$(VENV)/bin/activate:
	$(PYTHON) -m venv $(VENV)

$(VENV)/.deps.installed: requirements.txt $(VENV)/bin/activate
	$(PIP) install --upgrade pip
	@if find $(WHEELHOUSE) -maxdepth 1 -type f ! -name '.gitkeep' | grep -q .; then \
		echo "Installing dependencies from local wheelhouse/ cache"; \
		$(PIP) install --no-index --find-links $(WHEELHOUSE) -r requirements.txt; \
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

provision-check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --check -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
