# AX Module Studio implementation/team handoff v1.0

> Date: 2026-08-14 (Asia/Seoul)
> Status: Foundation Auth/RBAC complete in the reduced single-customer MVP boundary
> Supersedes: v0.9 implementation status and execution order; preserves historical publication evidence

## 1. Current Source baseline

Verified by fetching canonical `origin/dev`:

| Repository | `origin/dev` | Current evidence |
|---|---|---|
| Frontend | `0ba4295cf55e4b33c4fbacce6d8f75c4df837817` | FND-03 Frontend PR #4 merged |
| Backend | `e0a702dbfaf6f1c46d9ba21e88a08c013047e2fb` | FND-03 Backend PR #7 merged after FND-01 |
| Orchestrator | `eaeb3a380035e8ddb13e42fb1877baabd9f57549` | unchanged Coding Runtime baseline |

## 2. Foundation result

| Slice | State | Result |
|---|---|---|
| `AXMS-FND-01` | `DONE` | Backend feature/domain seam merged |
| `AXMS-FND-02` | `DONE` | Frontend app/feature seam merged |
| `AXMS-FND-03` | `DONE` | production two-role login/session and platform-role enforcement merged across Backend and Frontend |
| `AXMS-FND-04` | `RETIRED` | no scheduled implementation and no Wave; broad Approval/Audit/Job primitive is not needed before manual CMS |

The exact FND-03 reduction and FND-04 disposition are authoritative in
[the completion decision](../product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md).
Do not claim Project isolation or a complete account-management product from FND-03. `AXMS-CMS-01`
owns the full member-management UI/API work.

## 3. Next active work

There is no FND-04 Wave. After the Integration/Contract owner reserves shared contracts and Flyway
revisions, the next parallel product work is:

| Slice | Lead | Outcome |
|---|---|---|
| `AXMS-CMS-01` | 정차윤 | member/account status and membership management on the FND-03 authority seam |
| `AXMS-CMS-02` | 이재욱 | manual menu Draft/version/preview/direct publish |
| `AXMS-CMS-03` | 민은지 | manual content/page Draft/version/preview/direct publish |
| `AXMS-CMS-04` | 윤서 | board/post CRUD, publish, and soft delete |

CMS-05 → CMS-06 → CMS-07 remains sequential after the required reference/version contracts exist.

## 4. Team environment baseline

- Model routing: [multi-model LLM instruction routing](../workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md)
- Windows/macOS behavior: [team multi-OS specification](../workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md)
- Runtime versions and topology: [current local infrastructure baseline](../architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md)

Backend PR #4 is the macOS/PowerShell Core compatibility base. Backend PR #7 also contains the Windows
PowerShell 5.1 StrictMode fix. Master wrappers must remain OS-neutral and delegate runtime mutation to
Backend.

## 5. Preserved product rules

- `SUPER_ADMIN` is the delivery-company technical engineer; `GENERAL_ADMIN` is the customer operator.
- Manual CMS data and publication do not require `SUPER_ADMIN` approval.
- General Audit UI and broad manual-CMS approval/rejection remain outside the initial MVP.
- Autonomous coding remains the exception and retains two distinct-account approvals at every
  side-effect Gate in later Coding/LLM DevOps Slices.
- Master and Notion writes remain team-lead controlled. Teammate LLMs consume Master read-only and
  submit Slice PRs only to changed Source repositories.

## 6. Git integration policy update — 2026-08-18

- Master PR #4 promoted `dev` to `main`; the remote Master `dev` branch was subsequently absent.
- The preserved integration worktree at `9a5ae0f34db8eaeba2f2fe9b88dfcc168f7cfb8d` was used to recreate
  remote Master `dev` with a non-force push. Existing `main` was left unchanged.
- Across Master, Frontend, Backend, and Orchestrator, every Feature or agent-created PR now targets
  `dev` only.
- `main` is not an agent target. Min Seungjun periodically performs `dev` to `main` promotion manually
  and ensures that the persistent `dev` integration branch is not deleted during that operation.
