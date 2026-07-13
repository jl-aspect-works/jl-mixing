#!/usr/bin/env python3
from pathlib import Path
import json
import sys
from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parent.parent
pairs = [
    (ROOT/'schemas/studio.schema.json', ROOT/'examples/studio.json'),
    (ROOT/'schemas/client.schema.json', ROOT/'examples/client.json'),
    (ROOT/'schemas/project-manifest.schema.json', ROOT/'examples/project-manifest.json'),
    (ROOT/'schemas/delivery-manifest.schema.json', ROOT/'examples/delivery-manifest.json'),
]

failed = False
for schema_path, document_path in pairs:
    schema = json.loads(schema_path.read_text())
    Draft202012Validator.check_schema(schema)
    document = json.loads(document_path.read_text())
    errors = sorted(Draft202012Validator(schema, format_checker=FormatChecker()).iter_errors(document), key=lambda e: list(e.path))
    if errors:
        failed = True
        for error in errors:
            print(f"[FAIL] {document_path.name}: {error.message}", file=sys.stderr)
    else:
        print(f"[OK] {document_path.name}")

sys.exit(1 if failed else 0)
