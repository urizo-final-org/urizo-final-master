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

The latest local checkpoint is [implementation/team handoff v0.7](docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v0.7.md). The current implementation provides a healthy local-full technical foundation, a deterministic Project→Connector→Knowledge/RAG slice, and a Coding Harness foundation. It is not yet the planned product CMS: production RBAC, the five manual CMS domains, Site Release/Renderer, natural-language CMS, real repository tools, PathPolicy UI/versioning, and LLM DevOps remain incomplete.

Important publication gap: at the 2026-08-12 preflight, this Master remote was empty and all three source implementations existed as uncommitted local changes on feature branches. Until those changes are intentionally reviewed and published through repository-specific PRs, a new teammate cannot reproduce the current local-full implementation from canonical remotes alone.

## Entry points

- [Document index](docs/README.md)
- [Feature traceability matrix](docs/traceability/FEATURE_TRACEABILITY_MATRIX_v0.1.md)
- [Team ownership and roadmap](docs/team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md)
- [Master/bootstrap specification](docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.1.md)
- [Repository manifest](repository-manifest.json)

## LLM-first teammate onboarding

After the initial Master clone, open this repository in the coding agent and ask:

```text
AX Module Studio 팀 개발환경을 구성해줘.
```

The repository `AGENTS.md` instructs the LLM to read the handoff and team assignment, run read-only preflight, explain approval boundaries, execute the version-managed bootstrap itself after approval, stop for required login/MFA/administrator/reboot/secret entry, and finish with workspace health verification. A teammate should not need to copy routine setup commands manually. The initial Git clone/open and any unavoidable interactive authentication or operating-system boundary remain human actions.

Read-only checks:

```powershell
.\scripts\preflight-workspace.ps1
.\scripts\health-workspace.ps1
.\scripts\validate-master-scaffold.ps1
```

Future one-command onboarding, after all four remotes contain the reviewed baseline:

```powershell
.\scripts\bootstrap-workspace.ps1 -ApproveNetwork -RunLocalFull -ApproveLocalFullMutation
```

That command never pulls, checks out, resets, stashes, cleans, overwrites a non-empty non-repository directory, or deletes a database/volume. It stops at authentication, Docker/WSL installation, administrator, reboot, dirty-worktree, and credential boundaries.
