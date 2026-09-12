.DEFAULT_GOAL := help
.PHONY: help settings settings-reference settings-clean settings-clean-force settings-clean-force-all require-venv deps-bundle lint check ping provision cleanup

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= inventory.ini
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
PYTHON ?= python3
LOCAL_SETTINGS_FILE ?= vars/settings.local.yml
FORCE ?=
LIMIT ?=
EXTRA_ARGS ?=

help:
	@printf "playbook-template - scaffold for new implementation projects\n\n"
	@printf "Available targets:\n"
	@printf "  %-20s %s\n" "make help" "show this help"
	@printf "  %-20s %s\n" "make settings" "create/update vars/settings.local.yml for this machine"
	@printf "  %-20s %s\n" "make settings-reference" "write a full reference copy of every setting, for consulting only"
	@printf "  %-20s %s\n" "make settings-clean" "list machine-local settings files for this project"
	@printf "  %-20s %s\n" "make settings-clean-force" "delete disposable settings files (keeps settings.local.yml)"
	@printf "  %-20s %s\n" "make settings-clean-force-all" "also delete settings.local.yml (not reversible)"
	@printf "  %-20s %s\n" "(venv)" "shared env: create once at the repository root (make venv)"
	@printf "  %-20s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-20s %s\n" "make lint" "run ansible-lint"
	@printf "  %-20s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-20s %s\n" "make ping" "test connectivity to target"
	@printf "  %-20s %s\n" "make provision" "run provision workflow"
	@printf "  %-20s %s\n" "make cleanup" "run cleanup workflow"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_pattern>" "limit inventory scope"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"

settings:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/generate-local-settings.py \
		--vars-dir vars --output "$(LOCAL_SETTINGS_FILE)" \
		$(if $(filter 1,$(FORCE)),--force,)

settings-reference:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/generate-local-settings.py \
		--vars-dir vars --output vars/settings-reference.local.yml --reference

settings-clean:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars

settings-clean-force:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars --remove-disposable

settings-clean-force-all:
	@$(PYTHON) $(PROJECT_ROOT)/scripts/clean-local-settings.py --vars-dir vars --remove-active

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
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) -i "managed_target," $(PLAYBOOK_FILE) --syntax-check

ping: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
