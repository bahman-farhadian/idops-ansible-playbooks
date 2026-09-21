.DEFAULT_GOAL := help
.SHELLFLAGS := -eu -o pipefail -c
SHELL := /bin/bash
.PHONY: help venv reset deps-bundle clean check-local

PYTHON ?= python3
VENV ?= venv
VENV_PROMPT ?= idops-ansible-project
PIP := $(VENV)/bin/pip
VENV_ACTIVATE := . $(VENV)/bin/activate
REQUIREMENTS ?= requirements.txt
WHEELHOUSE ?= wheelhouse

help:
	@printf "idops-ansible-playbooks - project-wide tooling\n\n"
	@printf "Available targets:\n"
	@printf "  %-18s %s\n" "make help" "show this help"
	@printf "  %-18s %s\n" "make venv" "create the single project venv/ (prompt: $(VENV_PROMPT)) and install requirements.txt"
	@printf "  %-18s %s\n" "make reset" "remove venv/ and recreate it from scratch (make clean && make venv)"
	@printf "  %-18s %s\n" "make deps-bundle" "download dependency wheels into wheelhouse/ for offline use"
	@printf "  %-18s %s\n" "make clean" "remove the project venv/"
	@printf "  %-18s %s\n" "make check-local" "fail if a local settings file is tracked or staged in git"

venv: $(REQUIREMENTS)
	@echo "Creating virtual environment at $(VENV)/ (prompt: $(VENV_PROMPT))"
	$(PYTHON) -m venv --prompt "$(VENV_PROMPT)" $(VENV)
	@$(PIP) install --upgrade pip --quiet
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
	@echo "Done. Activate with: . $(VENV)/bin/activate"

reset: clean venv
	@echo "venv/ was removed and recreated from scratch."

deps-bundle: venv
	@echo "Downloading wheels for every dependency in $(REQUIREMENTS) into $(WHEELHOUSE)/"
	$(VENV_ACTIVATE) && pip download -r "$(REQUIREMENTS)" -d "$(WHEELHOUSE)"
	@echo "Done. $(WHEELHOUSE)/ can now be used for offline installs."

# Machine-local settings hold one operator's hosts, keys and paths. They are
# gitignored, but an ignore rule is not a guarantee: `git add -f` defeats it.
# This makes the invariant checkable, so it can run before a push or in CI.
check-local:
	@tracked="$$(git ls-files | grep -E '\.local\.yml(\.bak)?$$|local[_-]secrets\.yml$$' || true)"; \
	if [ -n "$$tracked" ]; then \
		echo "FAIL: a local settings file is tracked by git:"; \
		echo "$$tracked" | sed 's/^/  /'; \
		echo "Remove them with: git rm --cached <file>"; \
		exit 1; \
	fi; \
	staged="$$(git diff --cached --name-only | grep -E '\.local\.yml(\.bak)?$$|local[_-]secrets\.yml$$' || true)"; \
	if [ -n "$$staged" ]; then \
		echo "FAIL: a local settings file is staged for commit:"; \
		echo "$$staged" | sed 's/^/  /'; \
		echo "Unstage them with: git restore --staged <file>"; \
		exit 1; \
	fi; \
	echo "OK: no local settings file is tracked or staged."

clean:
	@if [ -d "$(VENV)" ]; then \
		rm -rf "$(VENV)"; \
		echo "Removed $(VENV)/"; \
	else \
		echo "$(VENV)/ does not exist; nothing to remove."; \
	fi
