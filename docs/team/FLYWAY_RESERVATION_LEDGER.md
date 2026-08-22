# Flyway UTC reservation ledger

> Owner: Integration/Contract owner
> Format: append-only status record; do not reuse abandoned timestamps

## Baseline

| Revision | State | Slice | Description | Owner | PR |
|---|---|---|---|---|---|
| `20260811220000` | `MERGED_LOCAL_BASELINE` | Stage 5 baseline | grant runtime migration readiness access | historical local implementation | not yet published |

The baseline is present in the preserved local Backend/Core DB, but at the 2026-08-12 checkpoint the implementation was still uncommitted locally. `MERGED_LOCAL_BASELINE` does not claim that canonical `origin/dev` contains it.

## Active reservations

| Revision | State | Slice | Description | Owner | Expires (UTC) | Backend PR | Dependencies |
|---|---|---|---|---|---|---|---|
| `20260819150845` | `RESERVED` | `axms-cms-local-demo-mvp` | `add_local_demo_cms_schema` | `tmdwns0531` | `2026-09-19T15:08:45Z` | pending | none |
| `20260819165652` | `RESERVED` | `axms-cms-local-demo-mvp` | `map_site_navigation_and_home_template` | `tmdwns0531` | `2026-09-19T16:56:52Z` | pending | `20260819150845` |

## Reservation template

| Revision | State | Slice | Description | Owner | Expires (UTC) | Backend PR | Dependencies |
|---|---|---|---|---|---|---|---|
| `YYYYMMDDHHMMSS` | `RESERVED` | `AXMS-...` | `lower_snake_description` | confirmed owner | ISO-8601 | pending | revision/Slice IDs |

Allowed states: `RESERVED`, `PR_OPEN`, `MERGED`, `ABANDONED`. The Integration/Contract owner is the sole editor. Timestamp allocation must also be recorded in the Backend PR body so a stale Master branch cannot silently authorize a collision.
