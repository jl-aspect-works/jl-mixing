#!/usr/bin/env python3
"""Validate Batch 1 example documents against their Draft 2020-12 schemas.

JSON syntax is always checked by tests/run-tests.sh. Semantic JSON Schema
validation is performed when the optional development dependency `jsonschema`
is available. The production installer will later create a private application
virtual environment containing the pinned dependency.
"""

from pathlib import Path
import json
import sys

try:
    from jsonschema import Draft202012Validator, FormatChecker
except ModuleNotFoundError:
    print(
        "[SKIP] JSON Schema semantic validation: Python package "
        "'jsonschema' is not installed."
    )
    print(
        "       Optional developer setup: "
        "python3 -m venv .venv && "
        ".venv/bin/pip install -r packaging/requirements.txt"
    )
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
PAIRS = [
    (ROOT / "schemas/studio.schema.json", ROOT / "examples/studio.json"),
    (ROOT / "schemas/client.schema.json", ROOT / "examples/client.json"),
    (
        ROOT / "schemas/project-manifest.schema.json",
        ROOT / "examples/project-manifest.json",
    ),
    (
        ROOT / "schemas/delivery-manifest.schema.json",
        ROOT / "examples/delivery-manifest.json",
    ),
]

failed = False
for schema_path, document_path in PAIRS:
    schema = json.loads(schema_path.read_text())
    Draft202012Validator.check_schema(schema)

    document = json.loads(document_path.read_text())
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    errors = sorted(validator.iter_errors(document), key=lambda error: list(error.path))

    if errors:
        failed = True
        for error in errors:
            print(f"[FAIL] {document_path.name}: {error.message}", file=sys.stderr)
    else:
        print(f"[OK] Schema: {document_path.name}")

sys.exit(1 if failed else 0)
