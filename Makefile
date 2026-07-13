SHELL := /bin/bash

.PHONY: help test check install uninstall release-check

help:
	@echo "JL Mixing Automation v$$(cat VERSION)"
	@echo
	@echo "Batch 1 development targets:"
	@echo "  make test          Verify documentation, schemas, templates, and shell syntax"
	@echo "  make check         Check required and optional development dependencies"
	@echo "  make release-check Run Batch 1 release verification"
	@echo
	@echo "Installer targets are placeholders until the packaging batch:"
	@echo "  make install"
	@echo "  make uninstall"

test:
	@tests/run-tests.sh

check:
	@tools/check-dependencies
	@tools/shellcheck-all

install:
	@./install.sh

uninstall:
	@./uninstall.sh

release-check:
	@tools/release-check
