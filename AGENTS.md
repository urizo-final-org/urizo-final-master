# AX Module Studio Master Repository Rules

## Repository role

- This repository is the workspace control, governance, documentation, and handoff repository.
- It is not a monorepo and must not contain copies of Frontend, Backend, or Orchestrator source.
- Its canonical remote is `https://github.com/urizo-final-org/urizo-final-master.git`.
- The parent `AX-Module-Studio-Workspace` is not a Git repository. Never create `.git` there.

## Sibling routing

- `../urizo-final-frontend/**` belongs to the Frontend repository.
- `../urizo-final-backend/**` belongs to the Spring Backend repository.
- `../urizo-final-orchestrator/**` belongs to the Python LangGraph Coding Runtime repository.
- `./**` belongs to this Master repository.
- Read across repositories when a slice requires it, but make commits, pushes, and pull requests separately in every changed repository.

## Required reading

1. `docs/onboarding/TEAMMATE_ONE_CLICK_CMS_START_GUIDE_v0.1.md`
2. `docs/product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md`
3. `docs/product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md`
4. `docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v1.0.md`
5. `docs/traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md`
6. `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`
7. `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`
8. `docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md`
9. `docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md`
10. `docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md`
11. `docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md`
12. `docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md`
13. `docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md` or `TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md`, as applicable
14. The applicable sibling repository `AGENTS.md`
15. For product intent, the preserved authoritative `AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`

The Project Spec is not reduced to the currently implemented OpenAPI. The approved Auth/RBAC MVP
overlay is the later authority for the initial two-role model, manual-CMS approval exclusion, Audit
exclusion, and autonomous-coding dual approval. A healthy container or a technical E2E does not
prove completion of an unimplemented product feature.

The later FND-03 completion decision is authoritative for the reduced single-customer demonstration:
production two-role login/role enforcement is complete, Project isolation and full member management are
not part of FND-03, and the scheduled FND-04 Foundation Wave is retired. Coding/LLM DevOps dual approval
is still required later and is not removed with FND-04.

## LLM onboarding protocol

- Treat natural-language requests such as `AX Module Studio 팀 개발환경을 구성해줘`, `로컬 환경을 세팅해줘`, or `환경 최신화해줘` as an onboarding/setup request.
- Treat `깃 pull 해줘`, `전체 Git 최신화`, or `워크스페이스 최신화` as a request to run the Master-first safe four-repository synchronization in `scripts/sync-workspace.ps1 -ApproveNetwork`. Re-read the updated Master rules and status snapshot before continuing. Never translate this request into an unconditional `pull origin dev` on every current branch.
- The teammate only needs to clone/open this Master repository and make that request. Do not require the teammate to copy and run PowerShell, Git, Docker, Maven, Node, or Python commands manually when the agent can run the version-managed scripts.
- First read the required documents above and run the read-only `scripts/preflight-workspace.ps1`. Explain the detected repository, Git, Docker/WSL, database, and health state before proposing changes.
- Detect and report the host OS and PowerShell runtime. Use Windows PowerShell 5.1 or PowerShell 7 on Windows and `pwsh` on macOS/Linux; never translate cross-platform Repository paths with hard-coded Windows separators.
- Explain the exact next action and whether it needs network access, local runtime mutation, authentication/MFA/browser interaction, administrator elevation, installation, or reboot. Obtain the applicable explicit approval before crossing that boundary.
- After approval, run `scripts/bootstrap-workspace.ps1` with only the approved switches. It assembles missing sibling repositories, creates absent parent workspace files, and delegates local-full setup to the Backend-owned script.
- If Git/Docker login, MFA, administrator elevation, installation, or reboot requires human interaction, stop at that boundary, explain the shortest human action, and resume verification after the teammate completes it. Never bypass or solicit secrets in chat or command arguments.
- After bootstrap, open or recommend the generated `AX-Module-Studio.code-workspace`, run `scripts/health-workspace.ps1`, and report service URLs, warnings, and any remaining blocker.
- Before assigning or implementing work, read `docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md` and state the Slice ID, E2E lead, reserved shared seams, repository paths, dependencies, and PR order.
- Report `SETUP PASS` only when the v0.8 setup acceptance contract is satisfied. Do not begin implementation from a generic workstream description; require one assigned Slice ID.

## Ownership boundaries

- Backend owns public/coding contracts, Flyway, Spring API and Batch, Tool Gateway, integrated Compose, and Dev bootstrap.
- Frontend owns the React admin and end-user UI and consumes the public contract.
- Orchestrator owns only the Python LangGraph Coding Runtime and consumes Backend coding contracts.
- Master owns the repository manifest, workspace bootstrap wrapper, latest handoff, traceability, team ownership, migration reservation ledger, model/OS routing and descriptive infrastructure baseline, and collaboration rules.
- Product source, Compose, migrations, runtime credentials, business data, and Docker volumes never move into Master.
- Only Min Seungjun (`tmdwns0531`) may create Master branches, commits, pushes, pull requests, or merges. Teammates use Master as a read/pull-only control repository and submit Slice work only to changed Frontend, Backend, or Orchestrator repositories.

## Notion synchronization policy

- At the start of every local implementation task, read this Master `AGENTS.md`, its required documents, and the applicable sibling repository `AGENTS.md` before planning or editing. The team lead must not have to paste this policy into each LLM prompt.
- If the task fetches, pulls, or otherwise synchronizes Git, re-read the updated Master `AGENTS.md`, `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`, and the task-relevant Master documents after synchronization and before planning or implementation. Do this without requiring a separate teammate instruction.
- Treat the team lead's `MASTER UPDATE COMPLETE` packet as the signal to synchronize, not as a substitute for Git evidence. After synchronization, match its Snapshot version, Slice ID, Task version, worker, target repositories, and Master commit to `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`.
- Before implementation, return `MASTER CONTEXT PASS` with the recognized Slice/Task version, worker, target repositories, next work, next gate, and fetched Source `origin/dev` refs. Return `MASTER CONTEXT BLOCKED` and stop if the announcement and checked-in Master context do not match.
- Git is the implementation source of truth. Notion pages, Gantt charts, WBS databases, and timelines are secondary planning and reporting views.
- Do not create, edit, delete, or otherwise synchronize any Notion content unless Min Seungjun (`tmdwns0531`) explicitly requests that Notion write in the current task. A request to implement code, update Git documentation, open a PR, merge, or report status does not imply Notion-write authorization.
- When an explicit Notion synchronization is requested, first fetch and inspect the relevant canonical repositories, verify the applicable `origin/dev` commits, merged PRs, specifications, and validation evidence, and then project that verified state into Notion. If Git and Notion conflict, treat Git as authoritative and report the mismatch.
- Teammates do not connect or use Notion MCP. A teammate LLM starts from current Git plus an assigned task packet containing at least the Slice ID, target repositories, scope, dependencies, and any optional team-lead-provided read-only snapshot.
- Only Min Seungjun updates each worker's Slice `Task-Version` in Master and announces the checked-in version, next work, and Master commit. Team members consume that assignment read-only and never advance its version themselves.
- A teammate LLM may consume only a task-relevant read-only snapshot explicitly supplied by the team lead. Do not request Notion MCP, scrape the Notion workspace, or block implementation because Notion is unavailable.

## Safety

- Preserve every sibling branch, HEAD, uncommitted change, Core DB, checkpoint DB, Docker volume, secret, and running container unless the user explicitly authorizes a scoped change.
- Never run automatic reset, clean, stash, checkout, rebase, history rewrite, database initialization, Flyway repair/clean, or Docker volume deletion.
- Do not output secret values or full secret fingerprints/digests.
- Network download, login, administrator elevation, reboot, credential registration, Prod/Cloud/SSH, and destructive actions require explicit approval.
- `scripts/preflight-workspace.ps1` and `scripts/health-workspace.ps1` are read-only.
- `scripts/bootstrap-workspace.ps1` may clone/fetch only with `-ApproveNetwork`, and may invoke Backend local-full bootstrap only with both `-RunLocalFull` and `-ApproveLocalFullMutation` after a clean-worktree check.

## Git and team workflow

- Team-member work starts from current `origin/dev`, uses `feature/<confirmed-github-id>_<work-slug>_<version>`, and reaches `dev` through a PR approved by the `tmdwns0531` Master/Admin integration account.
- Every team-member Branch work slug contains the lowercase Slice ID. Every Commit subject uses `<type>(<SLICE-ID>/<github-id>): <result>`, and every PR title uses `[<SLICE-ID>][<github-id>] <result>`. The PR body records Slice version, worker name/GitHub ID, Repository, dependencies, connected PRs, Contract/Migration impact, verification, Blocker, and next Gate.
- Every agent-created pull request in Master, Frontend, Backend, and Orchestrator targets `dev`. A generic request to create, publish, or merge a PR never authorizes a `main` target.
- `main` is the team lead's periodic manual promotion branch. Local LLMs and coding agents must not push to `main`, create or merge a PR targeting `main`, delete or recreate `main`, or otherwise advance it. Min Seungjun performs `dev` to `main` promotion manually outside routine agent workflows.
- Team members do not push directly to `dev`. The `tmdwns0531` Master/Admin account may use the intentional Ruleset bypass only to restore or integrate `dev`, merge its own validated governance changes into `dev`, and approve team-member PRs targeting `dev`. An additional teammate approval is not required for those owner-authored `dev` changes.
- Never force-push. Every Master/Admin bypass use must retain validation evidence and the resulting commit SHA in the handoff or PR record.
- One vertical slice may span repositories, but it uses the same Slice ID/work slug and separate cross-linked PRs.
- Shared contracts, Flyway revisions, app shell/router/navigation, common Error/Auth/Approval/Audit, Backend Compose/bootstrap, and Master handoff/manifest are serialized through the Integration/Contract owner.
- Database work must reserve a UTC 14-digit Flyway revision before creating SQL and must pass empty-DB, previous-revision, repeated-migrate, single-history, and runtime-DDL-denial gates.
- No commit, push, PR, ruleset, CODEOWNERS activation, or merge is implied by a documentation or scaffold task.
