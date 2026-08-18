# AX Module Studio 5-person vertical-slice ownership and roadmap v0.1

> Baseline: 2026-08-18; Foundation completion and Wave 3 naming revalidated from canonical Source `origin/dev`
> Goal: minimize shared-file collisions while each owner completes user-visible Contract→Flyway→Spring→Frontend→E2E slices
> Current decision authority: [team checklist decision overlay](../product/AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md)

The first team product milestone is the assembled **CMS product**: delivered administrator Auth/RBAC,
the fixed `GENERAL_USER` target, member management, menu, content/page, board, site design/template,
direct customer-admin Site Release/Publish/Rollback, Approval History, core Audit Log, and the end-user
Renderer. A separate manual-CMS Reviewer Gate is not required. Later public-data/RAG/Model Mapping,
Coding/PathPolicy, natural-language CMS, and LLM DevOps work remains discussion-required backlog until
the CMS milestone passes and a new team decision assigns it. Autonomous coding retains exactly three
future dual-approval Gates—autonomous-coding result, PR creation, and deployment.

## 1. Operating model

1. Work is divided by user-visible vertical slice, not by Frontend/Backend/DB horizontal layer.
2. Every slice has one E2E lead. That lead drives contract, migration, Spring, Frontend, tests, and handoff to completion.
3. The Integration/Contract owner serializes shared seams; a feature lead does not directly edit a reserved seam without that lane.
4. The Orchestrator does not change for the current CMS milestone. Any later Coding contract/graph work requires the post-CMS decision Gate.
5. Post-CMS order, owner, scope, Slice IDs, dependencies, and PR order are deliberately unassigned until the team deep-dive decision is checked into Master.
6. A healthy local stack and technical fixture E2E do not satisfy a product slice Definition of Done.

Confirmed account mapping is limited to:

- 민승준 → `tmdwns0531`
- 이재욱 → `LEEJAEWOOK1`
- 정차윤 → `jcy644542` (FND-03 Backend/Frontend merged PR evidence)
- 윤서 → `HaveOffDuty` (Backend PR #4 evidence)

Do not infer 민은지's GitHub handle. Confirm it before creating a Branch, GitHub team, or CODEOWNERS
entry for that member.

## 2. People and workstreams

| Member | Primary workstream | Cross-review responsibility | Must not own alone |
|---|---|---|---|
| 민승준 | Integration/Contract owner; Flyway lane, common Error, CMS-06 Release/Approval History/Audit, Compose/bootstrap, Master handoff | all shared seams and final CMS E2E | post-CMS backlog without a new team decision |
| 정차윤 | delivered administrator Auth/RBAC; CMS-01 `GENERAL_USER` membership; CMS-07 login/Renderer | role/member isolation and user security UX | shared contracts without lane; post-CMS backlog without a new team decision |
| 이재욱 | Frontend feature architecture; CMS-02 menu; CMS-05 site design/template | App shell and browser behavior | app shell as an unreviewed private hot spot; post-CMS backlog without a new team decision |
| 민은지 | CMS-03 content/page | content/data quality and CMS evidence | post-CMS backlog without a new team decision |
| 윤서 | CMS-04 board/post | board state and authorization behavior | post-CMS backlog without a new team decision |

## 3. RACI

`A` accountable, `R` responsible, `C` required consultation, `I` informed.

| Boundary | 민승준 | 정차윤 | 이재욱 | 민은지 | 윤서 |
|---|---:|---:|---:|---:|---:|
| Current CMS public OpenAPI and JSON Schema | A/R | C | C | C | C |
| Flyway reservation, order, verification | A/R | C | I | C | C |
| App shell/router/navigation | A | C | R | I | I |
| Common Error/Auth/Approval History/Audit contract | A/R | C | C | C | C |
| Production Auth/RBAC/administrator and `GENERAL_USER` members | C | A/R | C | I | C |
| Menu/SiteTemplate/Renderer | C | C | A/R | C | I |
| Content/page | C | I | C | A/R | C |
| Board/post | C | C | C | C | A/R |
| Backend Compose/bootstrap/health | A/R | I | C | C | C |
| Master manifest/handoff | A/R | C | C | C | C |
| Per-slice E2E | A for integration gate | R for owned slices | R for owned slices | R for owned slices | R for owned slices |

Every team-member PR is approved and merged by the `tmdwns0531` Master/Admin integration account. Domain peer review is optional unless the integration owner requests it for a shared Contract, Migration, Auth/Security, future Coding dual-approval, or Compose seam. Master/Admin-authored governance or integration changes may use the intentional Repository Admin Ruleset bypass after recorded validation and do not require an additional teammate approval.

## 4. Hot spots and collision control

### 4.1 Current hot spots

| Repository | Hot spot | Current size/role | Rule |
|---|---|---|---|
| Backend | `ProductStore.java` | 992 lines; Project/Connector/Knowledge/RAG/Job SQL and idempotency | no new product domain added before extraction |
| Backend | `ProductApiContract.java` | 336 lines; all product DTOs | split by domain under Contract lane |
| Backend | `ProductApiController.java` | 252 lines; product operations | extract one domain at a time with characterization tests |
| Backend | `contracts/public/openapi.yaml` | 1,796 lines, source of truth | one active Contract reservation only |
| Backend | `contracts/validation/validate_contracts.py` | 2,485 lines | validator changes are separate preparation work |
| Backend | `compose.dev.yaml`, `scripts/bootstrap-dev.ps1`, `scripts/health.ps1` | integrated runtime | Integration owner only; never a feature convenience edit |
| Frontend | `LocalFullWorkspace.tsx` | 636 lines; all product workflow UI | split into feature route before new CMS features |
| Frontend | `product-api.ts` | 555 lines; DTO/transport/operations | split shared transport from generated/domain clients |
| Frontend | `styles.css` | 457 lines; shell and features mixed | split tokens/shell/feature styles |
| Frontend | `App.tsx` | shell/hash routing/navigation | App-shell owner only |
| Orchestrator | `tool_gateway.py`, `model_gateway.py` | 936/814 lines | separate contract DTO, HTTP client, validation before tool expansion |
| Orchestrator | `graph.py`, `contracts.py` | fixed graph/shared models | Coding lane only; Product AI never added here |
| Master | handoff/manifest/ledger | shared governance | Integration owner updates after source status is verified |

### 4.2 Behavior-preserving preparation target

```text
Backend
src/main/java/org/urizo/axmodulestudio/backend/
├── common/{web,error,auth}/
├── project/
├── connector/
├── knowledge/
├── rag/
├── job/
├── cms/{member,menu,content,board,site,release}/
└── coding/{repository,pathpolicy,tool,devops}/

Frontend
src/
├── app/{AppShell,routes,navigation}/
├── shared/api/{http,error,session}/
├── features/{local-full,providers,auth,members,menus,content,boards,site-design,releases,rag-evaluation,model-routing,coding}/
└── styles/{tokens,shell,components}/

Orchestrator
src/axms_coding_orchestrator/
├── contracts/{events,worker,model_turn,tool}.py
├── gateways/{worker_client,model_client,tool_client}.py
├── graphs/coding.py
└── runtime/{service,queue,heartbeat,checkpoint}.py
```

Extraction is incremental. Existing facade classes remain until one domain at a time is characterized and routed through the new package. A preparation PR must not mix behavior changes.

## 5. Phase roadmap

Repository PR shorthand:

- `B`: Backend
- `F`: Frontend
- `O`: Orchestrator
- `M`: Master
- `B→F`: compatible Backend contract/runtime before Frontend consumer
- `B-expand→O→F`: compatible coding contract expansion, Orchestrator consumer, then Frontend

### Phase 0 — Foundation and safe seams

| Slice | E2E lead | User-visible/engineering outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-FND-00` Workspace governance | 민승준 | Master manifest, handoff, traceability, safe bootstrap | `M/**` | none; `M` |
| `AXMS-FND-01` Backend characterization/seam | 민승준 | **DONE**: existing Project/Connector/Knowledge/RAG/Job behavior preserved through domain delegates | Backend `project/connector/knowledge/rag/job`, current facade tests | Backend PR #6 merged; `B` |
| `AXMS-FND-02` Frontend app seam | 이재욱 | **DONE**: existing console screens preserved under route/feature boundaries | Frontend `app`, `features/local-full`, `features/providers`, `shared/api` | Frontend PR #3 merged; `F` |
| `AXMS-FND-03` Production Auth/RBAC | 정차윤 | **DONE, reduced single-customer scope**: fixed roles, login/session, Backend role enforcement and Frontend role-aware UX; no Project narrowing | public contract/fixtures; Flyway identity/RBAC; Backend `common/auth`; Frontend `features/auth` | Backend PR #7 → Frontend PR #4 merged; `B→F` |
| `AXMS-FND-04` Broad Approval/Audit/Job primitive | none | **RETIRED**: not a scheduled Foundation Slice or separate Wave | Approval History/core Audit are delivered through consuming CMS Slices; future Coding approvals require a later decision | no implementation or PR |

The Foundation sequence through FND-03 is complete. The original Wave 2 / FND-04 work is retired and
later Waves are not renumbered. **Wave 3 is CMS-01–04**, the next parallel product Wave. An explicit owner
request may start a named Slice; a separate Task Packet is optional refinement, while shared
Contract/Flyway reservations remain mandatory before editing those shared seams. FND-03 completion
details and the deliberate Project-isolation reduction are fixed in the later completion decision; do
not overstate the delivered boundary.

### Phase 1 — Five manual CMS domains, Release, Renderer

| Slice | E2E lead | Outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-CMS-01` Member management | 정차윤 | fixed `GENERAL_USER`; administrator/user list, invite, status, Project membership, permission failure; core account Audit events | Backend `cms/member`; Frontend `features/members` | FND-03; `B→F` |
| `AXMS-CMS-02` Manual menu | 이재욱 | `GENERAL_ADMIN` MenuSpec Draft/Version, duplicate-path validation, preview, direct publish | Backend `cms/menu`; Frontend `features/menus` | FND-03; `B→F` |
| `AXMS-CMS-03` Manual content/page | 민은지 | `GENERAL_ADMIN` Content/PageSpec Draft/Version, component/data binding, preview, direct publish | Backend `cms/content`; Frontend `features/content` | FND-03; `B→F` |
| `AXMS-CMS-04` Manual board | 윤서 | `GENERAL_ADMIN` Board/Post state, role enforcement, CRUD/publish, soft delete | Backend `cms/board`; Frontend `features/boards` | FND-03; `B→F` |
| `AXMS-CMS-05` Site design/template | 이재욱 | registry-constrained Header/Footer/Layout/Token, SiteTemplateSpec Version, desktop/mobile preview | Backend `cms/site`; Frontend `features/site-design` | CMS-02/03 reference contracts; `B→F` |
| `AXMS-CMS-06` Site Release and operation history | 민승준 | immutable versions directly published/rolled back by assigned `GENERAL_ADMIN`; integrated Approval History/core Audit Log query and UI | Backend `cms/release`, shared audit seam; Frontend `features/releases`, `features/audit` | CMS-01–05 core events; `B→F` |
| `AXMS-CMS-07` General User Renderer | 정차윤 | `GENERAL_USER` login/session; published route reads active Site Release only; Draft is never exposed | Backend `site/runtime`; Frontend `site-runtime` | CMS-06; `B→F` |

CMS-01–04 run in parallel after their contracts are reserved. Each emits applicable core Audit events;
Flyway creation and merge still use one lane. CMS-05→06→07 are sequential because of
reference/publish invariants. Integrated CMS acceptance opens the team deep-dive planning Gate, not an
automatic next implementation Phase.

### Post-CMS backlog — discussion required

The former Phase 2 through Phase 5 tables are no longer an approved execution sequence or ownership
assignment. They are reduced to the following capability inventory for the post-CMS team deep-dive.

| Capability inventory | Current evidence boundary | Topics the team must newly decide | Status |
|---|---|---|---|
| Real public-data Connector; RAG Dataset/Evaluation/Compare/Tuning; Provider/Model Mapping | deterministic Connector/RAG and model-selection foundations only | target domains, metrics, thresholds, model/embedding choices, Slice structure, owner, dependencies, PR order | `DISCUSSION_REQUIRED`; not assigned |
| Repository registry; PathPolicy; real read/write/diff/test/build/preview Coding Tools | Coding Harness and fixture read foundation only | repository access, fixed policies, Tool scope, test/build boundary, Slice structure, owner, dependencies, PR order | `DISCUSSION_REQUIRED`; not assigned |
| Natural-language CMS | no product implementation | supported CMS domains, ActionPlan/Draft/Diff/Preview boundary, publication UX, Slice structure, owner, dependencies, PR order | `DISCUSSION_REQUIRED`; not assigned |
| LLM DevOps | no real product implementation | exact execution scope, repository/cloud boundary, evidence UX, Slice structure, owner, dependencies, PR order | `DISCUSSION_REQUIRED`; not assigned |
| External-user chatbot and remaining presentation flows | incomplete or not implemented | authentication, RAG dependency, first/second Vertical Slice, demo order, owner, dependencies | `DISCUSSION_REQUIRED`; not assigned |

The post-CMS discussion may reuse, rename, split, combine, or retire former candidate Slice IDs. No
former owner or Phase number carries forward automatically. The new Git decision must identify the
confirmed order, owner, scope, Slice IDs, target repositories, dependencies, shared seams, and PR order.

One product invariant is already fixed for any future LLM DevOps design: dual approval occurs at
exactly three Gates—autonomous-coding result, PR creation, and deployment. Internal
request→limited patch→one allowlisted test→result execution is uninterrupted. Manual PR merge is a Git
workflow action, not a fourth product Gate. Automatic merge, unapproved deployment, free shell,
operational source mutation, and Python-held Git credentials remain prohibited.

## 6. Parallel windows

| Window | Parallel work allowed | Serialized seam |
|---|---|---|
| P0-A | FND-01 Backend seam + FND-02 Frontend seam | no contract/DB behavior change |
| P1-A | CMS-01/02/03/04 feature-local work after FND-03 | Contract reservation and Flyway merge |
| P1-B | CMS-05→CMS-06→CMS-07 sequential completion | reference/version, Release, Audit, Renderer, and integrated acceptance |
| Post-CMS | none until a new checked-in team decision | all remaining order/owner/scope/Slice/dependency/PR seams |

No two owners edit public OpenAPI, Flyway directory, app shell/navigation, common Auth/Error,
Approval History/Audit, Compose/bootstrap, or Master manifest concurrently. Post-CMS backlog files do
not become active hot spots until the new team decision assigns them.

## 7. Proposed CODEOWNERS model

Create Organization teams only after confirming membership and repository access:

- `@urizo-final-org/ax-integration-contract`
- `@urizo-final-org/ax-frontend`
- `@urizo-final-org/ax-backend`
- `@urizo-final-org/ax-data-rag`
- `@urizo-final-org/ax-coding-runtime`
- `@urizo-final-org/ax-security-approval`
- `@urizo-final-org/ax-db-migrations`
- `@urizo-final-org/ax-master-governance`

Recommended patterns:

```text
# Backend
/contracts/public/** @urizo-final-org/ax-integration-contract @urizo-final-org/ax-frontend
/contracts/coding-agent/** @urizo-final-org/ax-integration-contract @urizo-final-org/ax-coding-runtime
/src/main/resources/db/migration/** @urizo-final-org/ax-db-migrations @urizo-final-org/ax-integration-contract
/src/main/java/org/urizo/axmodulestudio/backend/common/auth/** @urizo-final-org/ax-security-approval @urizo-final-org/ax-integration-contract
/src/main/java/org/urizo/axmodulestudio/backend/coding/** @urizo-final-org/ax-coding-runtime @urizo-final-org/ax-security-approval
/compose.dev.yaml @urizo-final-org/ax-integration-contract
/scripts/** @urizo-final-org/ax-integration-contract

# Frontend
/src/App.tsx @urizo-final-org/ax-integration-contract @urizo-final-org/ax-frontend
/src/app/** @urizo-final-org/ax-integration-contract @urizo-final-org/ax-frontend
/src/features/auth/** @urizo-final-org/ax-security-approval @urizo-final-org/ax-frontend
/src/features/coding/** @urizo-final-org/ax-coding-runtime @urizo-final-org/ax-frontend

# Orchestrator
/src/axms_coding_orchestrator/contracts/** @urizo-final-org/ax-integration-contract @urizo-final-org/ax-coding-runtime
/src/axms_coding_orchestrator/graphs/** @urizo-final-org/ax-coding-runtime @urizo-final-org/ax-integration-contract

# Master
/AGENTS.md @urizo-final-org/ax-master-governance @urizo-final-org/ax-integration-contract
/docs/handoff/** @urizo-final-org/ax-master-governance @urizo-final-org/ax-integration-contract
/repository-manifest.json @urizo-final-org/ax-master-governance @urizo-final-org/ax-integration-contract
/scripts/** @urizo-final-org/ax-master-governance @urizo-final-org/ax-integration-contract
```

This is a proposal, not an active repository rule. Creating teams, adding CODEOWNERS, or changing rulesets requires separate authorization and readback verification.

## 8. Flyway UTC timestamp reservation

1. Before DB work, read current `origin/dev` migration HEAD and this Master ledger.
2. Submit Slice ID, owner, lower-snake description, expected Backend PR, dependencies, and target date to the Integration/Contract owner.
3. The owner allocates a UTC timestamp greater than every merged/reserved revision.
4. Only one `ACTIVE` reservation is preferred. A dependency chain may reserve multiple ordered revisions, but merge order must match timestamps.
5. Filename: `VYYYYMMDDHHMMSS__lower_snake_description.sql`.
6. Ledger states: `RESERVED`, `PR_OPEN`, `MERGED`, `ABANDONED`.
7. Reservation expiry: two working days unless renewed. Never reuse an expired or abandoned timestamp.
8. Never rename or modify a revision applied to any team/shared verification DB; add a forward revision.
9. Required DB gate: empty DB→HEAD, exact previous `origin/dev`→HEAD, single successful history/checksum, repeat pending zero/change zero, runtime DDL denied, framework auto-DDL zero, required extension/index/constraint present.
10. Migration PR requires the Integration/Contract owner and DB reviewer; later timestamps cannot merge before their dependencies.

The current baseline is recorded in [FLYWAY_RESERVATION_LEDGER.md](FLYWAY_RESERVATION_LEDGER.md).

## 9. Slice, branch, and cross-repository PR contract

Slice IDs use a stable phase/domain identifier, for example:

```text
AXMS-CMS-02
AXMS-CMS-03
AXMS-CMS-06
```

Branches preserve the approved rule:

```text
feature/<confirmed-github-id>_<same-work-slug>_<version>
```

All repositories in one Slice use the same work slug/version. Each changed repository has its own commit, push, and PR. A PR body includes:

```text
Slice-ID:
Slice-Version:
Lead:
Repository:
Connected PRs:
Contract Version:
Migration Revision / N/A:
Depends On:
Merge Order:
Independently Mergeable: yes/no
Feature Flag / Compatibility:
Rollback:
Verification:
```

Default merge order:

- Public API: compatible Backend expand/implementation → Frontend consumer.
- Coding internal contract: Backend expand → Orchestrator consumer → Frontend.
- Breaking removal: separate contract-cleanup slice only after every consumer migrated.
- Master handoff/manifest: last, after merged source SHAs and tests are known.

Never rely on simultaneous merge timing. Use `expand → migrate consumers → contract/remove`.

## 10. Definition of Done

Every Slice must satisfy:

- user scenario plus success, validation failure, 401, 403, 409/idempotency, timeout/retry where applicable;
- public/internal contract and valid/invalid golden fixtures;
- server-derived actor and Project scope, never client-asserted authority;
- all Flyway gates when DB changes;
- Backend format/static/unit/integration/context/contract checks;
- Frontend lint/type/unit/production build and generated-client diff;
- Orchestrator format/lint/type/pytest/lock/contract/checkpoint/interrupt/resume when changed;
- structured `traceId`, `projectId`, `actor`, relevant version, and `jobId`/candidate SHA;
- no secret, credential, Prompt raw content, actual customer data, or build output committed;
- compatible Backend-first merge that does not break current consumers;
- same-origin Slice E2E plus Stage 3–5 regression proportional to impact;
- Master/Admin approval for team-member PRs, or recorded validation evidence for a Master/Admin-authored bypass, plus cross-repository PR links;
- post-merge Master handoff/manifest update with exact verified state.

Additional phase gates:

| Phase | Additional DoD |
|---|---|
| CMS milestone | fixed `GENERAL_USER`; `GENERAL_ADMIN` Draft/version/preview/direct publish/rollback; Draft never public; no separate Reviewer or `SUPER_ADMIN` approval Gate; Approval History and core Audit Log screens; General User Renderer. |
| Post-CMS backlog | detailed DoD is `TBD` at the team deep-dive and must be checked into Master before implementation. |
| Future LLM DevOps invariant | exactly three Gates—autonomous-coding result, PR creation, deployment—require distinct `GENERAL_ADMIN` and `SUPER_ADMIN` approvals; internal request/patch/test/result steps do not pause; automatic merge and unapproved deploy remain prohibited. |
