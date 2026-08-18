# AX Module Studio LLM project status snapshot

> Updated: 2026-08-18 (Asia/Seoul)
> Snapshot-Version: `v0.3`
> Owner: Min Seungjun (`tmdwns0531`), Integration/Contract owner
> Purpose: small Git-owned status and WBS view that every teammate LLM reads after synchronizing Master

This is the current operational snapshot for local LLMs. It complements the detailed roadmap and
handoff without allowing teammate Notion MCP connections or full Notion workspace scraping.
Only Min Seungjun updates this Master file. Teammates consume it read-only and report Source PR/Git
evidence through their assigned Repository workflow.

## 1. Authority and freshness

- Technical completion and progress come from canonical Git commits, merged PRs, checks, and current
  repository state.
- Work assignment, milestone, and priority changes require team-lead confirmation.
- Notion Gantt, WBS, and timeline pages are human-facing projections. They are updated only when Min
  Seungjun explicitly requests a Notion write in the current task.
- If a fetched Frontend, Backend, or Orchestrator remote ref is newer than the SHA recorded below, use
  the newer Git evidence for implementation state and report this snapshot as stale. The checked-out
  commit containing this file is the current Master evidence. Do not guess an assignment or deadline.

## 2. Delivery milestones

| Gate | Target | Meaning |
|---|---|---|
| MVP implementation complete | 2026-09-13 | integrated product completion target and start of presentation preparation |
| Final presentation | 2026-09-21 | team final presentation |

## 3. Verified repository baseline

Verified by fetching each canonical `origin/dev` on 2026-08-14.

| Repository | `origin/dev` | Latest verified evidence |
|---|---|---|
| Master | base `e79637c6fbedf70135bb52ff23e069642a2cb8a8` | snapshot-PR base; the commit containing this file supersedes this embedded base |
| Frontend | `0ba4295cf55e4b33c4fbacce6d8f75c4df837817` | Frontend PR #4 merged; `AXMS-FND-03` login and role-aware navigation |
| Backend | `e0a702dbfaf6f1c46d9ba21e88a08c013047e2fb` | Backend PR #7 merged; `AXMS-FND-03` production login and role enforcement |
| Orchestrator | `eaeb3a380035e8ddb13e42fb1877baabd9f57549` | Coding runtime baseline; no Foundation Auth/RBAC change |

## 4. Current Foundation Wave and worker-task versions

| Order | Slice | Task version | Lead | Target repositories | State | Next gate |
|---:|---|---|---|---|---|---|
| 0 | `AXMS-FND-01` Backend seam | `v0.1` | 민승준 / `tmdwns0531` | Backend | merged to Backend `dev` | preserve as the Backend base for FND-03 |
| 0 | `AXMS-FND-02` Frontend app seam | `v0.1` | 이재욱 / `LEEJAEWOOK1` | Frontend | merged to Frontend `dev` | preserve as the Frontend base for FND-03 |
| 1 | `AXMS-FND-03` Production Auth/RBAC | `v0.2` | 정차윤 / `jcy644542` | Backend, Frontend | `DONE`: Backend PR #7 and Frontend PR #4 merged; reduced single-customer boundary | preserve login/role authority; Project isolation is not implemented and full member management moves to CMS-01 |
| 2 | `AXMS-FND-04` broad common Approval/Audit primitive | `N/A` | no assignee | no target | `RETIRED`: the original Wave 2 slot is closed and is not reused | Coding dual approval remains consumer-owned by later Coding/LLM DevOps Slices |

`Task version` is the team-lead-controlled version of one worker's assigned Slice packet. Min Seungjun
increments it when the assigned worker, scope, target repositories, dependencies, or next gate changes.
Ordinary implementation commits do not change it. A reassignment creates a new row/version rather than
silently replacing the previous assignment history.

`AXMS-FND-03` is one vertical Slice led by 정차윤. Contract/Flyway work, Backend Auth/RBAC,
Frontend login/permission UX, and integrated E2E are repository-specific tasks inside that Slice; they
are not separate owners of the Slice.

The authoritative completion boundary is
[`AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md`](../product/AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md).
Do not infer Project isolation from persisted membership types. The current demonstration is single
customer, and FND-03 intentionally does not narrow `GENERAL_ADMIN` access by Project.

## 5. Next active Wave — Wave 3

The original `Wave 2 = AXMS-FND-04` work was retired without renumbering later team Waves. Therefore the
next active work is **Wave 3**, the parallel `AXMS-CMS-01` through `AXMS-CMS-04` manual-CMS Wave. A
separate Task Packet is not required to recognize or name Wave 3. Shared contracts and Flyway revisions
must still be reserved before a Slice edits those shared seams.

| Slice | Lead | State | Next gate |
|---|---|---|---|
| `AXMS-CMS-01` | 정차윤 / `jcy644542` | `NEXT — WAVE 3` | member/account status and membership contract reservation |
| `AXMS-CMS-02` | 이재욱 / `LEEJAEWOOK1` | `NEXT — WAVE 3` | MenuSpec contract reservation |
| `AXMS-CMS-03` | 민은지 | `NEXT — WAVE 3` | Content/PageSpec contract reservation and confirmed GitHub ID |
| `AXMS-CMS-04` | 윤서 / `HaveOffDuty` | `NEXT — WAVE 3` | Board/Post contract reservation |

## 6. Primary work allocation

| Member | Primary responsibility |
|---|---|
| 민승준 | Integration/Contract owner; shared Contract/Flyway seams, common platform governance, release integration |
| 정차윤 | login, Production Auth/RBAC, members and Project membership/security UX |
| 이재욱 | Frontend feature architecture, menu/site design, Renderer and coding Diff/PR UX |
| 민은지 | Connector, content/page, RAG/Model Mapping and execution evidence |
| 윤서 | board/post, Repository/PathPolicy, Coding Runtime/Orchestrator and RAG evaluation |

Detailed future Slice ownership and dependencies remain in
[`TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md`](TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md).

## 7. Mandatory local LLM start sequence

1. Safely synchronize Master and the assigned repositories without discarding local changes.
2. Re-read Master `AGENTS.md` and this snapshot after synchronization.
3. Match the team-lead-announced Snapshot version, Slice ID, Task version, worker, and target
   repositories to this file. Stop and report a mismatch instead of guessing.
4. Read only the assigned Slice rows in the detailed roadmap, the applicable specification, and the
   target repository `AGENTS.md` files.
5. Compare fetched `origin/dev` refs with this snapshot. Report newer evidence or a stale snapshot
   before implementation.
6. Return the following acknowledgement before implementation:

```text
MASTER CONTEXT PASS | BLOCKED
Snapshot-Version:
Slice-ID / Task-Version:
Worker: <name> / <github-id>
Target-Repositories:
Next-Work:
Next-Gate:
Blocker:
Source-origin/dev:
```

7. Do not require Notion MCP and do not scrape Notion by default.

## 8. Team-lead update and next-work handoff

Only Min Seungjun updates this file. After verifying the relevant Source `origin/dev`, merged PRs, and
checks, he updates the worker-task row and announces the exact checked-in context using this compact
packet:

```text
MASTER UPDATE COMPLETE
Snapshot-Version:
Slice-ID / Task-Version:
Worker: <name> / <github-id>
Target-Repositories:
Current-State:
Next-Work:
Depends-On:
Next-Gate:
Master-Commit:
```

The announcement is the signal for the teammate to request Git synchronization. It is not a substitute
for the checked-in Master evidence: the local LLM must pull, read this file, and return `MASTER CONTEXT
PASS` before starting. If the announcement, local Master commit, or assignment row differs, return
`BLOCKED` with the mismatch and do not implement against an assumed version.

## 9. Snapshot update triggers

The team lead updates this Git file when any of the following changes:

- Wave or Slice assignment;
- deadline or milestone;
- Slice-level state changes because a PR opened, became blocked, or merged;
- implementation or validation gate;
- blocker or dependency that changes who can start work.

Every progress claim must cite a Repository, PR, commit SHA, or team-lead-confirmed decision. A Notion
write is a separate action and still requires Min Seungjun's explicit instruction in the current task.
