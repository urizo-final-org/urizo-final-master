# AX Module Studio Master repository and bootstrap specification v0.2

## 1. Decision

Use four sibling Git repositories under one non-Git parent:

```text
AX-Module-Studio-Workspace/
├── AGENTS.md
├── CLAUDE.md
├── AX-Module-Studio.code-workspace
├── urizo-final-master/
├── urizo-final-frontend/
├── urizo-final-backend/
└── urizo-final-orchestrator/
```

Master owns workspace governance, handoff, manifest, team collision rules, onboarding prompts, and safe wrappers. It does not own Source, contracts, Flyway SQL, Compose, Secrets, database data, or Docker Volumes. Backend remains the integrated runtime/bootstrap owner.

## 2. Published prerequisite

The v0.1 publication blocker is resolved. All canonical repositories now expose protected `main` and `dev` branches. Missing Source repositories can be cloned from `dev` using the canonical URLs in `repository-manifest.json`.

The first clean teammate machine is still an acceptance run for host-specific Git authentication, Docker Desktop/WSL, ports, and reboot requirements. The scripts must stop and explain those boundaries rather than bypass them.

## 3. LLM-first setup flow

The teammate opens a coding agent and provides the Master URL, their name/GitHub ID, and a desired parent path. After Master is available, the LLM follows `AGENTS.md` and the setup prompt.

```text
read authority and ownership
→ read-only workspace/Git/Docker/DB preflight
→ explain exact approvals and human boundaries
→ obtain network/local-mutation approval
→ run Master bootstrap wrapper
→ clone missing Source dev branches or fetch refs only
→ create absent parent templates without overwrite
→ delegate local-full bootstrap to Backend
→ run Master/Backend health
→ report SETUP PASS or an actionable blocker
```

The agent-executed wrapper is:

```powershell
.\scripts\bootstrap-workspace.ps1 -ApproveNetwork -RunLocalFull -ApproveLocalFullMutation
```

Planning remains available through `-WhatIf`. A teammate should not be asked to copy routine commands manually when the agent can run them.

## 4. Safety behavior

| Condition | Required behavior |
|---|---|
| Missing repository | Clone exact canonical `dev` only after network approval |
| Existing valid repository | Verify origin; fetch refs only when approved |
| Existing non-empty non-repository folder | Block; never overwrite or delete |
| Origin mismatch | Block; never rewrite remote automatically |
| Dirty Source worktree | Preserve it; block local-full bootstrap |
| Existing different parent template | Warn and preserve |
| Git/Docker login or MFA | Stop for human interaction and resume verification |
| Docker/WSL install, administrator, reboot | Explain and obtain explicit approval |
| Secret entry | User enters it in the designated CMS or platform credential flow |
| Prod/Cloud/SSH/firewall/OS accounts | Out of onboarding scope |

The wrapper never performs pull, checkout, reset, clean, stash, rebase, force push, database reset, Flyway clean/repair, or Volume deletion.

## 5. Repository and runtime ownership

- Frontend: React administrator and end-user UI.
- Backend: public/coding contract source, Spring API/Batch, Flyway, Model/Tool authority, integrated Compose and bootstrap.
- Orchestrator: Python fixed Coding graph, checkpoint, interrupt/resume, Backend contract consumers.
- Master: governance and safe coordination only.

Commits, pushes, and PRs remain repository-specific. A cross-repository Slice uses one Slice ID and cross-linked PRs.

## 6. Setup completion

The LLM reports `SETUP PASS` only when:

- all four origins match the manifest;
- Source worktrees are clean and on `dev`;
- the parent is not Git;
- the generated multi-root workspace exists;
- required local-full services and Flyway are healthy;
- service URLs and any optional warning are reported;
- no Secret value or full digest appears.

Work assignment begins only after setup passes. The Integration/Contract owner then provides a single Slice ID and the teammate uses the work-start prompt.
