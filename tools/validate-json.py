#!/usr/bin/env python3
"""Validate example or explicitly supplied JSON documents.

Without --strict, a missing jsonschema package is reported as a skip. With
--strict, it is a test failure. Production installation later supplies a
private, pinned Python environment.
"""

from argparse import ArgumentParser
from pathlib import Path
import json
import sys


def parser() -> ArgumentParser:
    result = ArgumentParser()
    result.add_argument("--schema", type=Path)
    result.add_argument("--document", type=Path)
    result.add_argument("--strict", action="store_true")
    return result


def default_pairs(root: Path):
    return [
        (root / "schemas/studio.schema.json", root / "examples/studio.json"),
        (root / "schemas/client.schema.json", root / "examples/client.json"),
        (
            root / "schemas/project-manifest.schema.json",
            root / "examples/project-manifest.json",
        ),
        (
            root / "schemas/delivery-manifest.schema.json",
            root / "examples/delivery-manifest.json",
        ),
    ]


def main() -> int:
    args = parser().parse_args()
    root = Path(__file__).resolve().parent.parent

    if bool(args.schema) != bool(args.document):
        print("--schema and --document must be supplied together.", file=sys.stderr)
        return 2

    try:
        from jsonschema import Draft202012Validator, FormatChecker
    except ModuleNotFoundError:
        message = "Python package 'jsonschema' is not installed."
        if args.strict:
            print(f"[FAIL] JSON Schema validation: {message}", file=sys.stderr)
            return 1
        print(f"[SKIP] JSON Schema semantic validation: {message}")
        print(
            "       Optional developer setup: python3 -m venv .venv && "
            ".venv/bin/pip install -r packaging/requirements.txt"
        )
        return 0

    pairs = [(args.schema, args.document)] if args.schema else default_pairs(root)
    failed = False

    for schema_path, document_path in pairs:
        schema = json.loads(schema_path.read_text())
        Draft202012Validator.check_schema(schema)
        document = json.loads(document_path.read_text())
        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        errors = sorted(validator.iter_errors(document), key=lambda error: list(error.path))

        if errors:
            failed = True
            for error in errors:
                location = ".".join(str(item) for item in error.absolute_path) or "<root>"
                print(
                    f"[FAIL] {document_path.name} at {location}: {error.message}",
                    file=sys.stderr,
                )
        else:
            print(f"[OK] Schema: {document_path.name}")

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
