"""Cross-platform JL Mixing Automation command dispatcher."""

from __future__ import annotations

import json
import sys
from collections.abc import Sequence

from .api.client_create import _error_envelope as client_error_envelope
from .api.client_create import execute as client_execute
from .api.client_create import parse_args as parse_client_args
from .api.client_update import _error_envelope as client_update_error_envelope
from .api.client_update import execute as client_update_execute
from .api.client_update import parse_args as parse_client_update_args
from .api.delivery_create import _error_envelope as delivery_error_envelope
from .api.delivery_create import execute as delivery_execute
from .api.delivery_create import parse_args as parse_delivery_args
from .api.delivery_management import _error_envelope as delivery_management_error_envelope
from .api.delivery_management import execute_delete_package as delivery_delete_package_execute
from .api.delivery_management import execute_status as delivery_status_execute
from .api.delivery_management import parse_delete_package_args as parse_delivery_delete_package_args
from .api.delivery_management import parse_status_args as parse_delivery_status_args
from .api.intake_validate import _error_envelope as intake_error_envelope
from .api.intake_validate import execute as intake_execute
from .api.intake_validate import parse_args as parse_intake_args
from .api.managed_client_files import _error as managed_files_error
from .api.managed_client_files import execute_import as managed_import_execute
from .api.managed_client_files import execute_import_plan as managed_import_plan_execute
from .api.managed_client_files import execute_reset as managed_reset_execute
from .api.managed_client_files import execute_reset_plan as managed_reset_plan_execute
from .api.managed_client_files import parse_import_args as parse_managed_import_args
from .api.managed_client_files import parse_reset_args as parse_managed_reset_args
from .api.project_create import _error_envelope as project_error_envelope
from .api.project_create import execute as project_execute
from .api.project_create import parse_args as parse_project_args
from .api.project_update import _error_envelope as project_update_error_envelope
from .api.project_update import execute as project_update_execute
from .api.project_update import parse_args as parse_project_update_args
from .api.revision_approve import _error_envelope as approval_error_envelope
from .api.revision_approve import execute as approval_execute
from .api.revision_approve import parse_args as parse_approval_args
from .api.revision_create import _error_envelope as revision_error_envelope
from .api.revision_create import execute as revision_execute
from .api.revision_create import parse_args as parse_revision_args
from .api.revision_lifecycle import _error as lifecycle_error_envelope
from .api.revision_lifecycle import execute as lifecycle_execute
from .api.revision_lifecycle import parse_args as parse_lifecycle_args
from .api.revision_unapprove import _error as unapprove_error_envelope
from .api.revision_unapprove import execute as unapprove_execute
from .api.revision_unapprove import parse_args as parse_unapprove_args
from .api.revision_update_description import _error_envelope as revision_description_error_envelope
from .api.revision_update_description import execute as revision_description_execute
from .api.revision_update_description import parse_args as parse_revision_description_args
from .api.studio_update import _error_envelope as studio_update_error_envelope
from .api.studio_update import execute as studio_update_execute
from .api.studio_update import parse_args as parse_studio_update_args
from .errors import ArgumentError, ValidationError
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

    if len(args) >= 2 and args[0:2] == ["studio", "update"]:
        try: request = parse_studio_update_args(args[2:])
        except ArgumentError as exc:
            _emit_json(studio_update_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(studio_update_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = studio_update_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["client", "create"]:
        try: request = parse_client_args(args[2:])
        except ArgumentError as exc:
            _emit_json(client_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(client_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = client_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["client", "update"]:
        try: request = parse_client_update_args(args[2:])
        except ArgumentError as exc:
            _emit_json(client_update_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(client_update_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = client_update_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["client-files", "import-plan"]:
        operation = "client.files.import.plan"
        try: request = parse_managed_import_args(args[2:], execute=False)
        except ArgumentError as exc:
            _emit_json(managed_files_error(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = managed_import_plan_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["client-files", "import-execute"]:
        operation = "client.files.import.execute"
        try: request = parse_managed_import_args(args[2:], execute=True)
        except ArgumentError as exc:
            _emit_json(managed_files_error(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = managed_import_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["audio-prep", "reset-plan"]:
        operation = "audio.prep.reset.plan"
        try: request = parse_managed_reset_args(args[2:], execute=False)
        except ArgumentError as exc:
            _emit_json(managed_files_error(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = managed_reset_plan_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["audio-prep", "reset-execute"]:
        operation = "audio.prep.reset.execute"
        try: request = parse_managed_reset_args(args[2:], execute=True)
        except ArgumentError as exc:
            _emit_json(managed_files_error(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = managed_reset_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["project", "create"]:
        try: request = parse_project_args(args[2:])
        except ArgumentError as exc:
            _emit_json(project_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(project_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = project_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["project", "update"]:
        try: request = parse_project_update_args(args[2:])
        except ArgumentError as exc:
            _emit_json(project_update_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(project_update_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = project_update_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["revision", "create"]:
        try: request = parse_revision_args(args[2:])
        except ArgumentError as exc:
            _emit_json(revision_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(revision_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = revision_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["revision", "update-description"]:
        try: request = parse_revision_description_args(args[2:])
        except ArgumentError as exc:
            _emit_json(revision_description_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(revision_description_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = revision_description_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["revision", "approve"]:
        try: request = parse_approval_args(args[2:])
        except ArgumentError as exc:
            _emit_json(approval_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(approval_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = approval_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0] == "revision" and args[1] in {"close", "reopen"}:
        action = args[1]
        operation = f"revision.{action}"
        try: request = parse_lifecycle_args(args[2:], action)
        except ArgumentError as exc:
            _emit_json(lifecycle_error_envelope(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(lifecycle_error_envelope(operation, "VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = lifecycle_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["revision", "unapprove"]:
        try: request = parse_unapprove_args(args[2:])
        except ArgumentError as exc:
            _emit_json(unapprove_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(unapprove_error_envelope("VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = unapprove_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["delivery", "create"]:
        try: request = parse_delivery_args(args[2:])
        except ArgumentError as exc:
            _emit_json(delivery_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        except ValidationError as exc:
            _emit_json(delivery_error_envelope("DELIVERY_VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked")); return exc.exit_code
        payload, status = delivery_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["delivery", "status"]:
        operation = "delivery.status"
        try: request = parse_delivery_status_args(args[2:])
        except ArgumentError as exc:
            _emit_json(delivery_management_error_envelope(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = delivery_status_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["delivery", "delete-package"]:
        operation = "delivery.delete-package"
        try: request = parse_delivery_delete_package_args(args[2:])
        except ArgumentError as exc:
            _emit_json(delivery_management_error_envelope(operation, "INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = delivery_delete_package_execute(request); _emit_json(payload); return status

    if len(args) >= 2 and args[0:2] == ["intake", "validate"]:
        try: request = parse_intake_args(args[2:])
        except ArgumentError as exc:
            _emit_json(intake_error_envelope("INVALID_REQUEST", str(exc), exc.exit_code)); return exc.exit_code
        payload, status = intake_execute(request); _emit_json(payload); return status

    print("Error: command has not yet been migrated to the v1.5 Python runtime.", file=sys.stderr)
    return EXIT_ARGUMENTS


if __name__ == "__main__":
    raise SystemExit(main())
