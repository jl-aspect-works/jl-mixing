# JL Mixing Automation
## User Guide v1.0

## Typical workflow

```text
new-studio
  ↓
new-client
  ↓
new-mix
  ↓
validate-intake
  ↓
prepare working audio manually
  ↓
new-revision
  ↓
approve-mix
  ↓
create-delivery
  ↓
create-delivery --mark-delivered
  ↓
complete-project
```

## Create the studio

```bash
new-studio
```

Accepting all defaults creates `~/Music/JL Mixing`, configures Logic Pro, and
creates `Studio/studio.json`.

## Create a client

```bash
new-client acme
```

## Create a project

```bash
new-mix --client acme --project "Blue Sky"
```

From within the client tree, omit `--client`.

## Store and validate client files

Copy received files into:

```text
01_Client_Files/Original_Delivery/
```

Do not edit them. Then run:

```bash
validate-intake
```

The command regenerates only the managed section in
`00_Admin/Intake_Report.md`; Engineer Notes are preserved.

## Prepare audio

Populate `02_Audio_Preparation/Working_Audio/` manually and document decisions
in `Preparation_Report.md`.

## Create a revision

```bash
new-revision --description "Initial mix"
```

Print all files for that revision into its `Prints/` directory. Prefix internal
working prints with `WORK `.

## Approve a revision

```bash
approve-mix --revision 1
```

The selected revision becomes `approved`; any previously approved revision
becomes `superseded`.

## Create and send the delivery

```bash
create-delivery
create-delivery --mark-delivered
```

## Complete the project

```bash
complete-project
```

Completion requires both an approved revision and a recorded delivery.

## Help

Every installed command supports:

```bash
<command> --help
```
