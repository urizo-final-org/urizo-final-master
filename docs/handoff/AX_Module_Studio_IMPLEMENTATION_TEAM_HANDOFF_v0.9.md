# AX Module Studio implementation/team handoff v0.9

> Date: 2026-08-13 (Asia/Seoul)
> Status: Auth/RBAC MVP decision recorded; Foundation Wave still in progress
> Supersedes the execution order and product-role interpretation in v0.8 while preserving its remote-publication evidence

## 1. Outcome

The team lead approved a minimum two-role product boundary for `AXMS-FND-03`:

- `SUPER_ADMIN`: delivery-company technical engineer with platform-global technical authority;
- `GENERAL_ADMIN`: customer-company operator limited to assigned Projects.

The authoritative decision is
[AX Module Studio Auth/RBAC MVP specification v0.1](../product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md).
It is a later product overlay for role naming, manual-CMS approval, Audit scope, and autonomous-coding
dual approval. The v0.8 repository publication, setup acceptance, preservation, and Git evidence remain
valid.

## 2. Current Foundation status

Observed or team-lead-confirmed on 2026-08-13:

| Slice | Repository | State | Evidence or boundary |
|---|---|---|---|
| `AXMS-FND-01` | Backend | in progress, not committed | Integration owner is working in a separate Backend session/worktree; this Master Slice does not touch it |
| `AXMS-FND-02` | Frontend | PR open | [Frontend PR #3](https://github.com/urizo-final-org/urizo-final-frontend/pull/3), `feature/LEEJAEWOOK1_frontend-app-seam_v0.1` → `dev` |
| `AXMS-FND-03` | Backend → Frontend | specification ready; implementation blocked | starts only after FND-01 and FND-02 merge and Contract/Flyway reservations are granted |
| `AXMS-FND-04` | N/A | deferred | broad manual-CMS Approval/Audit/Job primitive is not an initial MVP prerequisite |

This Master documentation Slice does not change Frontend, Backend, Orchestrator, public contracts,
Flyway, Compose, database state, or runtime state.

## 3. Approved MVP interpretation

### Manual CMS

An assigned `GENERAL_ADMIN` directly creates, updates, deletes, previews, publishes, unpublishes, and
rolls back the customer Project's menu, content/page, board/post, and site design/template data.
`SUPER_ADMIN` approval or rejection is not required. A separate Reviewer role and a unified Audit
product/UI are excluded from the initial MVP.

### Technical configuration

`SUPER_ADMIN` owns platform and integration settings such as Connector request/response specification,
Secrets, provider/model allowlists, LangSmith, repository status, PathPolicy, and infrastructure health.
Normal customer CMS work does not wait for the delivery engineer.

### Autonomous coding

Autonomous coding remains a strict exception. Every side-effect Gate requires approvals from two
distinct accounts:

- an assigned `GENERAL_ADMIN` for customer/business intent;
- a `SUPER_ADMIN` for technical/security/delivery risk.

Spring Backend and Core DB remain authoritative. LangGraph pauses and resumes but does not grant
authority. Scope, policy, candidate SHA, patch, or evidence changes invalidate approvals bound to the
earlier value.

## 4. Updated execution order

```text
FND-01 Backend seam + FND-02 Frontend seam
→ both merged
→ FND-03 two-role Auth/RBAC (Backend compatible contract/Flyway/Spring → Frontend)
→ CMS-01/02/03/04 feature-local work after Contract/Flyway reservation
→ CMS-05 → CMS-06 → CMS-07
```

The former FND-04 gate is removed from this initial sequence. Approval persistence is introduced only
by a concrete later consumer, especially the Coding/LLM DevOps dual-approval Slices.

## 5. Preservation and next gate

- Preserve the existing FND-01 dirty worktree and the FND-02 PR branch.
- Do not start FND-03 implementation until FND-01 and FND-02 are merged.
- Before FND-03 DDL, reserve a Flyway UTC revision through the Integration/Contract lane.
- Implement exactly the fixed-role, Project-isolation scope in the Auth/RBAC MVP specification.
- Do not add Reviewer, custom permissions, general CMS approval, Audit UI, MFA/SSO, or autonomous-coding
  workflow to FND-03.
