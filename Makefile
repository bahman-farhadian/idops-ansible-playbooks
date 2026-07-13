.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv deps-bundle clean

PYTHON ?= python3
VENV ?= venv
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
REQUIREMENTS ?= requirements.txt
WHEELHOUSE ?= wheelhouse
MSG ?= chore: project checkin

help:
	@printf "idops-ansible-playbooks - project-wide tooling\n\n"
	@printf "Available targets:\n"
	@printf "  %-18s %s\n" "make venv" "create the single project venv/ and install requirements.txt"
	@printf "  %-18s %s\n" "make deps-bundle" "download dependency wheels into wheelhouse/ for offline use"
	@printf "  %-18s %s\n" "make clean" "remove the project venv/"

venv: $(REQUIREMENTS)
	$(PYTHON) -m venv $(VENV)
	$(PIP) install --upgrade pip
	@if [ -d "$(WHEELHOUSE)" ] && find "$(WHEELHOUSE)" -maxdepth 1 -type f | grep -q .; then \
		echo "Installing dependencies from local wheelhouse/ cache"; \
		if ! $(PIP) install --no-index --find-links "$(WHEELHOUSE)" -r "$(REQUIREMENTS)"; then \
			echo "Wheelhouse cache incomplete; falling back to remote index"; \
			$(PIP) install -r "$(REQUIREMENTS)"; \
		fi; \
	else \
		echo "Installing dependencies from remote package index"; \
		$(PIP) install -r "$(REQUIREMENTS)"; \
	fi
	@touch $(VENV)/.deps.installed

deps-bundle: venv
	$(VENV_ACTIVATE) && pip download -r "$(REQUIREMENTS)" -d "$(WHEELHOUSE)"

clean:
	rm -rf $(VENV)
