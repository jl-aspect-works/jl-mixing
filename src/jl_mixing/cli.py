"""Cross-platform JL Mixing Automation command dispatcher."""

from __future__ import annotations

import json
import sys
from collections.abc import Sequence

from .api.intake_validate import _error_envelope, execute as intake_execute, parse_args as parse_intake_args
from .errors import ArgumentError
from .system_info import document as system_info_document

EXIT_ARGUMENTS = 2
EXIT_CONFIG = 3


def _emit_json(payload: dict[str, object]) -> None:
    print(json.dumps(payload, separators=(",", ":"), sort_keys=True))


def main(argv: Sequence[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)

    if args == ["system-info", "--json"]:
        try:
            payload = system_info_document()
        except RuntimeError as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return EXIT_CONFIG
        _emit_json(payload)
        return 0

    if len(args) >= 2 and args[0:2] == ["intake", "validate"]:
        try:
            request = parse_intake_args(args[2:])
        except ArgumentError as exc:
            _emit_json(_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code))
            return exc.exit_code
        payload, status = intake_execute(request)
        _emit_json(payload)
        return status

    print("Error: command has not yet been migrated to the v1.5 Python runtime.", file=sys.stderr)
    return EXIT_ARGUMENTS


if __name__ == "__main__":
    raise SystemExit(main())
