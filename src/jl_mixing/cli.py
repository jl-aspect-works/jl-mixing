"""Cross-platform JL Mixing Automation command dispatcher."""

from __future__ import annotations

import json
import sys
from collections.abc import Sequence

from .system_info import document as system_info_document

EXIT_ARGUMENTS = 2
EXIT_CONFIG = 3


def main(argv: Sequence[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)

    if args == ["system-info", "--json"]:
        try:
            payload = system_info_document()
        except RuntimeError as exc:
            print(f"Error: {exc}", file=sys.stderr)
            return EXIT_CONFIG
        print(json.dumps(payload, separators=(",", ":"), sort_keys=True))
        return 0

    print("Error: command has not yet been migrated to the v1.5 Python runtime.", file=sys.stderr)
    return EXIT_ARGUMENTS


if __name__ == "__main__":
    raise SystemExit(main())
