# AX Module Studio multi-model LLM instruction routing v0.1

> Updated: 2026-08-14 (Asia/Seoul)
> Owner: Min Seungjun (`tmdwns0531`)
> Scope: Codex-compatible GPT coding agents and Claude Code used by the five-person team

## 1. Decision

Project rules have one common source. They are not copied into separate GPT and Claude rule sets.

| Agent family | Automatic entry point | Common authority |
|---|---|---|
| Codex-compatible GPT coding agent | nearest applicable `AGENTS.md` | parent Workspace `AGENTS.md` → Master `AGENTS.md` → changed Source Repository `AGENTS.md` |
| Claude Code | nearest applicable `CLAUDE.md` | `CLAUDE.md` imports the same `AGENTS.md` content, then adds only Claude-specific routing |
| Generic chat UI without local-file discovery | none guaranteed | unsupported for unattended implementation; the user must provide the task packet or use the configured coding workspace |

There is no separate `GPT.md`. `AGENTS.md` remains the GPT/Codex-compatible entry point. Claude Code
does not automatically consume `AGENTS.md`, so the committed `CLAUDE.md` imports it with `@AGENTS.md`.
This avoids divergent product, Git, safety, and WBS instructions.

## 2. Required file layout

```text
AX-Module-Studio-Workspace/              # not Git
├── AGENTS.md                            # shared workspace rules for Codex-compatible agents
├── CLAUDE.md                            # imports parent and Master AGENTS for Claude Code
├── urizo-final-master/
│   ├── AGENTS.md                        # Master authority and required-reading router
│   ├── CLAUDE.md                        # imports Master AGENTS for Master-only Claude sessions
│   └── docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md
├── urizo-final-frontend/AGENTS.md
├── urizo-final-backend/AGENTS.md
└── urizo-final-orchestrator/AGENTS.md
```

Team implementation starts from the common non-Git parent workspace after bootstrap. A Source-only
checkout is not sufficient for automatic project/WBS awareness because it does not contain the Master
status and handoff authority.

## 3. Common start sequence

Both model families must perform the same sequence:

1. read the parent Workspace and Master instructions;
2. run Master-first safe synchronization when asked to update Git;
3. re-read the checked-in Master status snapshot and operating policy;
4. match Snapshot version, Slice ID, Task version, worker, target repositories, and next Gate;
5. read only the assigned Slice documents and applicable Source `AGENTS.md` files;
6. return `MASTER CONTEXT PASS` or `MASTER CONTEXT BLOCKED` before implementation.

Model identity never changes Repository ownership, approval boundaries, Git naming, Definition of Done,
or Notion-write authority.

## 4. What may be model-specific

Model-specific entry files may contain only:

- how that coding agent loads the common instructions;
- model/tool-specific navigation or context-loading guidance;
- a short warning about unsupported automatic discovery.

They must not contain a private copy of role permissions, Slice ownership, WBS state, runtime versions,
Git workflow, or safety rules. Those facts change over time and remain in their designated Master files.

## 5. Update behavior

- The team lead updates common policy in Master `AGENTS.md` and task/version state in
  `LLM_PROJECT_STATUS_SNAPSHOT.md`.
- `templates/workspace/AGENTS.md` and `templates/workspace/CLAUDE.md` contain managed blocks. The Master
  bootstrap synchronizes those blocks without replacing teammate custom text.
- A model-routing change requires Master scaffold validation. A product or WBS change normally does not
  require editing `CLAUDE.md` because Claude imports the shared authority.

## 6. Acceptance

Routing passes only when:

- Master has both `AGENTS.md` and `CLAUDE.md`;
- Master `CLAUDE.md` imports `@AGENTS.md`;
- the parent Claude template imports both parent and Master `AGENTS.md`;
- bootstrap can append or replace exactly one managed Claude-routing block idempotently;
- Codex-compatible and Claude sessions report the same assigned Slice/Task version after one Git sync.
