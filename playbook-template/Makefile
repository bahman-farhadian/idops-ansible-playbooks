.DEFAULT_GOAL := help
.PHONY: help venv deps-bundle lint check ping provision cleanup

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= inventory.ini
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
LIMIT ?=
EXTRA_ARGS ?=

help:
	@printf "Available targets:\n"
	@printf "  %-20s %s\n" "make venv" "create venv/ and install dependencies"
	@printf "  %-20s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-20s %s\n" "make lint" "run ansible-lint"
	@printf "  %-20s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-20s %s\n" "make ping" "test connectivity to target"
	@printf "  %-20s %s\n" "make provision" "run provision workflow"
	@printf "  %-20s %s\n" "make cleanup" "run cleanup workflow"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_pattern>" "limit inventory scope"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"

venv:
	@test -d $(VENV) || $(MAKE) -C $(PROJECT_ROOT) venv

deps-bundle: venv
	$(VENV_ACTIVATE) && pip download -r $(PROJECT_ROOT)/requirements.txt -d $(WHEELHOUSE)

lint: venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) -i "managed_target," $(PLAYBOOK_FILE) --syntax-check

ping: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
