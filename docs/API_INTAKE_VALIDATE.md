# Automation API: `intake.validate`

`intake.validate` exposes the existing non-destructive intake validation workflow through Automation API 1.0.

```bash
jl-mixing intake validate --json --project /path/to/project
```

The machine-facing route uses the same authoritative implementation as `validate-intake`; it does not launch the human command as a subprocess.

## Request options

The JSON route requires exactly one explicit `--project PATH`. It also accepts the existing validation options:

- `--source PATH`
- `--expected-sample-rate HZ`
- `--expected-bit-depth BITS`
- `--no-duplicate-check`
- `--dry-run`

`--progress=json` is not implemented in this slice and is rejected with `INVALID_REQUEST`. This avoids mixing human diagnostics with the API progress-event stream before stable progress phases are available.

## Results

A completed scan returns project, manifest, report, workspace, and source paths plus a summary containing:

- `files_discovered`
- `blocking_errors`
- `warnings`
- `ffprobe_available`

Normal validation updates only the managed section of `00_Admin/Intake_Report.md`. Intake source files remain immutable.

Dry-run returns `status: planned`, does not update the report, and includes `would_update` for the report path.

A completed scan with blocking findings returns process exit code `5`, `status: blocked`, and machine code `INTAKE_BLOCKING_FINDINGS`. The report is still updated in normal mode, matching `validate-intake` behavior.

Request/context failures retain the existing exit-code contract and map to stable API machine codes such as `INVALID_REQUEST`, `PROJECT_NOT_FOUND`, `SOURCE_NOT_FOUND`, `WORKSPACE_CONTEXT_ERROR`, `VALIDATION_FAILED`, and `UNSAFE_OPERATION`.

## Contract artifacts

The response schema is:

`api/schemas/v1.0/operations/intake-validate.schema.json`

Golden success, planned, blocked, and error examples ship under `api/examples/v1.0/`.
