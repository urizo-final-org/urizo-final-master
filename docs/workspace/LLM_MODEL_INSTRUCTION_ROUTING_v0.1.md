# AX Module Studio multi-model LLM instruction routing v0.1

> Updated: 2026-09-07 (Asia/Seoul)
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
This avoids divergent product scope, Git, and safety instructions.

## 2. Required file layout

```text
AX-Module-Studio-Workspace/              # not Git
├── AGENTS.md                            # shared workspace rules for Codex-compatible agents
├── CLAUDE.md                            # imports parent and Master AGENTS for Claude Code
├── urizo-final-master/
│   ├── AGENTS.md                        # Master authority and required-reading router
│   ├── CLAUDE.md                        # imports Master AGENTS for Master-only Claude sessions
│   └── docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md
├── urizo-final-frontend/{AGENTS.md,CLAUDE.md}       # repository router; Claude imports AGENTS
├── urizo-final-backend/{AGENTS.md,CLAUDE.md}        # repository router; Claude imports AGENTS
├── urizo-final-orchestrator/{AGENTS.md,CLAUDE.md}   # repository router; Claude imports AGENTS
└── urizo-final-mcp-server/{AGENTS.md,CLAUDE.md}     # repository router; Claude imports AGENTS
```

Team implementation starts from the common non-Git parent workspace after bootstrap. A Source-only
checkout is not sufficient for automatic project-scope awareness because it does not contain the Master
status and current-scope authority.

## 3. Common start sequence

Both model families must perform the same sequence:

1. read the parent Workspace and Master instructions;
2. classify the task using the Master `AGENTS.md` trigger table;
3. run `scripts/load-task-context.ps1` once with the ordered list of every required Profile and read every ordered Chunk;
4. read the applicable Source `AGENTS.md` and compare the task with the loaded scope and ownership;
5. run Master-first safe synchronization when the task requires Git freshness;
6. return `TASK CONTEXT PASS` and `MASTER CONTEXT PASS`, or stop with the exact blocker before mutation.

Model identity never changes Repository ownership, approval boundaries, Git naming, Definition of Done,
or Notion-write authority.

Both model families also inherit the same `Simple is best` rule, scope-expansion approval gate, and
short status-report format from Master `AGENTS.md`. These behaviors are not copied into model-specific
files.

## 4. Bounded task-context loading

An ordinary Markdown link is routing text, not an import. The SessionStart Hook automatically loads only
the Workspace, Master, and active Source `AGENTS.md` authorities. A linked document is authoritative only
after its content has been emitted and read for the matching task.

Use the shared loader from the active Master checkout or Worktree:

```powershell
./scripts/load-task-context.ps1 -Profile Git
./scripts/load-task-context.ps1 -Profile AiFeature -FeatureNumber 6
./scripts/load-task-context.ps1 -Profile Database -BackendSourceRoot <absolute-active-backend-worktree>
./scripts/load-task-context.ps1 -Profile Runtime,Database,Git -BackendSourceRoot <absolute-active-backend-worktree>
```

| Profile | Required documents |
|---|---|
| `Product` | current CMS minimum scope and project-status Snapshot |
| `Git` | Git/team operating policy and repository/bootstrap specification |
| `Runtime` | current local infrastructure and multi-OS local-development specification |
| `Database` | Git/team operating policy, Flyway reservation ledger, Runtime/Flyway rules, and the active Backend database policy |
| `AiFeature` | Snapshot, AI common boundary, structure contract, and the selected AI 2~6 document |
| `TeamLead` | team-lead protocol after the explicit activation approval |
| `Master` | this routing contract, Snapshot, and Git/team operating policy |

`-Profile` accepts one Profile or an ordered list. For a list, the loader walks Profiles in input order,
keeps each Profile's document order, and emits the first occurrence of each normalized document path once.
It does not summarize or remove document content. A one-Profile call keeps the existing body and Receipt contract.

The loader validates every allowlisted path, rejects missing or empty files, fingerprints the exact UTF-8
content, and emits bounded output. The default limits are 128 KiB for the complete normalized union bundle and
16 KiB for each Receipt; exceeding either fails closed. Large profiles are split at line boundaries. Start with the default
`-ChunkNumber 1`, read the returned `chunk=1/N`, then call the same command with `-ChunkNumber 2` through
`N`, preserving the same ordered Profile list. Every call after Chunk 1 must pass the first Receipt's `bundleSha256` through
`-ExpectedBundleSha256` and the immediately preceding Receipt's `chunkSha256` through
`-PreviousChunkSha256`. A missing or mismatched bundle hash detects documents changed between calls;
a missing or mismatched Chunk hash detects an out-of-order sequence. Both fail closed. `complete=true`
identifies only the final Chunk and does not waive the earlier Chunks.

Any Profile list containing `Database` requires an explicit absolute `-BackendSourceRoot`. It reads only
`docs/DATABASE_MIGRATION_POLICY_v0.2.md` below that exact checkout or Worktree and records both the normalized
Source root and policy SHA-256 in the Receipt. There is no parent-directory search or implicit canonical fallback.
The Profile also loads `TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md`, so Runtime and Database receive the
same a~e Runtime/Flyway rules without copying them. A local `full` operation that executes Flyway uses one
`-Profile Runtime,Database,Git` union call.

`TASK CONTEXT PASS` is valid only after all Chunks were read in order and the active Source `AGENTS.md`
was also read when applicable. A missing file, unreadable file, invalid Feature number, missing Chunk,
out-of-order sequence, or byte-limit failure is `TASK CONTEXT BLOCKED`. No affected Source, Git, runtime,
database, or external mutation may continue from a partial Receipt.

The loader does not fetch Git, query GitHub or Notion, mutate a file, or infer which Profile applies.
Master `AGENTS.md` owns task classification. Operational safety remains enforced by the existing
feature-work, pre-PR, pre-push, runtime, and database gates; linked prose is not their substitute.

## 5. What may be model- or Source-repository-specific

Model-specific and Source-repository entry files may contain only:

- how that coding agent loads the common instructions;
- model/tool-specific navigation or context-loading guidance;
- a short warning about unsupported automatic discovery.
- the Source repository's stable scope and ownership boundary;
- links to repository-local build, test, migration, or runtime documentation.

They must not contain a private copy of product scope, assignments, runtime versions,
Git workflow, or safety rules. Those facts change over time and remain in their designated Master files.
Source `AGENTS.md` files are therefore routing stubs, not secondary policy authorities. Source
`CLAUDE.md` files import the corresponding `AGENTS.md` and add no duplicate common policy.

## 6. Update behavior

- The team lead updates common policy in Master `AGENTS.md` and task/version state in
  `LLM_PROJECT_STATUS_SNAPSHOT.md`.
- `templates/workspace/AGENTS.md` and `templates/workspace/CLAUDE.md` contain managed blocks. The Master
  bootstrap synchronizes those blocks without replacing teammate custom text.
- A model-routing change requires Master scaffold validation. A product-scope change normally does not
  require editing `CLAUDE.md` because Claude imports the shared authority.
- A Profile or required-document change must update the allowlist in `scripts/load-task-context.ps1`, the
  Master `AGENTS.md` trigger table, and the scaffold validation in one Master change.

## 7. Acceptance

Routing passes only when:

- Master has both `AGENTS.md` and `CLAUDE.md`;
- Master `CLAUDE.md` imports `@AGENTS.md`;
- the parent Claude template imports both parent and Master `AGENTS.md`;
- bootstrap can append or replace exactly one managed Claude-routing block idempotently;
- Codex-compatible and Claude sessions report the same assigned Slice/Task version after one Git sync;
- the Master `AGENTS.md` remains within its byte budget and Full Hook output remains within the combined
  Master-plus-Source budget;
- every Profile returns fingerprinted, bounded Chunks and fails closed for missing or invalid input.
- `Database` fails closed without the explicit Backend root or exact Backend policy and fingerprints both in its Receipt.
