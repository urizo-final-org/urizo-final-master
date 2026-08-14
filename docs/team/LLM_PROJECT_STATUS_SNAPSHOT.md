# AX Module Studio LLM project status snapshot

> Updated: 2026-08-14 (Asia/Seoul)
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
| Frontend | `bffaebde9b4d320cd7031f3dd8f270539b5b54d8` | Frontend PR #3 merged; `AXMS-FND-02` app seam |
| Backend | `45b2afc9ec1db0ba096c0952afe63a7f241c9ad6` | Backend PR #6 merged; `AXMS-FND-01` backend seam |
| Orchestrator | `eaeb3a380035e8ddb13e42fb1877baabd9f57549` | Coding runtime baseline; no Foundation Auth/RBAC change |

## 4. Current Foundation Wave

| Order | Slice | Lead | State | Next gate |
|---:|---|---|---|---|
| 0 | `AXMS-FND-01` Backend seam | 민승준 | merged to Backend `dev` | preserve as the Backend base for FND-03 |
| 0 | `AXMS-FND-02` Frontend app seam | 이재욱 | merged to Frontend `dev` | preserve as the Frontend base for FND-03 |
| 1 | `AXMS-FND-03` Production Auth/RBAC | 정차윤 | ready and assigned; no implementation remote branch or PR observed | pull current Master, Frontend, and Backend; implement the approved two-role MVP in Backend-compatible order, then Frontend |
| deferred | `AXMS-FND-04` broad common Approval/Audit primitive | 민승준 | deferred from the initial MVP gate | introduce only for a concrete later consumer |

`AXMS-FND-03` is one vertical Slice led by 정차윤. Contract/Flyway work, Backend Auth/RBAC,
Frontend login/permission UX, and integrated E2E are repository-specific tasks inside that Slice; they
are not separate owners of the Slice.

## 5. Primary work allocation

| Member | Primary responsibility |
|---|---|
| 민승준 | Integration/Contract owner; shared Contract/Flyway seams, common platform governance, release integration |
| 정차윤 | login, Production Auth/RBAC, members and Project membership/security UX |
| 이재욱 | Frontend feature architecture, menu/site design, Renderer and coding Diff/PR UX |
| 민은지 | Connector, content/page, RAG/Model Mapping and execution evidence |
| 윤서 | board/post, Repository/PathPolicy, Coding Runtime/Orchestrator and RAG evaluation |

Detailed future Slice ownership and dependencies remain in
[`TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md`](TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md).

## 6. Mandatory local LLM start sequence

1. Safely synchronize Master and the assigned repositories without discarding local changes.
2. Re-read Master `AGENTS.md` and this snapshot after synchronization.
3. Read only the assigned Slice rows in the detailed roadmap, the applicable specification, and the
   target repository `AGENTS.md` files.
4. Compare fetched `origin/dev` refs with this snapshot. Report newer evidence or a stale snapshot
   before implementation.
5. Do not require Notion MCP and do not scrape Notion by default.

## 7. Snapshot update triggers

The team lead updates this Git file when any of the following changes:

- Wave or Slice assignment;
- deadline or milestone;
- Slice-level state changes because a PR opened, became blocked, or merged;
- implementation or validation gate;
- blocker or dependency that changes who can start work.

Every progress claim must cite a Repository, PR, commit SHA, or team-lead-confirmed decision. A Notion
write is a separate action and still requires Min Seungjun's explicit instruction in the current task.
