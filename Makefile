# Project Makefile
# Standard interface: sync, fmt, lint, typecheck, test, check, qa, clean, help
SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help
.SHELLFLAGS := -euo pipefail -c
.DELETE_ON_ERROR:

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

MOLECULE := molecule
ANSIBLE_LINT := ansible-lint
GALAXY := ansible-galaxy
ANSIBLE_PLAYBOOK := ansible-playbook
YAML_LINT := uvx yamllint

#------------------------------------------------------------------------------
# Output and optional RTK quiet-wrapper
#------------------------------------------------------------------------------

V ?= 0
RTK_BIN := $(shell command -v rtk 2>/dev/null)
RTK     := $(if $(RTK_BIN),$(if $(filter 1,$(V)),,$(RTK_BIN) err),)

NO_COLOR ?=
C_RESET := $(if $(NO_COLOR),,\033[0m)
C_INFO  := $(if $(NO_COLOR),,\033[34m)
C_OK    := $(if $(NO_COLOR),,\033[32m)
C_WARN  := $(if $(NO_COLOR),,\033[33m)
C_FAIL  := $(if $(NO_COLOR),,\033[31m)
C_SKIP  := $(if $(NO_COLOR),,\033[36m)
MSG_INFO := printf "$(C_INFO)INFO:$(C_RESET) %s\n"
MSG_OK   := printf "$(C_OK)OK:$(C_RESET) %s\n"
MSG_WARN := printf "$(C_WARN)WARN:$(C_RESET) %s\n" >&2
MSG_FAIL := printf "$(C_FAIL)FAIL:$(C_RESET) %s\n" >&2
MSG_SKIP := printf "$(C_SKIP)SKIP:$(C_RESET) %s\n"

define RUN
	$(MSG_INFO) "$@"
	output=$$($(RTK) $(1) 2>&1) && status=0 || status=$$?; \
	if [ "$$status" -ne 0 ]; then \
		$(MSG_FAIL) "$@ failed"; \
		printf "%s\n" "$$output" >&2; \
		exit "$$status"; \
	fi; \
	[ "$(V)" = "1" ] && printf "%s\n" "$$output"; \
	$(MSG_OK) "$@ complete"
endef

#------------------------------------------------------------------------------
# Phony Targets Declaration
#------------------------------------------------------------------------------

.PHONY: help sync fmt lint typecheck check qa clean distclean
.PHONY: test test.unit test.integration test.e2e
.PHONY: info info.vars build
.NOTPARALLEL: check qa

#------------------------------------------------------------------------------
# High-Level Targets
#------------------------------------------------------------------------------

check: fmt
	$(MAKE) --no-print-directory lint
	$(MAKE) --no-print-directory typecheck
qa: check test
test: test.unit

#------------------------------------------------------------------------------
# Installation & Dependencies
#------------------------------------------------------------------------------

sync:
	version=$$($(MAKE) --version 2>/dev/null | head -1)
	case "$$version" in
		GNU\ Make*) $(MSG_OK) "$$version" ;;
		*) $(MSG_FAIL) "GNU Make is required (brew install make; use gmake)"; exit 1 ;;
	esac
	$(call RUN,$(GALAXY) collection install -r requirements.yml)

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------

fmt:
	$(call RUN,$(YAML_LINT) .)

lint:
	$(call RUN,$(ANSIBLE_LINT) .)

typecheck:
	for playbook in playbooks/*.yml; do \
		[ -f "$$playbook" ] || continue; \
		$(call RUN,$(ANSIBLE_PLAYBOOK) --syntax-check "$$playbook"); \
	done

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

test.unit:
	$(MAKE) --no-print-directory typecheck

test.integration:
	MOLECULE_SCENARIO_FLAG=""; \
	if [ -n "$(MOLECULE_SCENARIO)" ]; then \
		MOLECULE_SCENARIO_FLAG="--scenario-name $(MOLECULE_SCENARIO)"; \
	fi; \
	for role_dir in roles/*; do \
		role_name=$$(basename $$role_dir); \
		if [ -n "$(MOLECULE_ROLE)" ] && [ "$$role_name" != "$(MOLECULE_ROLE)" ]; then \
			continue; \
		fi; \
		if [ -d "$$role_dir/molecule" ]; then \
			$(MSG_INFO) "Testing role: $$role_name"; \
			(cd "$$role_dir" && $(MOLECULE) test $$MOLECULE_SCENARIO_FLAG); \
		fi; \
	done

test.e2e:
	$(MSG_INFO) "E2E tests: use 'make test.integration' for molecule scenarios"

#------------------------------------------------------------------------------
# Build
#------------------------------------------------------------------------------

build:
	$(call RUN,$(GALAXY) collection build --force)

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

clean:
	$(MSG_INFO) "Cleaning build artifacts..."
	rm -f *.tar.gz
	find . -type d \( -name ".molecule" -o -name ".pytest_cache" -o -name "__pycache__" \) -prune -exec rm -rf {} +

distclean: clean
	$(MSG_INFO) "Performing deep clean..."
	rm -rf .ansible dist

#------------------------------------------------------------------------------
# Info
#------------------------------------------------------------------------------

info:
	$(MSG_INFO) "System information"
	printf "  %-12s: %s\n" "OS" "$(shell uname -s)"
	printf "  %-12s: %s\n" "Release" "$(shell uname -r | sed 's/-.*//')"
	printf "  %-12s: %s\n" "Architecture" "$(shell uname -m)"
	printf "  %-12s: %s\n" "CPU cores" "$(shell sysctl -n hw.ncpu 2>/dev/null || nproc)"
	$(MSG_INFO) "Build environment"
	printf "  %-12s: %s\n" "GNU Make" "$(shell make --version 2>/dev/null | head -1)"
	printf "  %-12s: %s\n" "Shell" "$(SHELL)"
	$(MSG_INFO) "Makefile variables"
	$(MAKE) --no-print-directory info.vars | sort -k1,1n -k2,2 | sed -E 's/^[0-9]+\.[A-Za-z]+ //'

info.vars:
	printf "%s\n" "02.Tools MOLECULE=$(MOLECULE)"
	printf "%s\n" "02.Tools ANSIBLE_LINT=$(ANSIBLE_LINT)"
	printf "%s\n" "02.Tools GALAXY=$(GALAXY)"
	printf "%s\n" "02.Tools ANSIBLE_PLAYBOOK=$(ANSIBLE_PLAYBOOK)"
	printf "%s\n" "02.Tools YAML_LINT=$(YAML_LINT)"

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	printf "\033[36m"
	printf "╔═╗╦ ╦╔╦╗ ╦ ╔═╗╔╗ ╔═╗╦ ╦\n"
	printf "╠═╣║ ║ ║║ ║ ║ ║╠╩╗║ ║╔╬╝\n"
	printf "╝ ╝╚═╝╚╩╝ ╩ ╚═╝╚═╝╚═╝╝ ╝\n"
	printf "\033[0m\n"
	printf "Usage: make [target]\n\n"
	printf "\033[1;35mSetup:\033[0m\n"
	printf "  sync            - Install dependencies\n"
	printf "\n"
	printf "\033[1;35mDevelopment:\033[0m\n"
	printf "  fmt             - Format YAML files\n"
	printf "  lint            - Lint code with auto-fix\n"
	printf "  typecheck       - Playbook syntax check\n"
	printf "  check           - fmt + lint + typecheck\n"
	printf "  qa              - check + test (quality gate)\n"
	printf "\n"
	printf "\033[1;35mTest:\033[0m\n"
	printf "  test            - Run all tests\n"
	printf "  test.unit       - Unit / syntax tests\n"
	printf "  test.integration - Role Molecule tests\n"
	printf "  test.e2e        - End-to-end tests\n"
	printf "\n"
	printf "\033[1;35mBuild:\033[0m\n"
	printf "  build           - Build collection package\n"
	printf "\n"
	printf "\033[1;35mCleanup:\033[0m\n"
	printf "  clean           - Remove build artifacts\n"
	printf "  distclean       - Deep clean (includes dist/)\n"
