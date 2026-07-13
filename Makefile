# Use Bash consistently for recipes on macOS and Linux.
SHELL := /bin/bash

# These targets are actions, not files.
.PHONY: help test strict-test schema-test check install uninstall release-check

# Display the current command and developer task surface.
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

# Run dependency-tolerant repository, unit, integration, and schema checks.
test:
	@tests/run-tests.sh

# Require all developer dependencies and execute the complete suite.
strict-test:
	@PYTHON="$${JL_MIXING_PYTHON:-}"; \
	if [ -z "$$PYTHON" ] && [ -x .venv/bin/python ]; then PYTHON=.venv/bin/python; fi; \
	if [ -z "$$PYTHON" ]; then PYTHON="$$(command -v python3 || true)"; fi; \
	[ -n "$$PYTHON" ] || { echo "Missing Python 3" >&2; exit 1; }; \
	command -v jq >/dev/null 2>&1 || { echo "Missing required command: jq" >&2; exit 1; }; \
	"$$PYTHON" -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }; \
	JL_MIXING_PYTHON="$$PYTHON" JL_TEST_STRICT=1 tests/run-tests.sh

# Run semantic Draft 2020-12 validation only.
schema-test:
	@PYTHON="$${JL_MIXING_PYTHON:-}"; \
	if [ -z "$$PYTHON" ] && [ -x .venv/bin/python ]; then PYTHON=.venv/bin/python; fi; \
	if [ -z "$$PYTHON" ]; then PYTHON="$$(command -v python3 || true)"; fi; \
	[ -n "$$PYTHON" ] || { echo "Missing Python 3" >&2; exit 1; }; \
	"$$PYTHON" -c 'import jsonschema' 2>/dev/null || { echo "Missing jsonschema. Run: python3 -m venv .venv && .venv/bin/pip install -r packaging/requirements.txt" >&2; exit 1; }; \
	"$$PYTHON" tools/validate-json.py --strict

# Check dependencies and static shell analysis.
check:
	@tools/check-dependencies
	@tools/shellcheck-all

# Delegate to the installer; implemented in Batch 4.
install:
	@./install.sh

# Delegate to the uninstaller; implemented in Batch 4.
uninstall:
	@./uninstall.sh

# Run release readiness checks; expanded in Batch 4.
release-check:
	@tools/release-check
