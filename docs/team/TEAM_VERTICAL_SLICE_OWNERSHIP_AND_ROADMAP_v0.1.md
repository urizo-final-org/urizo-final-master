# AX Module Studio 5-person vertical-slice ownership and roadmap v0.1

> Baseline: 2026-08-18; Foundation completion and Wave 3 naming revalidated from canonical Source `origin/dev`
> Goal: minimize shared-file collisions while each owner completes user-visible Contract→Flyway→Spring→Frontend→E2E slices

The first team product milestone is not infrastructure expansion. It is the assembled **manual administrator CMS product**: two-role production Auth/RBAC, member management, menu, content/page, board, site design/template, direct customer-admin Site Release/Publish/Rollback, and the end-user Renderer. General manual-CMS approval/rejection and a unified Audit product are not part of the initial MVP. Later RAG, Coding, natural-language CMS, and LLM DevOps work does not open until this milestone's dependency gates are satisfied. Autonomous coding remains the exception and requires distinct `GENERAL_ADMIN` and `SUPER_ADMIN` approvals at every side-effect Gate under the [Auth/RBAC MVP specification](../product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md).

## 1. Operating model

1. Work is divided by user-visible vertical slice, not by Frontend/Backend/DB horizontal layer.
2. Every slice has one E2E lead. That lead drives contract, migration, Spring, Frontend, tests, and handoff to completion.
3. The Integration/Contract owner serializes shared seams; a feature lead does not directly edit a reserved seam without that lane.
4. The Orchestrator joins only Coding contract/graph slices. Product RAG, manual CMS, and natural-language CMS stay in Spring.
5. Natural-language CMS and LLM DevOps are deliberately split among multiple owners.
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
| 민승준 | Integration/Contract owner; public/coding contracts, Flyway lane, common Error, future Coding dual approval, Compose/bootstrap, Master manifest/handoff | all shared seams and final integrated E2E | natural-language CMS whole; LLM DevOps whole |
| 정차윤 | Production Auth/RBAC, members, Project membership, security UX | role/project isolation and dual-approval consumer policy | shared contracts without lane; LLM DevOps whole |
| 이재욱 | Frontend feature architecture, menu/site design, Renderer, coding Diff/PR UX | App shell and browser behavior | app shell as an unreviewed private hot spot; natural-language CMS whole |
| 민은지 | real Connector, content/page, RAG/Model Mapping, test/build/preview evidence | data quality and execution evidence | RAG as one large feature; natural-language CMS whole |
| 윤서 | Repository/PathPolicy, Coding Runtime/Orchestrator, RAG evaluation, selected board slice | coding safety and consumer contract parity | Coding/LLM DevOps whole |

## 3. RACI

`A` accountable, `R` responsible, `C` required consultation, `I` informed.

| Boundary | 민승준 | 정차윤 | 이재욱 | 민은지 | 윤서 |
|---|---:|---:|---:|---:|---:|
| Public/Coding OpenAPI and JSON Schema | A/R | C | C | C | C |
| Flyway reservation, order, verification | A/R | C | I | C | C |
| App shell/router/navigation | A | C | R | I | I |
| Common Error/Auth and future Coding dual-approval contract | A/R | C | C | C | C |
| Production Auth/RBAC/members | C | A/R | C | I | C |
| Menu/SiteTemplate/Renderer | C | C | A/R | C | I |
| Connector/content/page/RAG/Model Mapping | C | I | C | A/R | C |
| PathPolicy/Coding contract/Orchestrator | C | C | C | C | A/R |
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
| `AXMS-FND-04` Broad Approval/Audit/Job primitive | none | **RETIRED**: not a scheduled Slice; no general manual-CMS Approval/Audit product and no separate Foundation Wave | N/A; later Coding dual approval belongs to the consuming Coding/LLM DevOps Slices | no implementation or PR |

The Foundation sequence through FND-03 is complete. The original Wave 2 / FND-04 work is retired and
later Waves are not renumbered. **Wave 3 is CMS-01–04**, the next parallel product Wave. An explicit owner
request may start a named Slice; a separate Task Packet is optional refinement, while shared
Contract/Flyway reservations remain mandatory before editing those shared seams. FND-03 completion
details and the deliberate Project-isolation reduction are fixed in the later completion decision; do
not overstate the delivered boundary.

### Phase 1 — Five manual CMS domains, Release, Renderer

| Slice | E2E lead | Outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-CMS-01` Member management | 정차윤 | list/invite/status/Project membership; permission failure | Backend `cms/member`; Frontend `features/members` | FND-03; `B→F` |
| `AXMS-CMS-02` Manual menu | 이재욱 | `GENERAL_ADMIN` MenuSpec Draft/Version, duplicate-path validation, preview, direct publish | Backend `cms/menu`; Frontend `features/menus` | FND-03; `B→F` |
| `AXMS-CMS-03` Manual content/page | 민은지 | `GENERAL_ADMIN` Content/PageSpec Draft/Version, component/data binding, preview, direct publish | Backend `cms/content`; Frontend `features/content` | FND-03; `B→F` |
| `AXMS-CMS-04` Manual board | 윤서 | `GENERAL_ADMIN` Board/Post state, role enforcement, CRUD/publish, soft delete | Backend `cms/board`; Frontend `features/boards` | FND-03; `B→F` |
| `AXMS-CMS-05` Site design/template | 이재욱 | registry-constrained Header/Footer/Layout/Token, SiteTemplateSpec Version, desktop/mobile preview | Backend `cms/site`; Frontend `features/site-design` | CMS-02/03 reference contracts; `B→F` |
| `AXMS-CMS-06` Site Release | 민승준 | immutable Menu/Page/SiteTemplate versions atomically published/rolled back directly by assigned `GENERAL_ADMIN` | Backend `cms/release`; Frontend `features/releases` | CMS-02/03/05; `B→F` |
| `AXMS-CMS-07` End-user Renderer | 정차윤 | public route reads active Site Release only; Draft is never exposed | Backend `site/runtime`; Frontend `site-runtime` | CMS-06; `B→F` |

CMS-01–04 may prepare feature-local code and mocks in parallel after their contracts are reserved. Flyway creation and merge still use one lane. CMS-05→06→07 are sequential because of reference/publish invariants.

### Phase 2 — Real data, RAG quality, Model Mapping

| Slice | E2E lead | Outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-DATA-01` Real public-data Connector | 민은지 | actual HTTPS adapter, domain configuration, SSRF/DNS/redirect/size/timeout/pagination/mapping; fixture retained as test adapter | Backend `connector`, `integration/publicdata`; Frontend `features/connectors` | FND-03; `B→F` |
| `AXMS-RAG-01` Evaluation Dataset/Run | 윤서 | Dataset/Question Versions; Hit@K, MRR, Citation, Refusal, latency history and artifacts | Backend `rag/evaluation`; Frontend `features/rag-evaluation` | DATA-01 and current Knowledge build; `B→F` |
| `AXMS-RAG-02` Compare/Threshold/Tuning | 정차윤 | candidate vs Active comparison, versioned threshold warning/block, tuning evidence | same RAG packages | RAG-01; `B→F` |
| `AXMS-MAP-01` Task Provider/Model Mapping | 민은지 | fixed use-case mapping, capability validation, version activation, Job snapshot; no graph rewiring | Backend `ai/gateway/mapping`; Frontend `features/model-routing` | FND-03 and Provider CMS; `B→F` |

Deterministic retrieval metrics must work without an `EVALUATION_JUDGE`. Paid judge calls and LangSmith are optional, approval-gated, and must not determine base readiness. Orchestrator does not change in this phase.

### Phase 3 — Repository, PathPolicy, real Coding Tools

| Slice | E2E lead | Outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-COD-01` Repository registry/tree | 윤서 | Super Admin sees registered repository status and a read-only tree without credential disclosure | Backend `coding/repository`; Frontend `features/coding/repositories` | FND-03; `B→F` |
| `AXMS-COD-02` PathPolicy Version | 정차윤 | tree-checkbox read/write rules, immutable version, technical evidence, fixed non-overridable denylist | public/coding schemas; Flyway; Backend `coding/pathpolicy`; Frontend coding policy | COD-01; `B-expand→O if context changes→F` |
| `AXMS-COD-03` Real read Tools | 윤서 | `list_tree`, `search_code`, `read_file` with repository/project/policy/realpath enforcement | Backend Tool executors; Orchestrator tool client/graph; Frontend result UI | COD-02; `B-expand→O→F` |
| `AXMS-COD-04` Mutation Tools | 이재욱 | isolated-worktree `write_file/apply_patch`; whole-patch rejection on one invalid path; traversal/symlink/escape blocked | Backend mutation executors; Orchestrator nodes; Frontend Diff UX | COD-03; `B-expand→O→F` |
| `AXMS-COD-05` Diff/Test/Build/Preview | 민은지 | candidate-SHA diff and async allowlisted checks with timeout/retry/evidence hashes | Backend check/preview executors; Orchestrator nodes; Frontend evidence/preview | COD-04; `B-expand→O→F` |
| `AXMS-COD-06` Coding graph integration | 윤서 | plan→patch→test→preview interrupt/resume with duplicate side effect zero | Backend coding lifecycle; Orchestrator fixed graph; Frontend job timeline | COD-03–05; `B-expand→O→F` |

Repository tools are sliced in the order `tree/read → write/apply_patch/diff → test → build → preview`. Each Tool slice includes contract, required evidence persistence, Spring authority, Orchestrator consumer, UI result, and E2E. The Orchestrator never receives Provider/Git/Docker credentials or final authorization.

### Phase 4 — Natural-language CMS on manual CMS

| Slice | E2E lead | Outcome | Expected paths | Dependency and PR order |
|---|---|---|---|---|
| `AXMS-NAT-01` ActionPlan/Draft/Diff primitive | 민승준 | natural language→typed ActionPlan→structured Draft→ValidationReport→Diff; model/prompt/policy snapshot | Backend `cms/natural`; shared public schemas; Frontend `features/natural-cms` | manual CMS + MAP-01; `B→F` |
| `AXMS-NAT-02` Natural-language Menu | 이재욱 | MenuSpec Draft, validation, Diff, preview; no direct active-pointer mutation | Menu packages and feature route | NAT-01 + CMS-02; `B→F` |
| `AXMS-NAT-03` Natural-language Content/Page | 민은지 | Content/PageSpec Draft, component/data/Knowledge binding, preview | content/page packages and feature route | NAT-01 + CMS-03; `B→F` |
| `AXMS-NAT-04` Natural-language SiteTemplate | 윤서 | SiteTemplateSpec Draft constrained to Registry/Token; desktop/mobile preview | site packages and feature route | NAT-01 + CMS-05; `B→F`; no Orchestrator |
| `AXMS-NAT-05` Combined preview/publish/rollback | 정차윤 | assigned `GENERAL_ADMIN` evaluates Diffs and directly publishes or rolls back one Site Release | release UI | NAT-02–04 + CMS-06/07; `B→F` |

After NAT-01 is merged, NAT-02–04 can run in parallel in disjoint feature packages. Identity/role changes are not natural-language actions. Raw HTML/CSS/JS remains prohibited.

### Phase 5 — LLM DevOps after real Coding/PathPolicy

| Slice | E2E lead | Outcome | Dependency and PR order |
|---|---|---|---|
| `AXMS-DVO-01` Scope/Context dual approval | 정차윤 | request→Context Pack→read/write scope→distinct `GENERAL_ADMIN` business and `SUPER_ADMIN` technical approvals | COD-02/03/06; `B-expand→O→F` |
| `AXMS-DVO-02` Patch/Diff dual approval | 윤서 | both roles approve the candidate SHA and policy hash; any change invalidates both approvals | COD-04/06 + DVO-01; `B-expand→O→F` |
| `AXMS-DVO-03` Test/Build/Preview dual approval | 민은지 | allowlisted commands and evidence hash require both roles, with retry and expiry | COD-05 + DVO-02; `B-expand→O→F` |
| `AXMS-DVO-04` PR creation dual approval | 이재욱 | only a candidate approved by both roles can push a feature branch/open PR; merge stays manual | DVO-03; `B-expand→O→F` |
| `AXMS-DVO-05` CI/deploy dual manual gate | 민승준 | CI readback and deploy require both roles; staging adapter keeps the previous image on failure | DVO-04; external Cloud/credentials require separate approval |
| `AXMS-DVO-06` Dual-approval evidence timeline | 정차윤 | Scope/Patch/Test/Preview/PR/CI/Deploy actors, SHA, policy, evidence, two approvals, rejection, and invalidation | DVO-01–05; `B-expand→O→F` |

Automatic merge, unapproved deployment, free shell, operational source mutation, and Python-held Git credentials remain prohibited.

## 6. Parallel windows

| Window | Parallel work allowed | Serialized seam |
|---|---|---|
| P0-A | FND-01 Backend seam + FND-02 Frontend seam | no contract/DB behavior change |
| P1-A | CMS-01/02/03/04 feature-local work after FND-03 | Contract reservation and Flyway merge |
| P2-A | RAG-01 UI mock + MAP-01 UI mock while DATA-01 Backend stabilizes | public contract and DB revisions |
| P3-A | COD feature UI components and executor unit harnesses | coding schema, PathPolicy model, graph |
| P4-A | NAT-02/03/04 after NAT-01 | shared ActionPlan/Draft contract and release |
| P5-A | UI/evidence views for subsequent DevOps stages | Coding job state machine and coding contracts |

No two owners edit public OpenAPI, Flyway directory, app shell/navigation, common Auth/Error, future Coding dual-approval, Compose/bootstrap, or Master manifest concurrently.

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
AXMS-COD-04
AXMS-DVO-03
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
| Manual CMS | `GENERAL_ADMIN` Draft/version/preview/direct publish/rollback; Draft never public; no `SUPER_ADMIN` approval Gate. |
| RAG | Dataset/metric/threshold/compare history; Active pointer remains unchanged on failure. |
| Model Mapping | fixed use cases only; capability mismatch blocked; mapping version snapshotted into Job. |
| Coding | traversal/symlink/denylist/escape blocked; policy/candidate hashes bound; duplicate side effect zero. |
| Natural-language CMS | ActionPlan→Draft→validation→Diff/Preview→`GENERAL_ADMIN` publish→Release→rollback; raw HTML/CSS/JS blocked. |
| LLM DevOps | every side-effect Gate requires distinct `GENERAL_ADMIN` and `SUPER_ADMIN` approvals; changed scope/SHA/policy/evidence invalidates both; automatic merge and unapproved deploy zero. |
