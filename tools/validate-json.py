#!/usr/bin/env python3
"""Validate JSON documents against the project's Draft 2020-12 schemas.

The basic test workflow treats a missing ``jsonschema`` package as a visible
skip. Strict development/CI mode treats it as a failure. The eventual Batch 4
installer provides a private pinned Python environment, so normal end users do
not need to activate or manage a virtual environment themselves.
"""

from argparse import ArgumentParser
import json
from pathlib import Path
import sys
from typing import Iterable

# A pair always represents (schema, instance document).
ValidationPair = tuple[Path, Path]


def parser() -> ArgumentParser:
    """Build the CLI parser used by Makefile targets and direct validation."""

    result = ArgumentParser(
        description="Validate JL Mixing JSON examples or one explicit document."
    )
    result.add_argument("--schema", type=Path)
    result.add_argument("--document", type=Path)
    result.add_argument(
        "--strict",
        action="store_true",
        help="fail instead of skipping when jsonschema is unavailable",
    )
    return result


def default_pairs(root: Path) -> list[ValidationPair]:
    """Return the four canonical schema/example pairs shipped by the project."""

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


def validate_pairs(pairs: Iterable[ValidationPair]) -> bool:
    """Validate every pair and return ``True`` only when all documents pass.

    Schema validity is checked before instance validation so a broken contract
    cannot produce misleading document errors.
    """

    from jsonschema import Draft202012Validator, FormatChecker

    failed = False
    for schema_path, document_path in pairs:
        schema = json.loads(schema_path.read_text())
        Draft202012Validator.check_schema(schema)

        document = json.loads(document_path.read_text())
        validator = Draft202012Validator(schema, format_checker=FormatChecker())
        errors = sorted(
            validator.iter_errors(document),
            key=lambda error: list(error.path),
        )

        if errors:
            failed = True
            for error in errors:
                location = ".".join(
                    str(item) for item in error.absolute_path
                ) or "<root>"
                print(
                    f"[FAIL] {document_path.name} at {location}: {error.message}",
                    file=sys.stderr,
                )
        else:
            print(f"[OK] Schema: {document_path.name}")

    return not failed


def main() -> int:
    """Resolve validation inputs, dependency policy, and process exit status."""

    args = parser().parse_args()
    root = Path(__file__).resolve().parent.parent

    # A caller must either provide both paths or neither; accepting half a pair
    # would make it unclear which contract or document should be used.
    if bool(args.schema) != bool(args.document):
        print("--schema and --document must be supplied together.", file=sys.stderr)
        return 2

    try:
        import jsonschema  # noqa: F401  # Imported here to support dependency-light tests.
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

    pairs: list[ValidationPair]
    if args.schema and args.document:
        pairs = [(args.schema, args.document)]
    else:
        pairs = default_pairs(root)

    return 0 if validate_pairs(pairs) else 1


if __name__ == "__main__":
    raise SystemExit(main())
