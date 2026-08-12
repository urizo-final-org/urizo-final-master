# AX Module Studio implementation/team handoff v0.7

> Date: 2026-08-12 (Asia/Seoul)
> Source workspace: `C:\urizo-final-project\AX-Module-Studio-Workspace`
> Status: workspace rebaseline and local Master scaffold complete; no commit, push, PR, merge, source reset, database change, or runtime restart performed

## 0. Status and authority

This is the first combined implementation/team checkpoint after v0.6. It does not overwrite v0.6 and does not infer state from an earlier chat. It is based on complete reading of:

1. the handoff package `AGENTS.md`;
2. the v0.6 required architecture sequence (`architecture-variants/README`, Spring candidate README, requirements precedence, feasibility ADR, license review, target architecture, three-repository collaboration, dual-runtime/spike gate);
3. `AX_Module_Studio_IMPLEMENTATION_HANDOFF_v0.2.md`;
4. `TEAM_DEV_SETUP_v0.2.md`;
5. `GIT-WORKFLOW_v0.2.md`;
6. `AX_Module_Studio_IMPLEMENTATION_SESSION_HANDOFF_v0.6.md`;
7. the complete original `AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`;
8. the architecture handoff, team work/Git guide, Dev/Prod bootstrap spec, SiteTemplate spec, and admin UI reference;
9. the conditional full `DATABASE_MIGRATION_POLICY_v0.2.md` and `AX_Module_Studio_LLM_Function_Tool_Job_Harness_Design_v0.2.md`;
10. the parent workspace and all three source-repository `AGENTS.md` files.

Interpretation order:

- Product intent and P0/P1/P2 requirements remain inherited from the Project Spec.
- The Spring v0.2 overlay changes runtime, migration, and repository responsibility; it does not silently remove product requirements.
- This handoff records what is implemented now. Missing contract or source is a gap, not an implicit scope reduction.
- `healthy`, fixture E2E, and Coding Harness completion are not evidence that the manual CMS, production RBAC, natural-language CMS, or LLM DevOps product is complete.

## 1. Read-only preflight snapshot

Observation window: 2026-08-12 11:53–12:00 KST. Git inspection used `GIT_OPTIONAL_LOCKS=0` and command-local `safe.directory`; no global Git setting was changed.

### 1.1 Git boundaries

- `C:\urizo-final-project`, the handoff package, and `AX-Module-Studio-Workspace` have no parent `.git`.
- Frontend, Backend, and Orchestrator are ordinary independent checkouts, not linked worktrees.
- The initial preflight found no local `urizo-final-master` folder. After explicit network approval, the canonical Master remote was cloned into the empty sibling path. The remote itself was empty, so local `main` has an unborn HEAD.

| Repository | Canonical origin | Branch | HEAD | Working tree at initial source preflight |
|---|---|---|---|---|
| Master | `urizo-final-org/urizo-final-master` | `main` | `UNBORN` | clean immediately after clone; this scaffold is now uncommitted |
| Frontend | `urizo-final-org/urizo-final-frontend` | `feature/tmdwns0531_stage2-provider-cms_v0.1` | `0eaada2ef1142c64951c76884ee3f873c67e4d2b` | dirty: `README.md` modified plus 12 untracked top-level entries (21 untracked files) |
| Backend | `urizo-final-org/urizo-final-backend` | `feature/tmdwns0531_stage0-contract-first_v0.1` | `7ac1e5d46af2123e84c6e0c863d72733d3eee817` | dirty: `README.md` modified plus 14 untracked top-level entries (330 untracked files) |
| Orchestrator | `urizo-final-org/urizo-final-orchestrator` | `feature/tmdwns0531_stage4-model-turn-bridge_v0.1` | `b463c71c4e9417104c6810d228d4d46999b871ba` | dirty: `README.md` modified plus 8 untracked top-level entries (36 untracked files) |

No source branch, HEAD, upstream, or file was changed. No fetch was performed for the three source repositories.

### 1.2 Runtime and database

- Docker Desktop client/server: 29.6.2.
- Eight long-running containers were `running|healthy`: the seven required services plus `database_gateway`.
- `flyway-migration` and `coding_credential_registrar` were `Exited (0)` one-shots.
- Published ports remained limited to Nginx `127.0.0.1:18080` and read-only DB relay `127.0.0.1:15432`.
- `/`, `/nginx-health`, `/api/health`, and `/api/readiness` returned HTTP 200.
- Application readiness was `READY`; Core DB, queue, and migrations were required `UP`. The optional `coding-agent` readiness entry was `NOT_CONFIGURED` even though the coding-runtime container itself was healthy. These facts must remain distinct.
- Core and checkpoint PostgreSQL accepted connections. Core PostgreSQL reported 16.14.
- A read-only Flyway query reported 10 total, 10 successful, 0 failed; latest was `20260811220000`. No checksum or secret digest was printed.

No container was built, started, stopped, restarted, or reconfigured. No database or volume was written, migrated, deleted, or initialized.

## 2. Confirmed AS-IS

### 2.1 Implemented local technical foundation

- Backend-owned local-full Compose supplies Nginx, Frontend, Spring App, Core PostgreSQL/pgvector, Valkey, Python Coding Runtime, and checkpoint PostgreSQL.
- `database_gateway` remains the auxiliary DBeaver relay; Flyway and coding credential registration remain one-shots.
- Project create/list/get, deterministic Connector version/preview/activate/sync, Knowledge build/version/activate/rollback, active-version RAG citation/refusal, and authoritative Product Job lifecycle form a technical vertical slice.
- Core DB transactional outbox→Valkey, Spring-owned Coding Job claim/lease/heartbeat/retry/outcome, Spring Model Turn and Tool Gateway, encrypted LangGraph checkpoint, and interrupt/resume form the Coding Harness foundation.
- Local encrypted Provider Credential CMS exists for OpenAI, Google, and Anthropic.

### 2.2 Important limits

- The Connector runtime accepts the deterministic `fixture.invalid` identity; there is no real public-data outbound adapter.
- Knowledge evaluation currently records a deterministic score of 100; it is not a Dataset/Metric/Threshold evaluation product.
- The Frontend has only `Local Full Workflow` and `LLM Providers` acceptance-console screens.
- Authentication is a local-full boot-random 24-hour Bearer session without production user, role, membership, or Project RBAC.
- Coding contract schemas name future `search_code`, `apply_patch`, and `run_check` candidates, but the implemented Tool is only classpath fixture `README.md` `read_file`.
- The Python graph is a fixed `model_turn → read_file → approval → complete` flow and has no repository filesystem, Git token, Docker socket, or final Tool authority.
- Public contract tags are limited to Health, Projects, Connectors, Knowledge, RAG, and Jobs. There are no manual CMS, Site Release, production identity, RAG evaluation, Model Mapping, PathPolicy, or LLM DevOps public operations.

The detailed evidence and layer-by-layer status are in the [feature traceability matrix](../traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md).

## 3. Confirmed product TO-BE

The following remain required unless a later approved product decision changes them:

1. real public-data Connector and two real domain configurations;
2. production login, users, roles, membership, and server-enforced Project RBAC;
3. five manual CMS domains: menu, members, content/pages, boards, and site design/templates;
4. MenuSpec, PageSpec, SiteTemplateSpec, immutable versions, validation, preview, Approval, Site Release, publish, and rollback;
5. an end-user site Renderer that reads only the active Site Release;
6. natural-language CMS as ActionPlan→typed Draft→validation→Diff/Preview→approval→publish/rollback, built on the manual CMS;
7. RAG Dataset, deterministic and optional judge Metrics, version comparison, Thresholds, tuning evidence, and artifact history;
8. fixed-workflow task-level Provider/Model Mapping, not arbitrary graph rewiring;
9. real repository `tree/read/write/apply_patch/diff/test/build/preview` Tools;
10. Super Admin repository-tree checkbox read/write PathPolicy Versions plus a non-overridable denylist;
11. LLM DevOps with manual gates for scope, Patch, Test, Preview, PR, CI, and deployment;
12. unified Approval/Audit/Job history.

Additional Project Spec gaps remain: GitHub Actions/staging rollback, two complete domain E2Es, build artifact downloads, SSRF/DNS-rebinding validation against a real adapter, prompt-injection product scenarios, and optional LangSmith Dataset/Evaluation integration.

## 4. Master repository decision

`urizo-final-master` is adopted as a fourth independent repository and direct sibling. It is not a source aggregation repository.

It owns:

- common agent/workspace routing rules;
- document index and newest handoff;
- AS-IS/TO-BE traceability;
- repository manifest;
- team RACI, file ownership, collision and PR rules;
- Flyway reservation ledger;
- safe PowerShell preflight/bootstrap/health wrappers;
- VS Code workspace templates.

It does not own product source, public/coding contract source, Flyway SQL, Compose, runtime secrets, or business/checkpoint data. Backend remains the integrated runtime and Dev bootstrap root.

## 5. Team execution baseline

### 5.1 Shared seam serialization

The Integration/Contract owner serializes:

- public/coding OpenAPI and JSON Schema;
- Flyway allocation and review;
- App shell/router/navigation;
- common Error/Auth/Approval/Audit contract;
- Backend integrated Compose/bootstrap;
- Master manifest/handoff.

Before parallel feature work, behavior-preserving preparation slices must extract Backend Project/Connector/Knowledge/RAG/Job packages and Frontend app/route/client/style seams. `ProductStore`, `ProductApiController`, `ProductApiContract`, `LocalFullWorkspace`, `product-api`, `styles.css`, and Orchestrator gateway/graph files must not keep accumulating unrelated features.

### 5.2 Vertical slice rule

Every product slice has one E2E lead who drives Contract→Flyway→Spring→Frontend→E2E. The Orchestrator owner joins only when the coding contract/graph changes. Natural-language CMS and LLM DevOps are split among multiple owners; neither is assigned whole to one person.

The complete phase plan, paths, dependencies, RACI, proposed CODEOWNERS teams, migration reservation method, and Definition of Done are in [TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md](../team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md).

## 6. Publication and reproduction blockers

At this checkpoint, a clean-PC reproduction from the four canonical remotes is not yet possible:

1. Master remote has no commit.
2. The current Frontend, Backend, and Orchestrator implementations are mostly untracked/uncommitted local work.
3. Therefore the remote source baselines do not contain the current Compose, migrations, product slice, or Coding Runtime.

This is not resolved by the local scaffold. It requires an explicit later request to review the source changes, apply `GIT-WORKFLOW_v0.2.md`, verify each repository, create intentional repository-specific commits, push matching feature branches, open cross-linked PRs, and merge through review. No such remote write was authorized or performed here.

Until then:

- use the current local environment only as preserved implementation evidence;
- do not tell a new teammate that the one-command remote bootstrap reproduces v0.6/v0.7;
- do not reset, clean, stash, or reorganize the dirty source trees to make them easier to publish;
- do not advance the Master manifest to “reproducible” status.

## 7. Safe next sequence

1. Review this v0.7 rebaseline with the five-person team and confirm the named workstream assignments.
2. Separately authorize source publication work, if desired; read the full Git workflow before touching implementation files.
3. Characterize and publish the current Stage 0–5 baseline in three repository-specific PRs with the same baseline Slice ID and cross-links.
4. Publish Master governance/handoff last, referencing the reviewed source PRs and exact merged SHAs.
5. Test the documented bootstrap on a second, clean PC without Host Maven/Python/Node.
6. Begin FND-01/FND-02 preparation slices, then production Auth/RBAC and common Approval/Audit foundations.
7. Follow the dependency roadmap: manual CMS → real Connector/RAG/Model Mapping → PathPolicy/Coding → natural-language CMS → LLM DevOps.

## 8. Preservation boundary for the next session

Preserve the four repository branches/HEADs and all uncommitted changes, current Core/checkpoint DBs, Docker volumes, secrets, and running containers. Do not perform reset, clean, stash, checkout, deletion, initialization, re-registration, actual public-data calls, paid-provider calls, Prod/Cloud/AWS/SSH, commit, push, PR, merge, ruleset, or credential changes without the matching explicit authorization.
