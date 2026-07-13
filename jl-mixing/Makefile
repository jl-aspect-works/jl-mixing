SHELL := /bin/bash

.PHONY: help test schema-test check install uninstall release-check

help:
	@echo "JL Mixing Automation v$$(cat VERSION)"
	@echo
	@echo "Batch 1 development targets:"
	@echo "  make test          Verify documentation, schemas, templates, and shell syntax"
	@echo "  make schema-test   Require full Draft 2020-12 example validation"
	@echo "  make check         Check required and optional development dependencies"
	@echo "  make release-check Run Batch 1 release verification"
	@echo
	@echo "Installer targets are placeholders until the packaging batch:"
	@echo "  make install"
	@echo "  make uninstall"

test:
	@tests/run-tests.sh

schema-test:
	@python3 -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }
	@python3 tools/validate-json.py

check:
	@tools/check-dependencies
	@tools/shellcheck-all

install:
	@./install.sh

uninstall:
	@./uninstall.sh

release-check:
	@tools/release-check
