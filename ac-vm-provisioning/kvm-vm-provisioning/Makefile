.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv deps-bundle lint check ping image-cache provision-stage provision-check provision cleanup cleanup-force cleanup-force-disks benchmark-cold benchmark-report

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
STAGE ?= full
BENCHMARK_ROOT ?= logs/benchmark
BENCHMARK_DIR ?=

help:
	@printf "Available targets:\n"
	@printf "  %-28s %s\n" "make venv" "create venv/ and install dependencies"
	@printf "  %-28s %s\n" "make deps-bundle" "download wheel artifacts into wheelhouse/"
	@printf "  %-28s %s\n" "make lint" "run ansible-lint"
	@printf "  %-28s %s\n" "make check" "syntax-check playbook entrypoint"
	@printf "  %-28s %s\n" "make ping" "test connectivity to hypervisor"
	@printf "  %-28s %s\n" "make image-cache" "download/verify cached cloud images for referenced profiles"
	@printf "  %-28s %s\n" "make provision-stage" "run one provision stage only (set STAGE=preflight|image-cache|provision|runtime|full)"
	@printf "  %-28s %s\n" "make provision-check" "run preflight stage in --check mode (no mutation by default)"
	@printf "  %-28s %s\n" "make provision" "execute full provisioning workflow"
	@printf "  %-28s %s\n" "make cleanup" "preview cleanup scope (declared instance names only)"
	@printf "  %-28s %s\n" "make cleanup-force" "execute cleanup for declared instance names only (keeps disks by default)"
	@printf "  %-28s %s\n" "make cleanup-force-disks" "execute cleanup and remove declared instance disks"
	@printf "  %-28s %s\n" "make benchmark-cold" "destructive cold benchmark (cleanup + timed provision, apt update/upgrade disabled)"
	@printf "  %-28s %s\n" "make benchmark-report" "print wall time, stage totals, and top slow tasks from latest benchmark run"
	@printf "\nRuntime options:\n"
	@printf "  %-28s %s\n" "LIMIT=<host_pattern>" "limit inventory scope"
	@printf "  %-28s %s\n" "EXTRA_ARGS=\"-e key=value\"" "pass extra ansible arguments"
	@printf "  %-28s %s\n" "STAGE=<stage_name>" "set provision stage for make provision-stage"
	@printf "  %-28s %s\n" "BENCHMARK_DIR=<path>" "override benchmark output directory"

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

provision-stage: venv
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision -e kvm_provision_stage=$(STAGE) $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS)

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

benchmark-cold: venv
	@set -eu; \
	bench_root="$(BENCHMARK_ROOT)"; \
	if [ -n "$(BENCHMARK_DIR)" ]; then run_dir="$(BENCHMARK_DIR)"; else run_dir="$$bench_root/$$(date +%Y%m%d-%H%M%S)"; fi; \
	mkdir -p "$$bench_root" "$$run_dir"; \
	echo "Benchmark run directory: $$run_dir"; \
	$(VENV_ACTIVATE) && ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=cleanup -e kvm_cleanup_confirmed=true -e kvm_cleanup_remove_instance_disks=true $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS); \
	$(VENV_ACTIVATE) && export IDOPS_BENCHMARK=1 IDOPS_BENCHMARK_DIR="$$run_dir"; TIMEFORMAT='real_seconds=%R\nuser_seconds=%U\nsys_seconds=%S'; { time ansible-playbook -i $(INVENTORY) $(PLAYBOOK_FILE) -e kvm_action=provision -e '{"kvm_default_cloud_init_package_update": false, "kvm_default_cloud_init_package_upgrade": false}' $(if $(LIMIT),-l $(LIMIT),) $(EXTRA_ARGS); } 2> "$$run_dir/time.txt"; \
	echo "$$run_dir" > "$$bench_root/.last_run"; \
	echo "Benchmark complete. Next: make benchmark-report BENCHMARK_DIR=$$run_dir"

benchmark-report: venv
	@set -eu; \
	bench_root="$(BENCHMARK_ROOT)"; \
	if [ -n "$(BENCHMARK_DIR)" ]; then \
	  run_dir="$(BENCHMARK_DIR)"; \
	elif [ -f "$$bench_root/.last_run" ]; then \
	  run_dir="$$(cat "$$bench_root/.last_run")"; \
	  if [ ! -f "$$run_dir/timing_summary.json" ]; then run_dir=""; fi; \
	else \
	  run_dir=""; \
	fi; \
	if [ -n "$$run_dir" ]; then \
	  $(VENV_ACTIVATE) && $(PYTHON) scripts/benchmark_report.py --benchmark-root "$$bench_root" --benchmark-dir "$$run_dir"; \
	else \
	  $(VENV_ACTIVATE) && $(PYTHON) scripts/benchmark_report.py --benchmark-root "$$bench_root"; \
	fi
