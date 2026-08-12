# AX Module Studio Workspace Agent Rules

## Workspace boundary

- This parent folder is not a Git repository. Never create `.git` here.
- `urizo-final-master/**` belongs to the Master control/handoff repository.
- `urizo-final-frontend/**` belongs to the Frontend repository.
- `urizo-final-backend/**` belongs to the Spring Backend repository.
- `urizo-final-orchestrator/**` belongs to the Python LangGraph Coding Runtime repository.
- Read all needed repositories, but commit/push/PR separately per `.git` with one shared Slice ID and cross-links.

## Authority and ownership

- Begin with `urizo-final-master/docs/handoff/AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v0.7.md` and the applicable repository `AGENTS.md`.
- Product requirements come from the approved Project Spec and are not reduced to the current OpenAPI.
- Backend owns public/coding contracts, Flyway, Spring API/Batch, Tool Gateway, integrated Compose, and Dev bootstrap.
- Orchestrator owns only the Python Coding graph/checkpoint runtime.
- Master owns manifest, handoff, traceability, ownership, and safe workspace wrappers; it never owns product source.

## LLM onboarding behavior

- On a natural-language setup/update request, do not make the teammate manually enter routine Git, PowerShell, Docker, Maven, Node, or Python commands.
- Read Master `AGENTS.md` and its required handoff/team documents, then run the Master read-only preflight and explain the detected state.
- Propose the exact network, local-runtime, authentication, installation, administrator, or reboot boundary and obtain explicit approval where required.
- After approval, run the Master bootstrap wrapper with only the approved switches; stop for human Git/Docker login, MFA, administrator elevation, installation, reboot, or secret entry and resume verification afterward.
- Use the generated `AX-Module-Studio.code-workspace` as the four-repository development view. Before work, report the assigned Slice ID, owner, dependencies, shared seams, and repository-specific PR order from the Master team roadmap.

## Safety and Git

- Preserve all branch/HEAD/uncommitted state, databases, volumes, secrets, and running containers.
- No automatic reset, clean, stash, checkout, database initialization, or volume deletion.
- No secret values or full secret digests in prompts, chat, commands, logs, commits, or PRs.
- Network/login/admin/reboot/credential/Prod/Cloud/SSH actions require explicit approval.
- Normal work uses latest `dev` → `feature/<confirmed-github-id>_<work-slug>_<version>` → reviewed PR to `dev`; no direct push, force push, auto-merge, or implicit merge.
- Shared contracts, Flyway, app shell, common Error/Auth/Approval/Audit, Backend Compose/bootstrap, and Master manifest/handoff are serialized through the Integration/Contract owner.
