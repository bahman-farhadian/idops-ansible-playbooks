.DEFAULT_GOAL := help
.PHONY: help settings settings-clean settings-clean-force settings-clean-force-all venv require-venv require-local-settings deps-bundle lint check ping provision cleanup

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= inventory.ini
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
PYTHON ?= python3
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
PYTHON ?= python3
FORCE ?=
EXTRA_ARGS ?=
SETTINGS_ARG := -e template_local_settings_file="$(LOCAL_SETTINGS_FILE)"
MAKE_GOAL := $(firstword $(MAKECMDGOALS))

help:
	@printf "playbook-template - scaffold for new implementation projects\n\n"
	@printf "Available targets:\n"
	@printf "  %-20s %s\n" "make help" "show this help"
	@printf "  %-20s %s\n" "make settings" "create/update a machine-local settings file"
	@printf "  %-20s %s\n" "make settings-clean" "list machine-local settings files for this project"
	@printf "  %-20s %s\n" "make settings-clean-force" "delete disposable settings files (keeps *.local.yml)"
	@printf "  %-20s %s\n" "make settings-clean-force-all" "delete LOCAL_SETTINGS_FILE (not reversible)"
	@printf "  %-20s %s\n" "make venv" "create/update the shared repository-root environment"
	@printf "  %-20s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-20s %s\n" "make lint" "run ansible-lint"
	@printf "  %-20s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-20s %s\n" "make ping" "test connectivity to target"
	@printf "  %-20s %s\n" "make provision" "run provision workflow"
	@printf "  %-20s %s\n" "make cleanup" "run cleanup workflow"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LOCAL_SETTINGS_FILE=<path>" "required *.local.yml for every action (no default)"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"

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
		echo "Shared Python venv not found at $(VENV)."; \
		echo "Create it once from the repository root with: make venv"; \
		exit 1; \
	}

require-local-settings:
	@if [ -z "$(strip $(LOCAL_SETTINGS_FILE))" ]; then \
		printf '%s\n' \
			"LOCAL_SETTINGS_FILE is required." \
			"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.local.yml" \
			"     or: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.lab.local.yml" \
			"Create one with: make settings LOCAL_SETTINGS_FILE=vars/settings.local.yml"; \
		exit 1; \
	fi
	@case "$(LOCAL_SETTINGS_FILE)" in \
		*.local.yml) ;; \
		*) \
			printf '%s\n' \
				"LOCAL_SETTINGS_FILE must be a gitignored *.local.yml file (got $(LOCAL_SETTINGS_FILE))." \
				"Example: make $(MAKE_GOAL) LOCAL_SETTINGS_FILE=vars/settings.local.yml"; \
			exit 1 ;; \
	esac

deps-bundle: require-venv
	$(VENV_ACTIVATE) && pip download -r $(PROJECT_ROOT)/requirements.txt -d $(WHEELHOUSE)

lint: require-venv
	$(VENV_ACTIVATE) && ansible-lint $(PLAYBOOK_FILE)

check: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) -i "managed_target," $(PLAYBOOK_FILE) --syntax-check $(SETTINGS_ARG)

ping: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=ping $(SETTINGS_ARG) $(EXTRA_ARGS)

provision: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=provision $(SETTINGS_ARG) $(EXTRA_ARGS)

cleanup: require-local-settings require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e template_action=cleanup $(SETTINGS_ARG) $(EXTRA_ARGS)
