# AX Module Studio FND-03 completion scope and FND-04 retirement decision v0.1

> Decision date: 2026-08-14 (Asia/Seoul)
> Status: team-lead-confirmed current MVP decision
> Evidence: Backend PR #7 and Frontend PR #4 merged to canonical `dev`

## 1. Decision

`AXMS-FND-03` is complete for the initial single-customer demonstration boundary. Its approved delivered
scope is smaller than the earlier Auth/RBAC MVP specification:

- production login, logout, and current-session identity;
- fixed `SUPER_ADMIN` and `GENERAL_ADMIN` roles;
- opaque revocable sessions and hashed passwords;
- centralized Backend route/permission enforcement;
- `SUPER_ADMIN`-only platform LLM credential configuration;
- Frontend login, session expiry handling, role display, logout, and role-aware navigation;
- two one-shot bootstrapped demonstration administrators;
- development-only session compatibility for the existing local-full acceptance path.

## 2. Deliberately reduced scope

The current delivery serves one customer organization. Therefore FND-03 does not narrow a
`GENERAL_ADMIN` by Project and does not expose full account/member-management endpoints or UI.

| Earlier expectation | Current decision |
|---|---|
| Cross-Project membership isolation in FND-03 | omitted for the single-customer demonstration; do not claim it is implemented |
| Complete administrator account/member management in FND-03 | moved to `AXMS-CMS-01`; FND-03 provides only the bootstrapped demo accounts and underlying authority seam |
| General manual-CMS approval/rejection and unified Audit | remains excluded from the initial MVP |

This decision supersedes the Project-isolation completion conditions in the earlier Auth/RBAC MVP
specification for the current demonstration only. If multi-customer operation is introduced, it requires
a new explicitly assigned Slice and migration/contract review; it must not be silently inferred from the
existing `ProjectMembership` types or tables.

## 3. FND-04 disposition

The former `AXMS-FND-04` broad Common Approval/Audit/Job primitive is **retired as a scheduled Foundation
Slice**. There is no Wave between FND-03 and the manual CMS parallel work.

```text
FND-01 + FND-02
→ FND-03 complete
→ CMS-01 + CMS-02 + CMS-03 + CMS-04 (after shared Contract/Flyway reservations)
```

This does not remove autonomous-coding approval. The later Coding/LLM DevOps Slices still require two
distinct accounts—one assigned `GENERAL_ADMIN` and one `SUPER_ADMIN`—at every side-effect Gate. Those
consumer-specific records, hash binding, invalidation, and LangGraph interrupt/resume are implemented
with the consuming Coding Slice rather than through a premature broad FND-04 primitive.

## 4. Git evidence

| Repository | PR | Merged `origin/dev` evidence | Verification recorded by the implementation |
|---|---|---|---|
| Backend | [PR #7](https://github.com/urizo-final-org/urizo-final-backend/pull/7) | `e0a702dbfaf6f1c46d9ba21e88a08c013047e2fb` | 184 tests after provider-role guard fix; role HTTP checks; migration `V20260813054613`; Windows PowerShell 5.1 migration verification |
| Frontend | [PR #4](https://github.com/urizo-final-org/urizo-final-frontend/pull/4) | `0ba4295cf55e4b33c4fbacce6d8f75c4df837817` | 20 tests; typecheck/build; two-role browser checks; Stage 3–5 13-step regression |
