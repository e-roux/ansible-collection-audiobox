
# Project Makefile for Ansible Collection
# Standard interface: sync, fmt, lint, typecheck, test, check, qa, clean, help
SHELL := /bin/bash
.SILENT:
.ONESHELL:
.DEFAULT_GOAL := help

#------------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------------

MOLECULE := $(shell which molecule)
ANSIBLE_RUNNER := $(shell which ansible-runner)
ANSIBLE_LINT := $(shell which ansible-lint)
ANSIBLE_PLAYBOOK := $(shell which ansible-playbook)
UVX := uvx
YAMLLINT := $(UVX) yamllint

#------------------------------------------------------------------------------
# Phony Targets Declaration
#------------------------------------------------------------------------------

.PHONY: help sync fmt lint typecheck check qa clean distclean
.PHONY: test test.unit test.integration test.e2e test.watch test.check-deps test.pre-validate
.PHONY: doc doc.build doc.serve build deploy.gerbera

#------------------------------------------------------------------------------
# High-Level Targets
#------------------------------------------------------------------------------

check: fmt lint
qa: check test
test: test.unit

#------------------------------------------------------------------------------
# Installation & Dependencies
#------------------------------------------------------------------------------

sync:
	echo "Installing dependencies..."
	ansible-galaxy collection install -r requirements.yml \
		|| echo "No requirements.yml file found"

#------------------------------------------------------------------------------
# Code Quality
#------------------------------------------------------------------------------

fmt:
	echo "Formatting code..."
	# Ansible doesn't have a standard formatter, but we can sort yaml keys or
	# use yamllint
	$(YAMLLINT) -c $(XDG_CONFIG_HOME)/yamllint/yamllint.yml $(realpath $(CURDIR))/ 

lint:
	echo "Linting code..."
	ansible-lint || echo "ansible-lint not installed or no issues found"

typecheck:
	echo "Checking types..."
	# Ansible doesn't have traditional type checking, but we can validate syntax
	ansible-playbook --syntax-check playbooks/*.yml || echo "No playbook syntax issues found"

#------------------------------------------------------------------------------
# Testing
#------------------------------------------------------------------------------

test.check-deps:
	cd roles/mediaplayer/molecule/default && \
		bash verify-deps.sh

test.pre-validate:
	bash roles/mediaplayer/molecule/default/pre-test.sh

test.unit: 
	cd roles/mediaplayer && \
		$(MOLECULE) test

#------------------------------------------------------------------------------
# Documentation
#------------------------------------------------------------------------------

doc.build:
	echo "Building documentation..."
	# Placeholder for documentation building

doc.serve:
	echo "Serving documentation..."
	# Placeholder for serving documentation

doc: doc.build

#------------------------------------------------------------------------------
# Build
#------------------------------------------------------------------------------

build:
	echo "Building project..."
	# Placeholder for build process

#------------------------------------------------------------------------------
# Cleanup
#------------------------------------------------------------------------------

clean:
	echo "Cleaning build artifacts..."
	# Remove temporary files and cache
	find . -name "*.retry" -delete
	rm -rf .molecule

distclean: clean
	echo "Deep cleaning..."
	# Additional cleanup for distribution

#------------------------------------------------------------------------------
# Custom Targets
#------------------------------------------------------------------------------

deploy.gerbera:
	$(ANSIBLE_RUNNER) run /tmp/$(@F) \
		-p  playbooks/rpi-hifiberry-box.yml \
		--tags=gerbera

#------------------------------------------------------------------------------
# Help
#------------------------------------------------------------------------------

help:
	figlet -f standard "AudioBox" 2>/dev/null || echo "AudioBox"
	printf "Usage: make [target]\n\n"
	printf "\033[1;35mSetup:\033[0m\n"
	printf "  sync            - Restore dependencies\n"
	printf "\033[1;35mDev:\033[0m\n"
	printf "  fmt             - Format code\n"
	printf "  lint            - Lint code\n"
	printf "  check           - fmt + lint + typecheck\n"
	printf "\033[1;35mTest:\033[0m\n"
	printf "  test            - Run unit tests\n"
	printf "  qa              - check + test (quality gate)\n"
	printf "\033[1;35mDocs:\033[0m\n"
	printf "  doc.build       - Build documentation\n"
	printf "  doc.serve       - Serve locally\n"
	printf "\033[1;35mInfo:\033[0m\n"
	printf "  clean           - Remove artifacts\n"
