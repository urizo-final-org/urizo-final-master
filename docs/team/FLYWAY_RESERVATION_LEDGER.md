# Flyway UTC reservation ledger

> Maintainer: authenticated teammate LLMs for their own work rows
> Format: append-only status record; do not reuse abandoned timestamps

## Self-service reservation rules

- New revisions use the current UTC time as `yyyyMMddHHmmssSSS` (17 digits, including milliseconds).
- Before writing SQL, the active LLM checks this ledger and Backend Migration filenames. If the value already exists, it generates a new current UTC value.
- If the same work already has a valid reservation, reuse it instead of creating another one.
- The active LLM records the current GitHub ID as `Owner` and immediately adds its own row as `RESERVED`. No separate approval from Min Seungjun or the Integration/Contract owner is required.
- Each teammate LLM may add and update only its own work rows. It must not edit another owner's rows, the baseline, or these policy rules.
- Set `Expires (UTC)` to 30 days after reservation. Record the Revision in the Backend PR body and update the row to `PR_OPEN`, `MERGED`, or `ABANDONED` as the work changes.
- Existing 14-digit revisions remain valid and must not be renamed or reused.

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
| `20260830013135942` | `MERGED` | `axms-ai06-007-profile-version-read-contract` | `create_ai_profile_version_read_contract` | `tmdwns0531` | `2026-09-30T01:31:35Z` | [#15](https://github.com/urizo-final-org/urizo-final-backend/pull/15) | none |
| `20260830025553074` | `MERGED` | `axms-ai06-008-job-snapshot-binding` | `bind_coding_job_to_profile_version` | `tmdwns0531` | `2026-09-30T02:55:53Z` | [#16](https://github.com/urizo-final-org/urizo-final-backend/pull/16) | `20260830013135942` |
| `20260830073257815` | `MERGED` | `axms-ai04-001-runner` | `create_coding_runner_task_queue` | `jcy644542` | `2026-09-29T07:32:57Z` | [#18](https://github.com/urizo-final-org/urizo-final-backend/pull/18) | `20260830025553074` |
| `20260830074952891` | `MERGED` | `axms-ai06-009-approval-check-guardrail-runtime` | `grant_coding_approval_transition_read` | `tmdwns0531` | `2026-09-29T07:49:52Z` | [#19](https://github.com/urizo-final-org/urizo-final-backend/pull/19) | `20260830073257815` |
| `20260830111238338` | `MERGED` | `axms-ai04-002-coding-handler-integration` | `create_coding_handler_results` | `tmdwns0531` | `2026-09-29T11:12:38Z` | [#22](https://github.com/urizo-final-org/urizo-final-backend/pull/22) | `20260830074952891` |
| `20260830162029912` | `MERGED` | `axms-ai05-001-01-cms-handler-integration` | `create_natural_cms_result_boundary` | `tmdwns0531` | `2026-09-29T16:20:29Z` | [#23](https://github.com/urizo-final-org/urizo-final-backend/pull/23) | `20260830111238338` |
| `20260831011109932` | `MERGED` | `axms-ai06-011-admin-profile-settings-integration` | `grant_profile_version_admin_write` | `tmdwns0531` | `2026-09-30T01:11:09Z` | [Backend #24](https://github.com/urizo-final-org/urizo-final-backend/pull/24) | `20260830162029912` |
| `20260831022313641` | `MERGED` | `axms-ai05-002-cms-site-settings-integration` | `create_cms_site_settings` | `tmdwns0531` | `2026-09-30T02:23:13Z` | [Backend #26](https://github.com/urizo-final-org/urizo-final-backend/pull/26) | `20260831011109932` |
| `20260831165912245` | `MERGED` | `AXMS-RC-002` | `unify_natural_cms_apply_transaction` | `tmdwns0531` | `2026-09-30T16:59:12Z` | [Backend #40](https://github.com/urizo-final-org/urizo-final-backend/pull/40) | `20260830162029912` |
| `20260831181151833` | `MERGED` | `AXMS-RC-003` | `expose_snapshot_approval_authority` | `tmdwns0531` | `2026-09-30T18:11:51Z` | [Backend #40](https://github.com/urizo-final-org/urizo-final-backend/pull/40) | `20260831165912245` |
| `20260831195834460` | `MERGED` | `AXMS-RC-005` | `cascade_provider_audit_on_credential_delete` | `tmdwns0531` | `2026-09-30T19:58:34Z` | [Backend #40](https://github.com/urizo-final-org/urizo-final-backend/pull/40) | none |
| `20260831030833217` | `RESERVED` | `axms-ai02-001-knowledge-vector-1024` | `widen_document_chunk_embedding_to_1024` | `emilyjjang-jpg` | `2026-09-30T03:08:33Z` | pending | none |
| `20260903055920035` | `MERGED` | `axms-ai05-010-natural-cms-resource-db-contract` | `allow_natural_cms_resource_types` | `tmdwns0531` | `2026-10-03T05:59:20Z` | [Backend #47](https://github.com/urizo-final-org/urizo-final-backend/pull/47) | `20260830162029912` |

## Reservation template

| Revision | State | Slice | Description | Owner | Expires (UTC) | Backend PR | Dependencies |
|---|---|---|---|---|---|---|---|
| `yyyyMMddHHmmssSSS` | `RESERVED` | `AXMS-...` | `lower_snake_description` | current GitHub ID | ISO-8601 | pending | revision/Slice IDs |

Allowed states: `RESERVED`, `PR_OPEN`, `MERGED`, `ABANDONED`. Reservation is self-approved after the duplicate checks and row append above. Git Push, PR creation, review, and Merge still follow the normal repository approval rules.
