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
2. `docs/product/AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md`
3. `docs/product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md`
4. `docs/product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md`
5. `docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v1.0.md`
6. `docs/traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md`
7. `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`
8. `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`
9. `docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md`
10. `docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md`
11. `docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md`
12. `docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md`
13. `docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md`
14. `docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md` or `TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md`, as applicable
15. The applicable sibling repository `AGENTS.md`
16. For cross-system product intent, the preserved baseline
    `docs/product/AX_Module_Studio_Vibe_Coding_Project_Spec_v1.0.md`

The Project Spec is not reduced to the currently implemented OpenAPI. The team checklist decision
overlay is the latest authority for the three-role target, Approval History/core Audit Log inclusion,
the CMS-first execution order, the post-CMS team-planning Gate, and the exact three later LLM DevOps
dual-approval Gates. A healthy container or a technical E2E does not prove completion of an
unimplemented product feature.

The later FND-03 completion decision is authoritative for the reduced single-customer demonstration:
production two-role login/role enforcement is complete, Project isolation and full member management are
not part of FND-03, and the scheduled FND-04 Foundation Wave is retired. The later target additionally
requires `GENERAL_USER`, Approval History, and a core Audit Log in the CMS milestone. Later Coding/LLM
DevOps uses exactly three dual-approval Gates: autonomous-coding result, PR creation, and deployment.
The internal request→limited patch→one allowlisted test→result flow runs without a human approval pause.

## LLM onboarding protocol

- Treat natural-language requests such as `AX Module Studio 팀 개발환경을 구성해줘`, `로컬 환경을 세팅해줘`, or `환경 최신화해줘` as an onboarding/setup request.
- Treat `깃 pull 해줘`, `전체 Git 최신화`, or `워크스페이스 최신화` as a request to run the Master-first safe four-repository synchronization in `scripts/sync-workspace.ps1 -ApproveNetwork`. Its default scope is Master plus all three Source repositories; never silently narrow it to the current repository. Re-read the updated Master rules and status snapshot before continuing. Never translate this request into an unconditional `pull origin dev` on every current branch.
- The teammate only needs to clone/open this Master repository and make that request. Do not require the teammate to copy and run PowerShell, Git, Docker, Maven, Node, or Python commands manually when the agent can run the version-managed scripts.
- First read the required documents above and run the read-only `scripts/preflight-workspace.ps1`. Explain the detected repository, Git, Docker/WSL, database, and health state before proposing changes.
- Detect and report the host OS and PowerShell runtime. Use Windows PowerShell 5.1 or PowerShell 7 on Windows and `pwsh` on macOS/Linux; never translate cross-platform Repository paths with hard-coded Windows separators.
- Explain the exact next action and whether it needs network access, local runtime mutation, authentication/MFA/browser interaction, administrator elevation, installation, or reboot. Obtain the applicable explicit approval before crossing that boundary.
- After approval, run `scripts/bootstrap-workspace.ps1` with only the approved switches. It assembles missing sibling repositories, creates absent parent workspace files, and delegates local-full setup to the Backend-owned script.
- If Git/Docker login, MFA, administrator elevation, installation, or reboot requires human interaction, stop at that boundary, explain the shortest human action, and resume verification after the teammate completes it. Never bypass or solicit secrets in chat or command arguments.
- After bootstrap, open or recommend the generated `AX-Module-Studio.code-workspace`, run `scripts/health-workspace.ps1`, and report service URLs, warnings, and any remaining blocker.
- Before assigning or implementing work, read `docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md` and state the Slice ID, E2E lead, reserved shared seams, repository paths, dependencies, and PR order.
- The approved order ends at Wave 3 CMS-01–04 in parallel, then CMS-05→06→07 and integrated CMS acceptance. Post-CMS backlog order, owner, scope, Slice IDs, and PR order remain unassigned until a new team-lead Git decision is checked in.
- Report `SETUP PASS` only when the v0.8 setup acceptance contract is satisfied. Do not begin implementation from a generic workstream description; require one assigned Slice ID.

## Ownership boundaries

- Backend owns public/coding contracts, Flyway, Spring API and Batch, Tool Gateway, integrated Compose, and Dev bootstrap.
- Frontend owns the React admin and end-user UI and consumes the public contract.
- Orchestrator owns only the Python LangGraph Coding Runtime and consumes Backend coding contracts.
- Master owns the repository manifest, workspace bootstrap wrapper, latest handoff, traceability, team ownership, migration reservation ledger, model/OS routing and descriptive infrastructure baseline, and collaboration rules.
- Master is the only normative source for cross-repository policy, roles, Wave/WBS state, assignments, Git/PR workflow, and shared safety rules. Source-repository `AGENTS.md` and `CLAUDE.md` files are routing entry points and may retain only repository-specific scope, ownership boundaries, and links to repository-local operational documentation. They must not copy changing Master policy.
- Historical Source documents may preserve implementation evidence, but they must be marked non-normative when their status, roles, repository URLs, branch policy, or execution gates have been superseded by Master.
- Product source, Compose, migrations, runtime credentials, business data, and Docker volumes never move into Master.
- Only Min Seungjun (`tmdwns0531`) may create Master branches, commits, pushes, pull requests, or merges. Teammates use Master as a read/pull-only control repository and submit Slice work only to changed Frontend, Backend, or Orchestrator repositories.

## Notion synchronization policy

- At the start of every local implementation task, read this Master `AGENTS.md`, its required documents, and the applicable sibling repository `AGENTS.md` before planning or editing. The team lead must not have to paste this policy into each LLM prompt.
- If the task fetches, pulls, or otherwise synchronizes Git, re-read the updated Master `AGENTS.md`, `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`, and the task-relevant Master documents after synchronization and before planning or implementation. Do this without requiring a separate teammate instruction.
- Treat the team lead's `MASTER UPDATE COMPLETE` packet as the signal to synchronize, not as a substitute for Git evidence. After synchronization, match its Snapshot version, Slice ID, Task version, worker, target repositories, and Master commit to `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`.
- Before implementation, return `MASTER CONTEXT PASS` with the recognized Wave, Slice and any issued Task version, worker, target repositories, next work, next gate, and fetched Source `origin/dev` refs. An explicit owner request naming a Master-listed Slice is sufficient to start its first task; a separately named Task Packet is not required merely to recognize or name the active Wave. Return `MASTER CONTEXT BLOCKED` only when the explicit request conflicts with checked-in Master context or a required technical dependency is still closed.
- Git is the implementation source of truth. Notion pages, Gantt charts, WBS databases, and timelines are secondary planning and reporting views.
- Do not create, edit, delete, or otherwise synchronize any Notion content unless Min Seungjun (`tmdwns0531`) explicitly requests that Notion write in the current task. A request to implement code, update Git documentation, open a PR, merge, or report status does not imply Notion-write authorization.
- When an explicit Notion synchronization is requested, first fetch and inspect the relevant canonical repositories, verify the applicable `origin/dev` commits, merged PRs, specifications, and validation evidence, and then project that verified state into Notion. If Git and Notion conflict, treat Git as authoritative and report the mismatch.
- Teammates do not connect or use Notion MCP. A teammate LLM starts from current Git plus an explicit owner work request naming at least the Slice ID and intended scope. A versioned Task Packet may refine target repositories, dependencies, and gates, but it does not define or renumber the active Wave.
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

- For a new assigned task, begin from a clean local `dev` that is fast-forwarded to `origin/dev`, then create `feature/<confirmed-github-id>_<work-slug>_<version>`. A separate worktree is preferred when the canonical checkout must remain on `dev`. If a checkout is dirty, diverged, or contains local-only commits, preserve it and report the blocker instead of switching automatically.
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
