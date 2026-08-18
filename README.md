# AX Module Studio Master

`urizo-final-master` is the workspace control and handoff repository for three independent canonical source repositories. It intentionally contains no product source and is not a monorepo.

```text
AX-Module-Studio-Workspace/          # no .git
├── urizo-final-master/             # governance, handoff, safe wrappers
├── urizo-final-frontend/           # React
├── urizo-final-backend/            # Spring, Flyway, contracts, integrated Compose
└── urizo-final-orchestrator/        # Python LangGraph Coding Runtime
```

## Current checkpoint

The latest checkpoint is [implementation/team handoff v1.0](docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v1.0.md). All four canonical repositories expose protected `main` and `dev` branches, and FND-03 production two-role login/role enforcement is merged in its reduced single-customer demonstration boundary. The [completion decision](docs/product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md) records that Project isolation is not implemented, full member management moves to CMS-01, and there is no scheduled FND-04 Wave. The five manual CMS domains, Site Release/Renderer, natural-language CMS, real repository tools, PathPolicy UI/versioning, and LLM DevOps remain incomplete. Autonomous coding still requires distinct customer and technical approvals later.

## Entry points

- [팀원 원클릭 전체관리자 CMS 시작 가이드](docs/onboarding/TEAMMATE_ONE_CLICK_CMS_START_GUIDE_v0.1.md)
- [Auth/RBAC MVP specification](docs/product/AX_Module_Studio_AUTH_RBAC_MVP_SPEC_v0.1.md)
- [FND-03 completion/FND-04 retirement decision](docs/product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md)
- [Multi-model LLM routing](docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md)
- [Team multi-OS local development](docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md)
- [Current infrastructure baseline](docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md)
- [Document index](docs/README.md)
- [Feature traceability matrix](docs/traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md)
- [Team ownership and roadmap](docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md)
- [Master/bootstrap specification](docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md)
- [Teammate LLM local setup prompt](docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md)
- [Teammate LLM work-start prompt](docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md)
- [Repository manifest](repository-manifest.json)

## LLM-first teammate onboarding

After the initial Master clone, open this repository in the coding agent and ask:

```text
AX Module Studio 팀 개발환경을 구성해줘.
```

Codex-compatible agents enter through `AGENTS.md`; Claude Code enters through `CLAUDE.md`, which imports the same authority. The shared rules instruct the LLM to read the current handoff and team assignment, detect Windows/macOS/Linux, run read-only preflight, explain approval boundaries, execute the version-managed bootstrap itself after approval, stop for required login/MFA/administrator/reboot/secret entry, and finish with workspace health verification. A teammate should not need to translate or copy routine setup commands manually. The initial Git clone/open and unavoidable interactive boundaries remain human actions.

Read-only checks:

```powershell
.\scripts\preflight-workspace.ps1
.\scripts\health-workspace.ps1
.\scripts\validate-master-scaffold.ps1
```

On macOS/Linux the local LLM invokes the same scripts with PowerShell 7 (`pwsh`). On Windows it may use
Windows PowerShell 5.1 or PowerShell 7 according to the multi-OS specification.

Agent-executed one-command onboarding:

```powershell
.\scripts\bootstrap-workspace.ps1 -ApproveNetwork -RunLocalFull -ApproveLocalFullMutation
```

That command never pulls, checks out, resets, stashes, cleans, overwrites a non-empty non-repository directory, or deletes a database/volume. It stops at authentication, Docker/WSL installation, administrator, reboot, dirty-worktree, and credential boundaries.
