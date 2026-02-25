.DEFAULT_GOAL := help
.PHONY: help venv deps-bundle lint check clone clone-check cleanup cleanup-force

INVENTORY ?= inventory.ini
CLONE_PLAYBOOK ?= clone-vms.yml
CLEANUP_PLAYBOOK ?= cleanup-vms.yml
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
	@echo "  make check         - syntax-check playbooks"
	@echo "  make clone-check   - dry-run VM provisioning"
	@echo "  make clone         - execute VM provisioning"
	@echo "  make cleanup       - preview VM cleanup (confirm_delete default is false)"
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
	$(VENV_ACTIVATE) && ansible-lint $(CLONE_PLAYBOOK) $(CLEANUP_PLAYBOOK)

check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLONE_PLAYBOOK) --syntax-check
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLEANUP_PLAYBOOK) --syntax-check

clone-check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLONE_PLAYBOOK) --check $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

clone: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLONE_PLAYBOOK) $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLEANUP_PLAYBOOK) $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(CLEANUP_PLAYBOOK) -e confirm_delete=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
