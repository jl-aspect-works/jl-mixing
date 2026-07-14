# JL Mixing Automation
## Script Reference v1.0

## Common behavior

Explicit `--client` and `--project` values override context detected by walking
upward from the current directory. Modifying commands support `--dry-run` where
practical and `--non-interactive` when prompting may occur.

Suggested exit codes:

| Code | Meaning |
|---:|---|
| 0 | Success |
| 1 | General error |
| 2 | Invalid arguments |
| 3 | Invalid configuration |
| 4 | Context not found |
| 5 | Validation failed |
| 6 | Unsafe operation prevented |

## Commands

### `new-studio`

```bash
new-studio [--root PATH] [--name NAME] [--daw NAME] [--engineer NAME]
```

Defaults include Logic Pro, 48 kHz, 24-bit WAV, and
`~/Music/Mixes`. It never overwrites an existing workspace.

### `new-client`

```bash
new-client CLIENT_ID [options]
```

Creates `client.json` and Active/Completed project directories.

### `new-mix`

```bash
new-mix --project PROJECT_NAME [--client CLIENT] [options]
```

The canonical option is `--project`. Optional values include `--project-type`,
artist, producer, engineer, BPM, key, time signature, audio format, DAW,
template, deadline, requested deliverables, and description.

### `validate-intake`

```bash
validate-intake [options]
```

Inventories `Original_Delivery/`, performs core checks, and regenerates only the
managed section of `Intake_Report.md`. `ffprobe` enables enhanced technical
inspection. It does not convert or prepare audio in Version 1.0.

### `new-revision`

```bash
new-revision [--description TEXT]
```

Creates the next `Revision_XX` folder, notes template, print directory, and an
`open` manifest entry.

### `approve-mix`

```bash
approve-mix [--revision NUMBER] [--approved-by NAME]
```

Approves one revision and marks any previously approved revision `superseded`.

### `create-delivery`

```bash
create-delivery [--revision NUMBER] [--mark-delivered] [options]
```

Without `--mark-delivered`, assembles and validates the package. With it,
records the delivery timestamp.

### `complete-project`

```bash
complete-project [options]
```

Requires approval and delivery, updates state, and moves the project from
Active to Completed.
