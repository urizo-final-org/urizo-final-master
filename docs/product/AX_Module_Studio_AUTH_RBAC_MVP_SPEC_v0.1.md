# AX Module Studio Auth/RBAC MVP specification v0.1

> Decision date: 2026-08-13 (Asia/Seoul)
> Status: Approved product MVP overlay
> Applies to: `AXMS-FND-03` and every later Slice that consumes product identity or Project authorization

## 1. Decision and precedence

The initial product MVP uses exactly two administrator roles:

- `SUPER_ADMIN` — 최고관리자, the delivery company's technical engineer;
- `GENERAL_ADMIN` — 일반관리자, the customer company's Project-scoped CMS operator.

This document is the approved MVP interpretation of the preserved
`AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`. It takes precedence where that document uses
`Project Admin`, `Reviewer`, generic `관리자`, manual-CMS approval, or general Audit language in a
way that conflicts with this two-role decision. Requirements unrelated to identity, authorization,
manual-CMS approval, or Audit remain unchanged.

The purpose is to open `AXMS-FND-03` without designing a large IAM product. It does not authorize
implementation before the roadmap dependency gate is open, and it does not change the separate
Contract/Flyway reservation rules.

## 2. MVP product boundary

### Included

- production login, logout, and current-session identity;
- the two fixed roles above;
- Project membership for `GENERAL_ADMIN`;
- server-derived actor, role, and Project scope;
- Backend enforcement plus Frontend role-aware navigation;
- 401, 403, and cross-Project isolation behavior;
- a one-time first `SUPER_ADMIN` bootstrap path;
- the role foundation required by later dual-control autonomous coding.

### Excluded

- custom roles or a permission editor;
- a separate `REVIEWER` role;
- SSO, OAuth login, MFA, SCIM, and enterprise federation;
- password recovery and a full account-administration product;
- general content, post, page, menu, or design approval/rejection;
- unified Audit history, an Audit search API, and an Audit administration screen;
- End User authentication, which belongs to the end-user Renderer scope if later required;
- Developer/PM as a product RBAC role;
- autonomous-coding approval persistence and LangGraph nodes, which are implemented only in the
  later Coding/LLM DevOps Slices.

## 3. Role definitions

| Role | Korean UI name | Scope | Primary responsibility |
|---|---|---|---|
| `SUPER_ADMIN` | 최고관리자 | Platform-global | Delivery-company technical configuration, integration, security, and support |
| `GENERAL_ADMIN` | 일반관리자 | Assigned Projects only | Customer-company business CMS operation |

`Project Admin`, `고객사 관리자`, `일반 관리자`, and `일반관리자` in earlier documents map to
`GENERAL_ADMIN` for this MVP. `SUPER_ADMIN` does not act as the customer's business approver.

The current Coding internal schema still contains the legacy string `PROJECT_ADMIN`. FND-03 must not
break the existing Coding Harness by renaming that consumer contract in place. Treat it as a legacy
compatibility alias and migrate the Coding contract through a later compatible expand→consumer
migration Slice before removing it.

The implementation may permit `SUPER_ADMIN` to inspect or repair Project business data as a global
support override, but normal CMS operation must never wait for a `SUPER_ADMIN` action.

## 4. Minimum permission matrix

### 4.1 Authentication, Project, and administrator assignment

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` |
|---|---:|---:|
| Login, logout, current session | allow | allow |
| List and open Projects | all Projects | assigned Projects only |
| Create or archive a Project | allow | deny |
| Assign or remove a `GENERAL_ADMIN` Project membership | allow | deny in the initial MVP |
| Create, disable, or restore an administrator account | allow | deny in the initial MVP |
| Grant or revoke `SUPER_ADMIN` | allow through a protected technical path | deny |

`AXMS-FND-03` owns the identity and Project-membership authority. A complete member-management UI,
invitation workflow, and customer member lifecycle remain `AXMS-CMS-01` work.

### 4.2 Technical configuration

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` |
|---|---:|---:|
| Connector URL, method, request/response specification | allow | deny |
| Public-data, platform LLM, or LangSmith Secret registration/rotation | allow | deny |
| Connector connection test and Connector Version activation | allow | deny |
| Provider/model allowlist and platform capability configuration | allow | deny |
| Repository status, PathPolicy, fixed denylist, infrastructure health | allow | deny |
| Use an already activated Connector/model in an assigned Project | allow | allow |

Secret plaintext is never displayed again after registration. `GENERAL_ADMIN` cannot inspect or
replace a platform Secret.

### 4.3 Knowledge/RAG operation

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` |
|---|---:|---:|
| Select an activated Connector for a Project | allow | assigned Project only |
| Configure non-secret document mapping, chunking, and evaluation criteria | allow | assigned Project only |
| View evaluation results and run RAG query tests | allow | assigned Project only |
| Start, cancel, or retry a Knowledge Build | allow | deny in the initial MVP |
| Activate or roll back a Knowledge Version | allow | deny in the initial MVP |
| Connect a Chatbot to Project Knowledge and test it | allow | assigned Project only |

This resolves the earlier contradictory language by keeping the sensitive Build/active-pointer
transition in the technical lane while preserving customer control over non-secret RAG composition
and quality review.

### 4.4 Manual CMS business operation

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` |
|---|---:|---:|
| Menu create, update, delete, preview, publish, unpublish | support override | assigned Project: allow |
| Content/Page create, update, delete, preview, publish, unpublish | support override | assigned Project: allow |
| Board/Post create, update, delete, publish, unpublish | support override | assigned Project: allow |
| Site design/template configuration, preview, publish, rollback | support override | assigned Project: allow |
| Customer business-member data management | support override | assigned Project: allow in `AXMS-CMS-01` |

Manual CMS changes do not require `SUPER_ADMIN` approval or rejection. The initial flow is:

```text
GENERAL_ADMIN edit
→ validate
→ preview where the domain supports it
→ GENERAL_ADMIN publish or unpublish
→ optional version rollback by GENERAL_ADMIN
```

Domain validation, version immutability where specified, and Draft-not-public invariants still
apply. They are system safety checks, not delivery-engineer approval gates.

## 5. Autonomous-coding exception: dual control

Autonomous coding is not ordinary CMS operation. Every side-effect Gate requires two approvals
from two distinct authenticated accounts:

1. one `GENERAL_ADMIN` who is assigned to the target Project and confirms the customer/business
   intent;
2. one `SUPER_ADMIN` who confirms technical scope, security, evidence, and delivery risk.

The later Coding/LLM DevOps flow applies dual control at least to:

```text
Scope / Context / read-write range
→ Patch / Diff and candidate SHA
→ Test / Build / Preview evidence
→ PR creation
→ Deployment
```

Rules:

- the same `actor_id` cannot satisfy both approvals;
- one rejection or missing approval keeps the pipeline paused;
- a changed scope, PathPolicy hash, patch, candidate SHA, or evidence hash invalidates the approvals
  bound to the earlier value;
- Spring Backend and Core DB are the authorization and approval source of truth;
- LangGraph only interrupts, checkpoints, and resumes after Spring confirms both approvals;
- the Orchestrator cannot grant a role, fabricate an approval, or hold final authorization.

`AXMS-FND-03` must preserve role and Project identity suitable for this future rule, but must not
implement the Coding approval workflow early.

## 6. Minimal authentication and authorization contract

### 6.1 Account and session

- A user signs in with `loginId` and password.
- Passwords are stored only as an adaptive one-way hash; plaintext is never stored or logged.
- A successful login returns an opaque Bearer session with an expiration time.
- Logout and account disablement revoke the affected session.
- Account status is limited to `ACTIVE` and `DISABLED` for `AXMS-FND-03`; invitation state belongs
  to `AXMS-CMS-01`.
- The first `SUPER_ADMIN` is created through a one-time, non-public bootstrap path. There is no
  public administrator sign-up.

Refresh tokens, device management, password recovery, MFA, and SSO are not required for this MVP.

### 6.2 Server authority

For every protected request the Backend derives:

- `actorId` from the validated session;
- the fixed platform role from the account authority;
- Project access from persisted membership or global `SUPER_ADMIN` scope;
- the target Project from the route or authoritative resource relationship.

Client-provided `actorId`, role, or Project claims never grant authority. Frontend menu hiding is a
usability feature only; the Backend repeats authorization for every operation.

### 6.3 Failure behavior

| Condition | Result |
|---|---|
| Missing, invalid, expired, or revoked session | `401 AUTHENTICATION_REQUIRED` |
| Authenticated actor lacks permission on a visible Project | `403 FORBIDDEN` |
| Resource belongs to an unassigned Project | `404 RESOURCE_NOT_FOUND` to avoid scope disclosure |

## 7. Conceptual persistence boundary

The exact Flyway schema is owned by the `AXMS-FND-03` implementation Slice, but the minimum
conceptual records are:

- administrator account and fixed role;
- revocable opaque session with expiration;
- Project membership for `GENERAL_ADMIN`;
- existing Project aggregate relationship.

This specification does not reserve a Flyway revision and does not authorize DDL by itself.

## 8. Slice boundaries and roadmap effect

### `AXMS-FND-03`

- implement the two fixed roles, login/session, Project membership, server actor context, and
  Backend/Frontend enforcement;
- preserve the current Local Full acceptance path through an explicit development-only profile;
- add valid login, invalid login, 401, 403, cross-Project isolation, disabled-account, and
  client-role-forgery tests;
- do not add manual-CMS approval, Audit UI, custom permissions, or Coding approval nodes.

### `AXMS-CMS-01`

- add the complete member list/invite/status/Project-membership management product on the FND-03
  authority;
- do not create another role model.

### `AXMS-FND-04`

The former broad Common Approval/Audit/Job proposal is not a prerequisite for the initial manual
CMS. It is deferred and must not block `AXMS-CMS-01` through `AXMS-CMS-04`. Existing Product Job
behavior remains preserved; new common primitives are introduced only by a concrete consuming
Slice.

### Coding/LLM DevOps

Implement the dual-approval records, hash binding, invalidation, and LangGraph interrupt/resume in
the corresponding later Coding/LLM DevOps Slices.

## 9. Acceptance criteria

`AXMS-FND-03` is complete only when all of the following pass:

1. A `SUPER_ADMIN` and a `GENERAL_ADMIN` can log in and log out.
2. The current-session response contains server-derived actor and fixed role information without a
   Secret or password value.
3. A `GENERAL_ADMIN` sees only assigned Projects and can operate Project-scoped business endpoints.
4. The same account cannot list or access an unassigned Project or its resource IDs.
5. A `GENERAL_ADMIN` receives 403 for platform technical configuration.
6. A `SUPER_ADMIN` can reach the technical configuration boundary and all Projects.
7. Supplying a forged role, actor ID, or Project ID does not elevate authority.
8. Expired, revoked, and disabled-account sessions fail closed.
9. Existing Stage 3–5 behavior and the development-only Local Full acceptance path remain
   compatible.
10. No manual-CMS approval/Audit product feature or autonomous-coding workflow is accidentally
    included in the Slice.
