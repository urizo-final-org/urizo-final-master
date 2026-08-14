# AX Module Studio Workspace Agent Rules

## Workspace boundary

- This parent folder is not a Git repository. Never create `.git` here.
- `urizo-final-master/**` belongs to the Master control/handoff repository.
- `urizo-final-frontend/**` belongs to the Frontend repository.
- `urizo-final-backend/**` belongs to the Spring Backend repository.
- `urizo-final-orchestrator/**` belongs to the Python LangGraph Coding Runtime repository.
- Read all needed repositories, but commit/push/PR separately per `.git` with one shared Slice ID and cross-links.

## Authority and ownership

- Begin with `urizo-final-master/docs/onboarding/TEAMMATE_ONE_CLICK_CMS_START_GUIDE_v0.1.md`, the latest implementation/team handoff, and the applicable repository `AGENTS.md`.
- The first team product milestone is the complete manual administrator CMS: production Auth/RBAC, members, menus, content/pages, boards, site design/template, Approval/Site Release/Publish/Rollback, Audit, and the end-user Renderer.
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
- Report `SETUP PASS` only after the v0.8 acceptance contract passes. Do not implement from a broad workstream request without one assigned Slice ID.

<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:BEGIN -->
## Automatic local LLM and Notion policy

- At the start of every local implementation task, automatically read `urizo-final-master/AGENTS.md`, its required documents, and the applicable sibling repository `AGENTS.md` before planning or editing. Do not require the team lead to paste these rules into each prompt.
- If the task fetches, pulls, or otherwise synchronizes Git, automatically re-read the updated Master `AGENTS.md` and task-relevant Master documents after synchronization and before planning or implementation. No separate teammate instruction is required.
- Git is the implementation source of truth. Notion pages, Gantt charts, WBS databases, and timelines are secondary planning and reporting views.
- Do not create, edit, delete, or otherwise synchronize any Notion content unless Min Seungjun (`tmdwns0531`) explicitly requests that Notion write in the current task. Git work, PR, merge, and status requests do not imply Notion-write authorization.
- For an explicitly requested Notion synchronization, first fetch and verify the relevant canonical repositories, `origin/dev` commits, merged PRs, specifications, and validation evidence. Project that state into Notion; if the two conflict, Git is authoritative and the mismatch must be reported.
- Notion MCP is optional for teammates. Start from current Git and the assigned task packet: Slice ID, target repositories, scope, dependencies, and an optional Notion URL or snapshot.
- Read only task-relevant Notion content when access and a reference are supplied. Never scrape the full workspace after every pull, and never block work solely because Notion MCP is unavailable.
<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:END -->

## Safety and Git

- Preserve all branch/HEAD/uncommitted state, databases, volumes, secrets, and running containers.
- No automatic reset, clean, stash, checkout, database initialization, or volume deletion.
- No secret values or full secret digests in prompts, chat, commands, logs, commits, or PRs.
- Network/login/admin/reboot/credential/Prod/Cloud/SSH actions require explicit approval.
- Team-member work uses latest `dev` → `feature/<confirmed-github-id>_<work-slug>_<version>` → PR to `dev`, approved by the `tmdwns0531` Master/Admin integration account.
- Team members never push directly to `dev`/`main`. The `tmdwns0531` Master/Admin account may use the intentional Repository Admin Ruleset bypass to update `dev`/`main`, merge its own validated governance changes, and approve team PRs; no additional teammate approval is required for those owner changes.
- Never force-push. Record validation evidence and the resulting SHA for every owner bypass operation.
- Shared contracts, Flyway, app shell, common Error/Auth/Approval/Audit, Backend Compose/bootstrap, and Master manifest/handoff are serialized through the Integration/Contract owner.
