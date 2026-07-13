SHELL := /bin/bash

.PHONY: help test strict-test schema-test check install uninstall release-check

help:
	@echo "JL Mixing Automation v$$(cat VERSION)"
	@echo
	@echo "Batch 2 development targets:"
	@echo "  make test          Run artifact checks and shared-library unit tests"
	@echo "  make strict-test   Require jq and full Draft 2020-12 schema validation"
	@echo "  make schema-test   Run only strict JSON Schema validation"
	@echo "  make check         Check dependencies and run ShellCheck when installed"
	@echo "  make release-check Run current release verification"
	@echo
	@echo "User commands and installers remain placeholders until later batches."

test:
	@tests/run-tests.sh

strict-test:
	@command -v jq >/dev/null 2>&1 || { echo "Missing required command: jq" >&2; exit 1; }
	@python3 -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }
	@JL_TEST_STRICT=1 tests/run-tests.sh

schema-test:
	@python3 -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }
	@python3 tools/validate-json.py --strict

check:
	@tools/check-dependencies
	@tools/shellcheck-all

install:
	@./install.sh

uninstall:
	@./uninstall.sh

release-check:
	@tools/release-check
