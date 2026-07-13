SHELL := /bin/bash

.PHONY: help test strict-test schema-test check install uninstall release-check

help:
	@echo "JL Mixing Automation v$$(cat VERSION)"
	@echo
	@echo "Batch 3 development targets:"
	@echo "  make test          Run artifact, unit, integration, and schema tests when dependencies are available"
	@echo "  make strict-test   Require jq and full Draft 2020-12 validation"
	@echo "  make schema-test   Run only strict JSON Schema validation"
	@echo "  make check         Check dependencies and run ShellCheck when installed"
	@echo "  make release-check Run current release verification"
	@echo
	@echo "All eight user commands are implemented. Installers remain Batch 4 placeholders."

test:
	@tests/run-tests.sh

strict-test:
	@PYTHON="$${JL_MIXING_PYTHON:-}"; \
	if [ -z "$$PYTHON" ] && [ -x .venv/bin/python ]; then PYTHON=.venv/bin/python; fi; \
	if [ -z "$$PYTHON" ]; then PYTHON="$$(command -v python3 || true)"; fi; \
	[ -n "$$PYTHON" ] || { echo "Missing Python 3" >&2; exit 1; }; \
	command -v jq >/dev/null 2>&1 || { echo "Missing required command: jq" >&2; exit 1; }; \
	"$$PYTHON" -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }; \
	JL_MIXING_PYTHON="$$PYTHON" JL_TEST_STRICT=1 tests/run-tests.sh

schema-test:
	@PYTHON="$${JL_MIXING_PYTHON:-}"; \
	if [ -z "$$PYTHON" ] && [ -x .venv/bin/python ]; then PYTHON=.venv/bin/python; fi; \
	if [ -z "$$PYTHON" ]; then PYTHON="$$(command -v python3 || true)"; fi; \
	[ -n "$$PYTHON" ] || { echo "Missing Python 3" >&2; exit 1; }; \
	"$$PYTHON" -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }; \
	"$$PYTHON" tools/validate-json.py --strict

check:
	@tools/check-dependencies
	@tools/shellcheck-all

install:
	@./install.sh

uninstall:
	@./uninstall.sh

release-check:
	@tools/release-check
