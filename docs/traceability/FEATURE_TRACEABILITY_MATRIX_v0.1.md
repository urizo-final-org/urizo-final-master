# AX Module Studio AS-IS/TO-BE feature traceability matrix v0.1

> Baseline date: 2026-08-18
> Product authority: preserved Project Spec, delivered FND-03 evidence, and the later team checklist decision overlay
> Implementation checkpoint: v1.0 handoff; Backend `e0a702d`, Frontend `0ba4295`, Orchestrator `eaeb3a3`

## 1. Status vocabulary

| Status | Meaning |
|---|---|
| `IMPLEMENTED` | The current local scope connects contract, persistence where needed, runtime/UI, and verification evidence. |
| `FOUNDATION_ONLY` | A reusable seam, field, state, or technical path exists, but the user-visible product requirement is incomplete. |
| `NOT_IMPLEMENTED` | The required product boundary is absent. |
| `N/A` | That repository/runtime is not required for this feature under the approved architecture. |
| `RECORDED_PASS` | v0.6 records the test as passed; this rebaseline did not rerun the destructive/restart/failure suites. |

Rules of interpretation:

- A flexible schema does not prove that a real adapter exists.
- A table/status does not prove that the complete workflow exists.
- A healthy container does not prove product feature completion.
- A fixture E2E proves only the deterministic fixture slice.
- Contract names for future Tools do not prove that the Tools execute.

## 2. Evidence index

Paths are relative to their owning source repository unless noted otherwise.

| ID | Evidence |
|---|---|
| E1 | Product requirements: handoff package `AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`, especially §§4–7, 9–18, 25, 31–34. |
| E2 | Public contract: Backend `contracts/public/openapi.yaml`; 27 operations under Health, Projects, Connectors, Knowledge, RAG, Jobs. |
| E3 | Core product schema: Backend Flyway `V20260811210000__create_stage3_product_core.sql` and `V20260811211500__create_product_job_outbox_and_batch.sql`. |
| E4 | Fixture/data path: Backend `DeterministicConnectorFixture.java`, `ProductBatchService.java`, `ProductStore.java`. The adapter uses `fixture.invalid`; evaluation assigns score 100. |
| E5 | Current UI: Frontend `App.tsx`, `LocalFullWorkspace.tsx`, `ProviderSettings.tsx`; only two acceptance-console screens. |
| E6 | Local Provider CMS: Backend `dev/cms/**`, Flyway `V20260811141000__create_local_provider_secret_store.sql`, Frontend `api.ts` and `ProviderSettings.tsx`. |
| E7 | Development-only auth compatibility: Backend `ProductAuthFilter.java`, `ProductLocalAccess.java`, `ProductSessionController.java`; retained only behind the `dev-session` profile for local acceptance. |
| E8 | Coding contract/runtime gap: `contracts/coding-agent/tool-request.schema.json` names `read_file/search_code/apply_patch/run_check`; `CodingToolService.java` and Flyway enforce fixture `README.md` `read_file`. |
| E9 | Orchestrator: `graph.py`, `queue.py`, `checkpoint.py`; fixed Model Turn→read fixture→approval→complete flow. |
| E10 | Model foundation: Backend `ProviderCapabilityConfiguration.java`, `CodingModelTurnService.java`; code-configured registry and first eligible CHAT candidate, not DB task mapping. |
| E11 | Integrated runtime/E2E: Backend `compose.dev.yaml`, `scripts/verify-full-local-e2e.ps1`, `scripts/health.ps1`. |
| E12 | Recorded verification: handoff package `AX_Module_Studio_IMPLEMENTATION_SESSION_HANDOFF_v0.6.md`. |
| E13 | Historical administrator Auth/RBAC MVP: Master `docs/product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md`; delivered `SUPER_ADMIN`/`GENERAL_ADMIN`, direct customer CMS operation, future Coding dual approval. |
| E14 | FND-03 implementation and later scope decision: Backend PR #7 at `e0a702d`, Frontend PR #4 at `0ba4295`, and Master `AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md`; production login/roles implemented, Project narrowing deliberately omitted for the single-customer demo, FND-04 retired. |
| E15 | Current team checklist overlay: Master `docs/product/AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md`; fixed `GENERAL_USER`, Approval History/core Audit MVP, CMS-first execution plus post-CMS planning Gate, and exactly three LLM DevOps dual-approval Gates. |

No implemented identifiers were found for `GENERAL_USER`, `menu_version`, `page_version`,
`site_template`, `site_release`, general `approval`, general `audit_log`, `golden_question`,
`model_mapping`, or `path_policy_version`. FND-03 adds administrator account, session, role, and
membership persistence, but Project narrowing is not active in the approved single-customer
demonstration. Approval History/core Audit are now MVP requirements under E15 but remain unimplemented.
Coding-specific approval fragments still do not satisfy the later three-Gate two-account rule.

## 3. Confirmed AS-IS

| ID | Capability | Contract | DB | Backend | Frontend | Orchestrator | E2E | Overall |
|---|---|---|---|---|---|---|---|---|
| A1 | Local-full infrastructure | Health/readiness in E2 | Core Flyway + separate checkpoint DB | Backend-owned Compose, limits, health E11 | Nginx same-origin app | Valkey worker/checkpoint health | `RECORDED_PASS`: health, restart, failure gates E12 | `IMPLEMENTED` local foundation |
| A2 | Project technical slice | create/list/get E2 | `app.project` E3 | Controller/Service/Store | create/select/restore console E5 | N/A | `RECORDED_PASS` | `IMPLEMENTED`; current FND-03 role enforcement applies, but no Project narrowing |
| A3 | Connector version/preview/activate/sync | ConnectorSpec-shaped API E2 | connector/version/config JSON E3 | `fixture.invalid` only E4 | fixed fixture form E5 | N/A | three fixture documents pass | `FOUNDATION_ONLY` for real Connector |
| A4 | Knowledge build/version/activate/rollback | Knowledge operations E2 | base/version/document/chunk/vector E3 | six-phase Batch, active pointer | build/version/activate/rollback console | N/A | `RECORDED_PASS` | `IMPLEMENTED` deterministic technical slice |
| A5 | RAG citation/refusal | chatbot/query/citation/refusal E2 | active-version documents/chunks | server active pointer; deterministic grounding/refusal E4 | query/citations/refusal view | N/A | `RECORDED_PASS` | `IMPLEMENTED` fixture RAG, not evaluated product quality |
| A6 | Authoritative Product Job | list/get/cancel/retry E2 | product job, outbox, Batch metadata E3 | state/recovery/retry | Product Job panel | N/A | `RECORDED_PASS` | `IMPLEMENTED` Product lane |
| A7 | Coding Harness | lifecycle/model/tool contracts | job/command/lease/tool execution | claim, lease, heartbeat, Model/Tool gateway | no Coding UI | reliable queue, encrypted checkpoint, interrupt/resume E9 | `RECORDED_PASS` | `IMPLEMENTED` harness foundation only |
| A8 | Provider Credential local CMS | internal-dev boundary, not public product API | encrypted secret and connection audit | local-only store/test E6 | OpenAI/Google/Anthropic form | N/A | three VERIFIED states recorded | `IMPLEMENTED(local)`; no Project scope/Model Mapping |
| A9 | Frontend product status | Auth login/me/logout consumer plus existing APIs | N/A | consumes actual Spring API | login/session expiry, role display/navigation, `Local Full Workflow`, `LLM Providers` | not exposed | 20 tests, typecheck/build, two-role browser checks, 13-step Stage 3–5 regression E14 | Auth UI implemented; remaining manual CMS product screens absent |
| A10 | Authentication/authorization | production login/logout/me and Bearer/error shapes | administrator account, role, session, membership tables | centralized production authentication and route/role enforcement; Provider credential boundary protected | login/logout/session expiry and role-aware navigation | Coding role snapshot remains a separate legacy consumer | Backend 184 tests after guard fix plus HTTP role checks; Frontend evidence E14 | `IMPLEMENTED` for the reduced single-customer FND-03 scope; Project isolation and full member management not implemented |
| A11 | Coding Tool | future candidate names E8 | execution rows constrained to fixture read | classpath README read only | absent | graph allows read_file only E9 | fixture read/approval/resume | `FOUNDATION_ONLY`; no repository operation |

## 4. Required TO-BE matrix

| ID | Product requirement | Contract | DB | Backend | Frontend | Orchestrator | E2E | Overall |
|---|---|---|---|---|---|---|---|---|
| T1 | Real public-data Connector and domain replacement | `FOUNDATION_ONLY`: configurable request/response/mapping shape | `FOUNDATION_ONLY`: config JSON and secret reference shape | `NOT_IMPLEMENTED`: non-fixture host rejected | `NOT_IMPLEMENTED`: fixture values fixed | `N/A` | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; technical foundation only |
| T2 | Fixed `SUPER_ADMIN`/`GENERAL_ADMIN`/`GENERAL_USER` target E13–E15 | `PARTIAL`: administrator login/logout/me exists; General User contract absent | `PARTIAL`: administrator account/role/session and membership seam only | `PARTIAL`: administrator server-derived session and role checks; no General User or Project narrowing | `PARTIAL`: administrator login/logout/expiry and role-aware navigation only | `FOUNDATION_ONLY`: Coding role string is not yet migrated to product authority | `IMPLEMENTED` only for delivered two-administrator reduced scope | `PARTIAL`; CMS-01 adds General User administration, CMS-07 adds login/Renderer access |
| T3 | Five manual CMS domains | `NOT_IMPLEMENTED`: no menu/member/content/board/design operations | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |
| T4 | MenuSpec/PageSpec/SiteTemplateSpec, versions, Preview, direct `GENERAL_ADMIN` Publish, Site Release, Rollback | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A` for manual workflow | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`; no `SUPER_ADMIN` approval Gate in the initial MVP |
| T5 | `GENERAL_USER` login/session and end-user site Renderer | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`: admin acceptance console only | `N/A` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`; fixed CMS-07 target |
| T6 | Natural-language CMS candidate capability | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A`: current graph is Coding only | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; scope/order/owner unassigned |
| T7 | RAG Dataset/Metric/Compare/Threshold/Tuning candidate capability | `FOUNDATION_ONLY`: Knowledge score field | `FOUNDATION_ONLY`: single score, no dataset/case/run/metric/threshold | `FOUNDATION_ONLY`: Evaluate phase uses constant 100 E4 | `NOT_IMPLEMENTED` dashboard/artifacts | `N/A` by default | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; technical foundation only |
| T8 | Provider/Model Mapping candidate capability | `FOUNDATION_ONLY`: selected model in Model Turn | `NOT_IMPLEMENTED`: scoped mapping/version table absent | `FOUNDATION_ONLY`: code registry, first CHAT candidate E10 | `NOT_IMPLEMENTED`: key registration only | `FOUNDATION_ONLY`: consumes selection, never owns it | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; technical foundation only |
| T9 | Repository/Coding Tool candidate capability | `FOUNDATION_ONLY`: four candidate tool names, incomplete set | `FOUNDATION_ONLY`: execution store exists but fixture-constrained | `NOT_IMPLEMENTED`: classpath fixture only | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`: no real repo/filesystem mutation | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; Harness foundation only |
| T10 | Repository PathPolicy candidate capability | `FOUNDATION_ONLY`: policy hash/requested path context | `NOT_IMPLEMENTED`: no repository/policy/rule/version aggregate | `FOUNDATION_ONLY`: exact README check only | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY`: snapshot/hash parity | fixture traversal denial only | `DISCUSSION_REQUIRED` after CMS; foundation only |
| T11 | LLM DevOps candidate with fixed three two-account Gates: autonomous-coding result, PR creation, deployment | `FOUNDATION_ONLY`: Coding state/hash/tool fragments | `FOUNDATION_ONLY`: lifecycle/tool execution; no three-Gate approval/evidence/PR/deploy aggregate | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY`: one generic approval interrupt does not implement the three exact Gates | `NOT_IMPLEMENTED` | `DISCUSSION_REQUIRED` after CMS; Gate invariant fixed by E15, internal request→limited patch→one test→result remains uninterrupted |
| T12 | MVP Approval History and core Audit Log | `NOT_IMPLEMENTED`: query/event contract absent | `NOT_IMPLEMENTED`: core approval/audit aggregate absent | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`: screens absent | `N/A` for current CMS | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`; required by E15 through consuming CMS Slices without a separate Reviewer Gate |

## 5. Original Project Spec trace

| Project Spec requirement group | Current implementation evidence | Gap disposition |
|---|---|---|
| §4.1 P0 1–3: auth/project/provider | production two-role login/role enforcement and protected Provider credentials exist E14 | Add CMS-01 member management; do not claim Project isolation in the current single-customer demo. |
| §4.1 P0 4–11: Connector/RAG/citations | deterministic Stage 3 slice | Post-CMS discussion must newly confirm real-data/RAG scope, order, owner, metrics, and E2E boundary. |
| §4.1 P0 12–16, 25–26: natural-language menu/page/template, preview/publish/rollback | no contract/source | Complete the fixed CMS milestone; then newly decide natural-language CMS scope, order, and owner. |
| §4.1 P0 17: Tool/Audit history | Product/Coding technical histories | Add MVP Approval History/core Audit screens for state-changing actions; later Coding Gates add their evidence only after post-CMS discussion. |
| §4.1 P0 18–19: staging and two-domain demo | local Docker only; fixture mixes sample topics | Cloud work remains separately approval-gated; two true end-to-end configured domains remain missing. |
| §4.1 P0 20–23: Build UI, retrieval harness, evaluation dashboard, artifacts | build phases/job console and active RAG exist | Implement metric history, comparison, threshold, failure artifacts, and downloads. |
| §4.1 P0 24: five manual CMS areas | absent | Implement all five as small vertical slices. |
| §§5, 12–13: roles, isolation, security/governance | production fixed roles and technical-vs-business Provider boundary; no Project narrowing E14 | Preserve role enforcement; add Project isolation only through a separately approved multi-customer Slice; real Connector SSRF/DNS and prompt-injection tests remain. |
| §14: CI/CD and rollback | Dockerfiles/local Compose | GitHub Actions, immutable staging, manual environment gate, and image rollback are missing. |
| §17: performance/observability | health/trace/job state foundation | Measure product paths after implementation; token/cost/model/evaluation observability remains incomplete. |
| §18: full Definition of Done | fixture technical E2E only | Full Project Spec E2E is not met. |
| §25/§31.6: controlled coding extension | Coding Harness foundation | Post-CMS discussion must newly decide Repository/PathPolicy/Tool/DevOps scope and sequence; the Harness does not assign it. |
| §31.4: task Model Mapping | Provider capability foundation | Post-CMS discussion must newly decide mapping use cases, persistence, scope, order, and owner. |
| §§32–33: design/template and CMS UX | visual reference only, not product screen | Implement registry/spec/renderer/preview/release using the prescribed admin shell language. |
| §34: one-file/one-command onboarding | Backend macOS/pwsh and Windows 5.1 fixes plus published Master wrapper exist | Preserve per-PC preflight/health and OS-neutral Master paths; a new/reinstalled host still requires its own acceptance. |

## 6. Overstatement guards

1. Do not call T1 complete because Connector JSON is configurable; the runtime adapter is a deterministic fixture.
2. Do not call T7 complete because `EVALUATE` and `score` exist; current evaluation is constant 100.
3. Do not call T9–T11 complete because tool schemas mention mutation; runtime executes only fixture `read_file`.
4. Do not call T3–T6 complete because the UI demonstrates workflow calls; it is not the manual CMS, Renderer, Site Release, or natural-language CMS.
5. Do not overstate T2: production login and role enforcement are complete for the reduced demo, but Project isolation and a complete member-management product are not.
6. Do not omit `GENERAL_USER`, Approval History, or core Audit from the CMS target; E15 requires them.
   Do not infer a separate Reviewer or `SUPER_ADMIN` pre-publication Gate from that inclusion.
7. Do not treat T1 or T6–T11 as an assigned sequence. Their order, owner, scope, and Slice structure are
   decided only after integrated CMS acceptance.
