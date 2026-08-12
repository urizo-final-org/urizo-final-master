# AX Module Studio AS-IS/TO-BE feature traceability matrix v0.1

> Baseline date: 2026-08-12
> Product authority: `AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`
> Implementation checkpoint: v0.6 source plus v0.7 read-only rebaseline

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
| E7 | Local auth: Backend `ProductAuthFilter.java`, `ProductLocalAccess.java`, `ProductSessionController.java`; random 24-hour local-full Bearer without production identity/RBAC. |
| E8 | Coding contract/runtime gap: `contracts/coding-agent/tool-request.schema.json` names `read_file/search_code/apply_patch/run_check`; `CodingToolService.java` and Flyway enforce fixture `README.md` `read_file`. |
| E9 | Orchestrator: `graph.py`, `queue.py`, `checkpoint.py`; fixed Model Turn→read fixture→approval→complete flow. |
| E10 | Model foundation: Backend `ProviderCapabilityConfiguration.java`, `CodingModelTurnService.java`; code-configured registry and first eligible CHAT candidate, not DB task mapping. |
| E11 | Integrated runtime/E2E: Backend `compose.dev.yaml`, `scripts/verify-full-local-e2e.ps1`, `scripts/health.ps1`. |
| E12 | Recorded verification: handoff package `AX_Module_Studio_IMPLEMENTATION_SESSION_HANDOFF_v0.6.md`. |

No implemented identifiers were found for `project_member`, `menu_version`, `page_version`, `site_template`, `site_release`, general `approval`, general `audit_log`, `golden_question`, `model_mapping`, or `path_policy_version`. Coding-specific approval fragments and Provider connection audit are not a unified product Approval/Audit aggregate.

## 3. Confirmed AS-IS

| ID | Capability | Contract | DB | Backend | Frontend | Orchestrator | E2E | Overall |
|---|---|---|---|---|---|---|---|---|
| A1 | Local-full infrastructure | Health/readiness in E2 | Core Flyway + separate checkpoint DB | Backend-owned Compose, limits, health E11 | Nginx same-origin app | Valkey worker/checkpoint health | `RECORDED_PASS`: health, restart, failure gates E12 | `IMPLEMENTED` local foundation |
| A2 | Project technical slice | create/list/get E2 | `app.project` E3 | Controller/Service/Store | create/select/restore console E5 | N/A | `RECORDED_PASS` | `IMPLEMENTED`, without member/RBAC ownership |
| A3 | Connector version/preview/activate/sync | ConnectorSpec-shaped API E2 | connector/version/config JSON E3 | `fixture.invalid` only E4 | fixed fixture form E5 | N/A | three fixture documents pass | `FOUNDATION_ONLY` for real Connector |
| A4 | Knowledge build/version/activate/rollback | Knowledge operations E2 | base/version/document/chunk/vector E3 | six-phase Batch, active pointer | build/version/activate/rollback console | N/A | `RECORDED_PASS` | `IMPLEMENTED` deterministic technical slice |
| A5 | RAG citation/refusal | chatbot/query/citation/refusal E2 | active-version documents/chunks | server active pointer; deterministic grounding/refusal E4 | query/citations/refusal view | N/A | `RECORDED_PASS` | `IMPLEMENTED` fixture RAG, not evaluated product quality |
| A6 | Authoritative Product Job | list/get/cancel/retry E2 | product job, outbox, Batch metadata E3 | state/recovery/retry | Product Job panel | N/A | `RECORDED_PASS` | `IMPLEMENTED` Product lane |
| A7 | Coding Harness | lifecycle/model/tool contracts | job/command/lease/tool execution | claim, lease, heartbeat, Model/Tool gateway | no Coding UI | reliable queue, encrypted checkpoint, interrupt/resume E9 | `RECORDED_PASS` | `IMPLEMENTED` harness foundation only |
| A8 | Provider Credential local CMS | internal-dev boundary, not public product API | encrypted secret and connection audit | local-only store/test E6 | OpenAI/Google/Anthropic form | N/A | three VERIFIED states recorded | `IMPLEMENTED(local)`; no Project scope/Model Mapping |
| A9 | Frontend product status | N/A | N/A | consumes actual Spring API | `Local Full Workflow`, `LLM Providers` only E5 | not exposed | Browser acceptance recorded | acceptance console, not product CMS |
| A10 | Authentication/authorization | Bearer/error shapes | no user/member/role/session | local random token E7 | fixed local administrator label | Coding role snapshot string only | local 401 boundary only | `FOUNDATION_ONLY`; production Auth/RBAC absent |
| A11 | Coding Tool | future candidate names E8 | execution rows constrained to fixture read | classpath README read only | absent | graph allows read_file only E9 | fixture read/approval/resume | `FOUNDATION_ONLY`; no repository operation |

## 4. Required TO-BE matrix

| ID | Product requirement | Contract | DB | Backend | Frontend | Orchestrator | E2E | Overall |
|---|---|---|---|---|---|---|---|---|
| T1 | Real public-data Connector and domain replacement | `FOUNDATION_ONLY`: configurable request/response/mapping shape | `FOUNDATION_ONLY`: config JSON and secret reference shape | `NOT_IMPLEMENTED`: non-fixture host rejected | `NOT_IMPLEMENTED`: fixture values fixed | `N/A` | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY` |
| T2 | Production login/users/roles/Project RBAC | `FOUNDATION_ONLY`: Bearer/error form only | `NOT_IMPLEMENTED`: identity/membership/RBAC tables absent | `NOT_IMPLEMENTED`: no production authn/authz or server actor context | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY`: Coding role string is not product RBAC | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |
| T3 | Five manual CMS domains | `NOT_IMPLEMENTED`: no menu/member/content/board/design operations | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |
| T4 | MenuSpec/PageSpec/SiteTemplateSpec, versions, Preview, Approval, Publish, Site Release, Rollback | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A` for manual workflow | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`; Knowledge Version is not a substitute |
| T5 | End-user site Renderer | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`: admin acceptance console only | `N/A` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |
| T6 | Natural language→ActionPlan→Draft→validation→Diff/Preview→approval→publish/rollback | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `N/A`: Product AI belongs in Spring; current graph is Coding only | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` |
| T7 | RAG Dataset/Metric/Compare/Threshold/Tuning | `FOUNDATION_ONLY`: Knowledge score field | `FOUNDATION_ONLY`: single score, no dataset/case/run/metric/threshold | `FOUNDATION_ONLY`: Evaluate phase uses constant 100 E4 | `NOT_IMPLEMENTED` dashboard/artifacts | `N/A` by default | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY` |
| T8 | Task-level Provider/Model Mapping in fixed workflows | `FOUNDATION_ONLY`: selected model in Model Turn | `NOT_IMPLEMENTED`: scoped mapping/version table absent | `FOUNDATION_ONLY`: code registry, first CHAT candidate E10 | `NOT_IMPLEMENTED`: key registration only | `FOUNDATION_ONLY`: consumes selection, never owns it | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY` |
| T9 | Repository tree/read/write/apply_patch/diff/test/build/preview | `FOUNDATION_ONLY`: four candidate tool names, incomplete set | `FOUNDATION_ONLY`: execution store exists but fixture-constrained | `NOT_IMPLEMENTED`: classpath fixture only | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED`: no real repo/filesystem mutation | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY` |
| T10 | Repository Tree checkbox PathPolicy Version and fixed denylist | `FOUNDATION_ONLY`: policy hash/requested path context | `NOT_IMPLEMENTED`: no repository/policy/rule/version aggregate | `FOUNDATION_ONLY`: exact README check only | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY`: snapshot/hash parity | fixture traversal denial only | `FOUNDATION_ONLY` |
| T11 | LLM DevOps Scope/Patch/Test/Preview/PR/CI/Deploy manual gates | `FOUNDATION_ONLY`: Coding state/hash/tool fragments | `FOUNDATION_ONLY`: lifecycle/tool execution; no pipeline stage/evidence/PR/deploy aggregate | `NOT_IMPLEMENTED` | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY`: one approval interrupt then complete | `NOT_IMPLEMENTED` | `FOUNDATION_ONLY` |
| T12 | Unified Approval/Audit/Job history | `FOUNDATION_ONLY`: Product/Coding fragments are separate | `FOUNDATION_ONLY`: product job, coding job, tool execution, provider audit are fragmented | `FOUNDATION_ONLY` | `FOUNDATION_ONLY`: Product Job panel only | `FOUNDATION_ONLY`: Coding interrupt only | separate technical flows only | `FOUNDATION_ONLY` |

## 5. Original Project Spec trace

| Project Spec requirement group | Current implementation evidence | Gap disposition |
|---|---|---|
| §4.1 P0 1–3: auth/project/provider | Project and local Provider CMS exist | Production auth/RBAC and Project-scoped Provider/Mapping remain required. |
| §4.1 P0 4–11: Connector/RAG/citations | deterministic Stage 3 slice | Replace fixture with real public-data adapter; implement quality Dataset/Metrics and two-domain E2E. |
| §4.1 P0 12–16, 25–26: natural-language menu/page/template, preview/publish/rollback | no contract/source | Implement manual CMS/version/release/renderer first, then natural-language Draft workflow. |
| §4.1 P0 17: Tool/Audit history | Product/Coding technical histories | Add unified domain-neutral Approval/Audit/Job history and UI. |
| §4.1 P0 18–19: staging and two-domain demo | local Docker only; fixture mixes sample topics | Cloud work remains separately approval-gated; two true end-to-end configured domains remain missing. |
| §4.1 P0 20–23: Build UI, retrieval harness, evaluation dashboard, artifacts | build phases/job console and active RAG exist | Implement metric history, comparison, threshold, failure artifacts, and downloads. |
| §4.1 P0 24: five manual CMS areas | absent | Implement all five as small vertical slices. |
| §§5, 12–13: roles, isolation, security/governance | local access and limited fixture/path guards | Implement identity/RBAC, server Project context, real Connector SSRF/DNS controls, product prompt-injection tests. |
| §14: CI/CD and rollback | Dockerfiles/local Compose | GitHub Actions, immutable staging, manual environment gate, and image rollback are missing. |
| §17: performance/observability | health/trace/job state foundation | Measure product paths after implementation; token/cost/model/evaluation observability remains incomplete. |
| §18: full Definition of Done | fixture technical E2E only | Full Project Spec E2E is not met. |
| §25/§31.6: controlled coding extension | Coding Harness foundation | Build Repository/PathPolicy/real tools before DevOps gates. |
| §31.4: task Model Mapping | Provider capability foundation | Add versioned DB mapping per fixed use case and snapshot it into Jobs. |
| §§32–33: design/template and CMS UX | visual reference only, not product screen | Implement registry/spec/renderer/preview/release using the prescribed admin shell language. |
| §34: one-file/one-command onboarding | Backend scripts work on the preserved machine | Master wrapper exists locally, but remote reproduction is blocked until four repositories publish the baseline. |

## 6. Overstatement guards

1. Do not call T1 complete because Connector JSON is configurable; the runtime adapter is a deterministic fixture.
2. Do not call T7 complete because `EVALUATE` and `score` exist; current evaluation is constant 100.
3. Do not call T9–T11 complete because tool schemas mention mutation; runtime executes only fixture `read_file`.
4. Do not call T3–T6 complete because the UI demonstrates workflow calls; it is not the manual CMS, Renderer, Site Release, or natural-language CMS.
5. Do not call T2 complete because Bearer authentication exists; it has no production user/role/membership authority.
