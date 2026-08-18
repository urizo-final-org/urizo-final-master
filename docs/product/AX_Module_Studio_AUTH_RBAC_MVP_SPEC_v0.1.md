# AX Module Studio Auth/RBAC MVP specification v0.1

> Decision date: 2026-08-13 (Asia/Seoul)
> Status: Historical administrator Auth/RBAC authority with later delivered and product-decision overlays
> Applies to: `AXMS-FND-03` and every later Slice that consumes product identity or Project authorization
> Later completion authority: `AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md` records the
> delivered single-customer reduction, moves full member management to CMS-01, and retires the scheduled
> FND-04 Wave while preserving later Coding dual approval.
> Approval-gate clarification: 2026-08-18 — later LLM DevOps has exactly three dual-approval Gates:
> autonomous-coding result, PR creation, and deployment.
> Current product authority: `AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md` adds
> `GENERAL_USER`, Approval History/core Audit Log, and the post-CMS team-planning Gate.

For delivered FND-03 evidence, the later completion authority wins wherever this document still
describes the multi-Project target state. For the current product target and scheduling, the team
checklist decision overlay wins. Sections 3 through 7 are not evidence that Project isolation,
`GENERAL_USER`, member management, Approval History, or Audit Log shipped in FND-03.

## 1. Decision and precedence

The delivered FND-03 administrator boundary uses exactly two administrator roles:

- `SUPER_ADMIN` — 최고관리자, the delivery company's technical engineer;
- `GENERAL_ADMIN` — 일반관리자, the customer company's Project-scoped CMS operator.

The later current product target adds one fixed non-administrator role:

- `GENERAL_USER` — 일반 사용자, the published end-user site's user without administrator authority.

This document is the approved MVP interpretation of the preserved
[`AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`](AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md). It takes precedence where that document uses
`Project Admin`, `Reviewer`, generic `관리자`, manual-CMS approval, or general Audit language. The
later team checklist overlay supersedes this document for `GENERAL_USER`, Approval History/core Audit
Log inclusion, and post-CMS scheduling.

The purpose is to open `AXMS-FND-03` without designing a large IAM product. It does not authorize
implementation before the roadmap dependency gate is open, and it does not change the separate
Contract/Flyway reservation rules.

## 2. MVP product boundary

### Included

- production login, logout, and current-session identity;
- the delivered two administrator roles plus the fixed `GENERAL_USER` product target;
- the Project-membership persistence/service seam for later expansion, without Project narrowing in the
  current single-customer demonstration;
- server-derived actor, role, and Project scope;
- Backend enforcement plus Frontend role-aware navigation;
- production 401 and 403 behavior; cross-Project isolation remains a future multi-customer target;
- two one-shot bootstrapped demonstration administrators;
- later `GENERAL_USER` account/session and published Renderer access through CMS-01/CMS-07;
- Approval History and core Audit Log screens over state-changing MVP events;
- the role foundation required by later dual-control autonomous coding.

### Excluded

- custom roles or a permission editor;
- a separate `REVIEWER` role;
- SSO, OAuth login, MFA, SCIM, and enterprise federation;
- password recovery and a full account-administration product;
- a separate pre-publication `REVIEWER` workflow for ordinary manual CMS work;
- exhaustive Audit capture of every view, click, read, or navigation event;
- Developer/PM as a product RBAC role;
- autonomous-coding approval persistence and LangGraph nodes, which are implemented only in the
  later Coding/LLM DevOps Slices.

## 3. Role definitions

| Role | Korean UI name | Scope | Primary responsibility |
|---|---|---|---|
| `SUPER_ADMIN` | 최고관리자 | Platform-global | Delivery-company technical configuration, integration, security, and support |
| `GENERAL_ADMIN` | 일반관리자 | Current single customer; assigned Projects after a future multi-customer Slice | Customer-company business CMS operation |
| `GENERAL_USER` | 일반 사용자 | Published end-user site | Uses published user-facing functions without administrator authority |

`Project Admin`, `고객사 관리자`, `일반 관리자`, and `일반관리자` in earlier documents map to
`GENERAL_ADMIN` for this MVP. `SUPER_ADMIN` does not act as the customer's business approver.
`GENERAL_USER` is distinct from both administrator roles and never inherits an administrator route or
technical permission.

The current Coding internal schema still contains the legacy string `PROJECT_ADMIN`. FND-03 must not
break the existing Coding Harness by renaming that consumer contract in place. Treat it as a legacy
compatibility alias and migrate the Coding contract through a later compatible expand→consumer
migration Slice before removing it.

The implementation may permit `SUPER_ADMIN` to inspect or repair Project business data as a global
support override, but normal CMS operation must never wait for a `SUPER_ADMIN` action.

## 4. Minimum permission matrix

### 4.1 Authentication, Project, administrator, and General User assignment

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` |
|---|---:|---:|
| Login, logout, current session | allow | allow |
| List and open Projects | all Projects | assigned Projects only |
| Create or archive a Project | allow | deny |
| Assign or remove a `GENERAL_ADMIN` Project membership | allow | deny in the initial MVP |
| Create, disable, or restore an administrator account | allow | deny in the initial MVP |
| Create, disable, restore, or assign a `GENERAL_USER` account | support override | assigned Project: allow in `AXMS-CMS-01` |
| Grant or revoke `SUPER_ADMIN` | allow through a protected technical path | deny |

`AXMS-FND-03` owns the delivered administrator identity authority. A complete member-management UI,
`GENERAL_USER` lifecycle, invitation/status workflow, and customer membership remain `AXMS-CMS-01`
work. `AXMS-CMS-07` completes General User login/session and published Renderer access.

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

### 4.5 Approval History and core Audit Log

| Operation | `SUPER_ADMIN` | `GENERAL_ADMIN` | `GENERAL_USER` |
|---|---:|---:|---:|
| View Project Approval History | all Projects | assigned Project | deny |
| View core Audit Log | all Projects | assigned Project | deny |
| Record actor-bound CMS mutation/publish/rollback evidence | system | system | system for applicable user actions |

The screens include core state-changing account, permission, Draft/version, Preview, publish,
unpublish, Site Release, and rollback events. They do not log every view or click. Ordinary manual CMS
still uses `GENERAL_ADMIN` direct publication; recording that decision does not add a separate Reviewer
or `SUPER_ADMIN` approval Gate.

## 5. Autonomous-coding exception: dual control

Autonomous coding is not ordinary CMS operation. It requires dual control at exactly three human
approval Gates. Each Gate requires approvals from two distinct authenticated accounts:

1. one `GENERAL_ADMIN` who is assigned to the target Project and confirms the customer/business
   intent;
2. one `SUPER_ADMIN` who confirms technical scope, security, evidence, and delivery risk.

The approved flow is:

```text
Natural-language request
→ limited code change
→ one allowlisted test
→ result / Diff / evidence
→ Gate 1: autonomous-coding result dual approval
→ Gate 2: PR creation dual approval
→ automatic CI/readback and manual merge under Git policy
→ Gate 3: deployment dual approval
```

The internal request→code change→test→result sequence runs without human approval between its steps.
Scope, Context Pack, PathPolicy, denylist, command allowlist, and evidence production remain mandatory
automatic safety checks; they are not additional human approval Gates. Manual PR merge remains governed
by the Git workflow and is not a fourth product dual-approval Gate.

Rules:

- the same `actor_id` cannot satisfy both approvals;
- one rejection or missing approval at any of the three Gates keeps the pipeline paused;
- Gate 1 approvals bind the request, scope/PathPolicy, candidate SHA, Diff, and test/result evidence;
  changing any bound value invalidates Gate 1 and every downstream approval;
- Gate 2 approvals bind the exact candidate and PR payload; changing either invalidates Gate 2 and
  every downstream approval;
- Gate 3 approvals bind the exact deployable artifact, CI evidence, target environment, and deployment
  plan; changing any bound value invalidates Gate 3;
- Spring Backend and Core DB are the authorization and approval source of truth;
- LangGraph interrupts for human approval only at the three Gates and resumes after Spring confirms
  both approvals;
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

- administrator and `GENERAL_USER` account with fixed role;
- revocable opaque session with expiration;
- Project membership for `GENERAL_ADMIN`;
- existing Project aggregate relationship.

This specification does not reserve a Flyway revision and does not authorize DDL by itself.

## 8. Slice boundaries and roadmap effect

### `AXMS-FND-03` -- delivered reduced boundary

- implemented the two fixed roles, login/session, server actor context, and Backend/Frontend
  enforcement;
- preserved the current Local Full acceptance path through an explicit development-only profile;
- implemented valid/invalid login and role-bound 401/403 behavior;
- retained a Project-membership seam but deliberately did not apply Project narrowing for the initial
  single-customer demonstration;
- did not add `GENERAL_USER`, full member-management endpoints/UI, Approval History/Audit UI, custom
  permissions, or Coding approval nodes.

### `AXMS-CMS-01`

- add the complete administrator and `GENERAL_USER` list/invite/status/Project-membership management
  product on the FND-03 authority;
- add the fixed `GENERAL_USER` role without creating a custom-role editor.

### `AXMS-CMS-06` and `AXMS-CMS-07`

- `AXMS-CMS-06` integrates Approval History and core Audit Log query/UI with Site Release,
  Publish/Unpublish, and Rollback evidence;
- `AXMS-CMS-07` completes `GENERAL_USER` login/session and published Renderer access.

### `AXMS-FND-04`

The former broad Common Approval/Audit/Job proposal is retired as a scheduled Foundation Slice.
There is no FND-04 Wave before `AXMS-CMS-01` through `AXMS-CMS-04`. Existing Product Job behavior
remains preserved; new common primitives are introduced only by a concrete consuming Slice.

### Coding/LLM DevOps

Implement the dual-approval records, hash binding, invalidation, and LangGraph interrupt/resume in
the corresponding later Coding/LLM DevOps Slices.

## 9. Acceptance criteria

`AXMS-FND-03` is complete for the reduced single-customer demonstration when all of the following
pass:

1. A `SUPER_ADMIN` and a `GENERAL_ADMIN` can log in and log out.
2. The current-session response contains server-derived actor and fixed role information without a
   Secret or password value.
3. A `GENERAL_ADMIN` can operate customer business CMS functions without delivery-engineer approval.
4. A `GENERAL_ADMIN` receives 403 for platform technical configuration.
5. A `SUPER_ADMIN` can reach the technical configuration boundary.
6. Supplying a forged role or actor ID does not elevate authority.
7. Expired, revoked, and disabled-account sessions fail closed.
8. Existing Stage 3–5 behavior and the development-only Local Full acceptance path remain
   compatible.
9. No later CMS Approval History/Audit product feature, `GENERAL_USER`, or autonomous-coding workflow
   is incorrectly claimed as delivered by the historical FND-03 Slice.
10. Project narrowing and full member management are not claimed as implemented; those require a
    separately assigned future multi-customer Slice and `AXMS-CMS-01`, respectively.
