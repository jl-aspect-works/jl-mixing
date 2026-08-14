# Automation API: `intake.validate`

`intake.validate` exposes the non-destructive intake validation workflow through Automation API 1.0.

```bash
jl-mixing intake validate --json --project /path/to/project
```

The machine-facing route uses the same authoritative implementation as `validate-intake`; it does not launch the human command as a subprocess.

## Capabilities

Consumers should discover support through `system-info --json` rather than by matching application versions:

- `intake.validate` — base operation
- `intake.validate.report` — durable managed intake report
- `intake.validate.incremental-cache` — unchanged files may reuse authoritative cached inspection results
- `intake.validate.structured-files` — structured per-file validation records are returned in `data.files`

## Request options

The JSON route requires exactly one explicit `--project PATH`. It also accepts:

- `--source PATH`
- `--expected-sample-rate HZ`
- `--expected-bit-depth BITS`
- `--no-duplicate-check`
- `--dry-run`

The project manifest supplies the expected file format when present. `--progress=json` is not implemented and is rejected with `INVALID_REQUEST`.

## Incremental cache

Normal validation persists `00_Admin/intake-validation-cache.json`. The cache stores expensive file-inspection results such as SHA-256 identity, ffprobe metadata, decode-integrity results, and dual-mono inspection data.

A cached record is reused only when:

- its project-relative path still identifies the file;
- size and modification timestamp are unchanged;
- a lightweight content fingerprint over size plus the beginning/end of the file still matches; and
- the validation context is unchanged, including expected sample rate, bit depth, file format, and ffprobe/ffmpeg capability.

New, changed, or context-invalidated files receive the full authoritative checks. This avoids unnecessary repeated full-file decode/hash I/O while not relying on timestamps alone.

`--dry-run` never creates or updates the cache.

## Results

A completed scan returns project, manifest, report, workspace, source, and validation-cache paths. `data.summary` includes:

- `files_discovered`
- `blocking_errors`
- `warnings`
- `ffprobe_available`
- `ffmpeg_available`
- `cache_reused`
- `files_validated`

`data.files` contains one record per discovered file. Useful fields include:

- `relative_path`
- `is_audio`
- `status`: `valid`, `needs_attention`, `blocked`, `info`, or `not_applicable`
- `cache_state`: `validated` or `reused`
- `sha256` where applicable
- normalized audio `metadata`
- `decode_ok`
- `dual_mono`
- `findings`

Each finding has a stable `code`, `severity`, and `message`, with `expected` / `actual` or `related_paths` where relevant. Current finding codes include sample-rate, bit-depth and file-format mismatches, unreadable/decode-integrity failures, exact duplicate relationships, and exact dual-mono information.

## Human-report compatibility

Normal validation continues to update only the managed section of `00_Admin/Intake_Report.md`; Original Delivery remains immutable. Existing human-facing report contracts such as duplicate-basename reporting and established diagnostic wording are preserved. Exact SHA-256 duplicate relationships are additive and are also exposed through structured file findings.

Dry-run returns `status: planned`, does not update the report or cache, and includes `would_update` for the report path only.

A completed scan with blocking findings returns process exit code `5`, `status: blocked`, and machine code `INTAKE_BLOCKING_FINDINGS`. The report is still updated in normal mode, matching `validate-intake` behavior.

Request/context failures retain the existing exit-code contract and map to stable API machine codes such as `INVALID_REQUEST`, `PROJECT_NOT_FOUND`, `SOURCE_NOT_FOUND`, `WORKSPACE_CONTEXT_ERROR`, `VALIDATION_FAILED`, and `UNSAFE_OPERATION`.

## Contract artifacts

The response schema is:

`api/schemas/v1.0/operations/intake-validate.schema.json`

Golden success, planned, blocked, and error examples ship under `api/examples/v1.0/`.
