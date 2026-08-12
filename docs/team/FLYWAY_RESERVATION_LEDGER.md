# Flyway UTC reservation ledger

> Owner: Integration/Contract owner
> Format: append-only status record; do not reuse abandoned timestamps

## Baseline

| Revision | State | Slice | Description | Owner | PR |
|---|---|---|---|---|---|
| `20260811220000` | `MERGED_LOCAL_BASELINE` | Stage 5 baseline | grant runtime migration readiness access | historical local implementation | not yet published |

The baseline is present in the preserved local Backend/Core DB, but at the 2026-08-12 checkpoint the implementation was still uncommitted locally. `MERGED_LOCAL_BASELINE` does not claim that canonical `origin/dev` contains it.

## Active reservations

None.

## Reservation template

| Revision | State | Slice | Description | Owner | Expires (UTC) | Backend PR | Dependencies |
|---|---|---|---|---|---|---|---|
| `YYYYMMDDHHMMSS` | `RESERVED` | `AXMS-...` | `lower_snake_description` | confirmed owner | ISO-8601 | pending | revision/Slice IDs |

Allowed states: `RESERVED`, `PR_OPEN`, `MERGED`, `ABANDONED`. The Integration/Contract owner is the sole editor. Timestamp allocation must also be recorded in the Backend PR body so a stale Master branch cannot silently authorize a collision.
