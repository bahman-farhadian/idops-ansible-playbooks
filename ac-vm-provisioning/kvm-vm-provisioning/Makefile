.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv require-venv deps-bundle lint check ping image-cache checksum-refresh provision-check provision cleanup cleanup-force cleanup-force-disks

PROJECT_ROOT := $(shell git rev-parse --show-toplevel 2>/dev/null)

INVENTORY ?= host.yml
PLAYBOOK_FILE ?= playbook.yml
VENV := $(PROJECT_ROOT)/venv
WHEELHOUSE := $(PROJECT_ROOT)/wheelhouse
VENV_ACTIVATE := . $(VENV)/bin/activate
LIMIT ?=
EXTRA_ARGS ?=

help:
	@printf "Available targets:\n"
	@printf "  %-28s %s\n" "make help" "show this help"
	@printf "  %-28s %s\n" "make venv" "create/update the shared repository-root environment"
	@printf "  %-28s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-28s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-28s %s\n" "make lint" "run ansible-lint"
	@printf "  %-28s %s\n" "make ping" "test connectivity to hypervisor"
	@printf "  %-28s %s\n" "make image-cache" "download/verify cached cloud images for referenced profiles"
	@printf "  %-28s %s\n" "make checksum-refresh" "refresh trusted checksum data for pinned images"
	@printf "  %-28s %s\n" "make provision" "execute full provisioning workflow"
	@printf "  %-28s %s\n" "make provision-check" "run preflight stage in --check mode (no mutation by default)"
	@printf "  %-28s %s\n" "make cleanup" "preview cleanup scope (declared instance names only)"
	@printf "  %-28s %s\n" "make cleanup-force" "execute cleanup for declared instance names only (keeps disks by default)"
	@printf "  %-28s %s\n" "make cleanup-force-disks" "execute cleanup and remove declared instance disks"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_pattern>" "limit run to named hypervisor(s)"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"

venv:
	$(MAKE) -C $(PROJECT_ROOT) venv

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
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --syntax-check

ping: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=ping $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

image-cache: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision -e kvm_provision_stage=image-cache $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

checksum-refresh: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision -e kvm_provision_stage=image-cache -e kvm_force_manifest_refresh=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision-check: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) --check -e kvm_action=provision -e kvm_provision_stage=preflight $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

provision: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

cleanup-force-disks: require-venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true -e kvm_cleanup_remove_instance_disks=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)
