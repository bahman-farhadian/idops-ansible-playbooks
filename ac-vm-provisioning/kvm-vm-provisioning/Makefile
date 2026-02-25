.DEFAULT_GOAL := help
.PHONY: help venv deps-bundle lint check ping provision-check provision cleanup cleanup-force

INVENTORY ?= inventory.ini
SITE_PLAYBOOK ?= site.yml
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
	@echo "  make check         - syntax-check site playbook"
	@echo "  make ping          - test connectivity to hypervisor"
	@echo "  make provision-check - dry-run provisioning workflow"
	@echo "  make provision     - execute provisioning workflow"
	@echo "  make cleanup       - preview cleanup workflow (confirm_delete default is false)"
	@echo "  make cleanup-force - execute cleanup with confirm_delete=true"

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
	$(VENV_ACTIVATE) && ansible-lint $(SITE_PLAYBOOK)

check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) --syntax-check

ping: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) -e kvm_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision-check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) --check -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) -e kvm_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(SITE_PLAYBOOK) -e kvm_action=cleanup -e confirm_delete=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
