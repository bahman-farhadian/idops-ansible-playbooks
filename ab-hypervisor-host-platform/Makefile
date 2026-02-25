.DEFAULT_GOAL := help
.PHONY: help venv deps-bundle lint check ping configure configure-check

INVENTORY ?= inventory.ini
PLAYBOOK_FILE ?= playbook.yml
VENV ?= venv
WHEELHOUSE ?= wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
LIMIT ?=
EXTRA_ARGS ?=

help:
	@echo "Available targets:"
	@echo "  make venv           - create venv/ and install dependencies"
	@echo "  make deps-bundle    - download wheel artifacts into wheelhouse/"
	@echo "  make lint           - run ansible-lint"
	@echo "  make check          - syntax-check playbook entrypoint"
	@echo "  make ping           - test connectivity to hypervisor"
	@echo "  make configure-check - dry-run hypervisor configuration"
	@echo "  make configure      - execute hypervisor configuration"

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
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e hypervisor_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

configure-check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --check -e hypervisor_action=configure $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

configure: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e hypervisor_action=configure $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
