# AX Module Studio Master repository and bootstrap specification v0.1

## 1. Decision

Adopt four sibling Git repositories under a parent that has no `.git`:

```text
AX-Module-Studio-Workspace/
├── AGENTS.md                         # generated only when absent
├── CLAUDE.md                         # generated only when absent
├── AX-Module-Studio.code-workspace   # generated only when absent
├── urizo-final-master/
├── urizo-final-frontend/
├── urizo-final-backend/
└── urizo-final-orchestrator/
```

Master is a control/handoff repository. It does not vendor, subtree, submodule, copy, or build the three source repositories. Backend remains the integrated Compose and Dev bootstrap root.

## 2. Master file tree

```text
urizo-final-master/
├── AGENTS.md
├── README.md
├── repository-manifest.json
├── AX-Module-Studio.code-workspace
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── README.md
│   ├── handoff/
│   │   └── AX_Module_Studio_IMPLEMENTATION_TEAM_HANDOFF_v0.7.md
│   ├── traceability/
│   │   └── FEATURE_TRACEABILITY_MATRIX_v0.1.md
│   ├── team/
│   │   ├── TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md
│   │   └── FLYWAY_RESERVATION_LEDGER.md
│   └── workspace/
│       └── MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.1.md
├── templates/workspace/
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   └── AX-Module-Studio.code-workspace
└── scripts/
    ├── preflight-workspace.ps1
    ├── bootstrap-workspace.ps1
    ├── health-workspace.ps1
    └── validate-master-scaffold.ps1
```

## 3. New teammate flow

Prerequisite: the reviewed Master baseline and current source baseline must already exist in the canonical remotes. This is not true at the 2026-08-12 local checkpoint; see §8.

After cloning Master as `AX-Module-Studio-Workspace/urizo-final-master`, the intended single command is:

```powershell
.\scripts\bootstrap-workspace.ps1 -ApproveNetwork -RunLocalFull -ApproveLocalFullMutation
```

The command performs:

```text
manifest and parent no-.git validation
→ inspect every existing target before any network write
→ clone a missing source repo only into a missing/empty exact sibling path
→ fetch canonical origin refs in existing repos without merge/checkout
→ generate parent AGENTS/CLAUDE/workspace only when the target is absent
→ require all source worktrees clean before local-full bootstrap
→ invoke Backend's version-managed bootstrap-dev.ps1
→ invoke Backend's health.ps1
```

It never performs `pull`, checkout, reset, clean, stash, rebase, force, overwrite, database reset, or Docker volume deletion.

Planning without network or mutation:

```powershell
.\scripts\bootstrap-workspace.ps1 -WhatIf
```

Read-only inspection of an existing workspace:

```powershell
.\scripts\preflight-workspace.ps1
.\scripts\health-workspace.ps1
```

## 4. Approval and stop boundaries

| Boundary | Script behavior |
|---|---|
| Network clone/fetch | requires `-ApproveNetwork`; otherwise reports and stops |
| Existing non-empty folder without expected Git repo | blocks; never overwrites or deletes |
| Canonical origin mismatch | blocks; never rewrites remote |
| Existing source worktree dirty | clone/fetch may be inspected, but local-full bootstrap blocks; never stashes/resets |
| Existing parent AGENTS/CLAUDE/workspace differs | warns and skips; never overwrites |
| Git authentication/MFA/browser/device flow needed | Git reports failure; script stops and asks user to complete authentication externally |
| WSL2/Docker Desktop absent or stopped | blocks; never installs, elevates, or reboots |
| Local-full build/secret/migration/container mutation | requires `-RunLocalFull` and `-ApproveLocalFullMutation` plus clean source trees |
| New Product/Provider/public-data secrets | never requested in prompt/arguments; user enters them in CMS after service starts |
| Prod/Cloud/SSH/firewall/OS account | out of scope and blocked by policy |

Passing an approval switch when a human runs the script is not permission for an agent to bypass the conversational approval boundary. An agent must still obtain explicit user approval before invoking the network or mutation modes.

## 5. Existing repository behavior

For an existing valid repository:

- verify exact canonical origin;
- report branch, HEAD, and dirty state;
- with network approval, run only `git fetch --prune origin`;
- do not set upstream, fast-forward, merge, switch branch, or update the worktree.

This means daily source synchronization remains a separate Backend/team workflow. Master bootstrap is for safe discovery and initial assembly, not for silently changing a developer's active branch.

## 6. Runtime ownership

Master wrappers do not reproduce Backend bootstrap logic. They delegate to:

```text
urizo-final-backend/scripts/bootstrap-dev.ps1 -Profile full
urizo-final-backend/scripts/health.ps1 -Profile full
```

Backend owns Compose, Flyway, one-shot services, runtime role sync, local secret initialization, builds, and health semantics. Master only confirms the sibling boundary and explicit approval flags before delegation.

## 7. Secrets

No secret value, full fingerprint/digest, password, token, private key, or production DB URL belongs in Master, its templates, script arguments, reports, or logs.

Documentation states only the input location:

- LLM Provider and public-data credentials: local CMS secret forms after service startup;
- LangSmith: separate Super Admin observability/evaluation form;
- Git/registry authentication: platform credential helper or CI secret store, outside CMS prompts;
- local infrastructure materials: Backend version-managed initialization flow, never copied to Master.

## 8. Current reproduction blocker

At the 2026-08-12 checkpoint:

- Master remote was empty;
- Frontend/Backend/Orchestrator implementations were predominantly untracked/uncommitted local changes;
- the preserved local runtime was healthy, but canonical remotes did not contain that implementation.

Therefore the one-command remote bootstrap is a validated scaffold and future contract, not a claim that a clean PC can reproduce the current local-full system today. Reproduction becomes valid only after separately authorized repository-specific review, verification, commit, push, PR, merge, and a clean second-PC bootstrap test.

## 9. Verification

`validate-master-scaffold.ps1` is network-free and checks:

- required files;
- JSON parsing of manifest and workspace files;
- PowerShell parsing of all scripts;
- expected four repository entries and canonical URLs;
- absence of destructive command patterns;
- absence of copied source-repository directories inside Master.

`preflight-workspace.ps1` then verifies the live Git/workspace/runtime boundary without changing it. Full local health remains authoritative in Backend `health.ps1`.
