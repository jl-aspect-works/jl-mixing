# Transitional v1.0.4 Schemas

These schemas preserve the exact validation contracts used by commands that
have not yet been migrated during staged v1.1 development. The canonical v1.1
schemas are the five files in the parent `schemas/` directory.

Each command feature branch must move its command to the canonical v1.1 schema
and exact-identity validation. This legacy directory must not be treated as a
v1.1 workspace compatibility layer or migration feature.
