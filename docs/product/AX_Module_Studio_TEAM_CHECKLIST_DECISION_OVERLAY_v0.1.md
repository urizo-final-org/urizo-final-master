# AX Module Studio team checklist decision overlay v0.1

> Decision date: 2026-08-18 (Asia/Seoul)
> Status: team-lead-confirmed current product and execution authority
> Applies to: role target, Approval/Audit MVP boundary, CMS execution order, and later LLM DevOps approval Gates
> Supersedes on conflict: the earlier Auth/RBAC MVP interpretation, FND-03 scope decision, handoff text,
> and future Phase assignments in the team roadmap

## 1. Authority

This Git document records the approved decisions extracted from the 2026-08-18 team checklist. The
external checklist remains meeting input; teammate LLMs use this checked-in overlay as the normative
source. Earlier documents remain valid for delivered Git evidence and historical scope except where
this overlay explicitly changes the current product target or future execution policy.

## 2. Decision 1 — fixed role target includes a general user

The current product target has three fixed roles:

| Role | Korean UI name | Product responsibility |
|---|---|---|
| `SUPER_ADMIN` | 최고관리자 | delivery-company technical configuration, integration, security, and support |
| `GENERAL_ADMIN` | 일반관리자 | customer-company CMS operation, preview, publication, and business decisions |
| `GENERAL_USER` | 일반 사용자 | uses the published end-user site and user-facing functions without administrator authority |

The delivered `AXMS-FND-03` evidence remains a two-administrator-role implementation. It does not prove
that `GENERAL_USER` authentication or authorization is implemented. `AXMS-CMS-01` owns General User
account/status/permission administration, while `AXMS-CMS-07` owns the General User login/session and
published Renderer experience. The current CMS contract reservation may refine the boundary between
those two Slices without removing the fixed role.

## 3. Decision 2 — Approval History and core Audit Log are in the MVP

The MVP includes an Approval History screen and a core Audit Log screen. The minimum recorded scope is:

- administrator and General User account/status/permission changes;
- CMS Draft/version changes and validation outcomes;
- Preview, publish, unpublish, Site Release, and rollback decisions;
- later RAG operating-version decisions when that feature is opened;
- the three later LLM DevOps dual-approval Gates when that feature is opened.

This inclusion does not create a separate `REVIEWER` role and does not add a `SUPER_ADMIN` pre-approval
Gate to ordinary manual CMS work. An assigned `GENERAL_ADMIN` still previews and directly publishes or
rolls back permitted CMS content. The system records that human decision and its evidence. The MVP logs
core state-changing actions, not every page view, click, or read.

Each `AXMS-CMS-01` through `AXMS-CMS-07` Slice emits its applicable core events. `AXMS-CMS-06` owns the
integrated Approval History/Audit Log query and administration UI over those records through the shared
Integration/Contract lane.

## 4. Decision 3 — fixed CMS order, then a new team planning Gate

The only approved execution order beyond completed Foundation work is:

```text
Wave 3: AXMS-CMS-01 + AXMS-CMS-02 + AXMS-CMS-03 + AXMS-CMS-04 in parallel
→ AXMS-CMS-05
→ AXMS-CMS-06
→ AXMS-CMS-07 and integrated CMS acceptance
→ team deep-dive planning Gate
→ newly confirm the order, owner, scope, Slice IDs, dependencies, and PR order of remaining work
```

The former roadmap Phase 2 through Phase 5 rows are backlog inventory and historical planning input
only. They are not active assignments, do not authorize implementation, and do not fix the order or
owner of real public-data/RAG/Model Mapping, Repository/PathPolicy/Coding, natural-language CMS, or LLM
DevOps work. After the CMS acceptance Gate, the team lead publishes a new checked-in decision before any
of those capabilities starts.

## 5. Decision 4 — exactly three LLM DevOps dual-approval Gates

Later LLM DevOps has exactly three human dual-approval Gates:

1. autonomous-coding result approval;
2. PR creation approval;
3. deployment approval.

Each Gate requires two distinct accounts: one `GENERAL_ADMIN` for customer/business intent and one
`SUPER_ADMIN` for technical/security/delivery risk.

```text
Natural-language request
→ limited code change
→ one allowlisted test
→ result / Diff / evidence
→ Gate 1: autonomous-coding result dual approval
→ Gate 2: PR creation dual approval
→ automatic CI/readback and manual merge under Git policy
→ Gate 3: deployment dual approval
```

The internal request→code change→test→result sequence has no human approval pause. Scope, PathPolicy,
denylist, allowlisted commands, and evidence production remain automatic fail-closed safety checks, not
additional human approval Gates. Manual PR merge follows Git policy and is not a fourth product
dual-approval Gate.

## 6. LLM execution rule

Until the CMS completion and integrated acceptance Gate passes:

- report Wave 3 and the applicable CMS Slice only;
- do not start a post-CMS backlog capability;
- do not infer a future owner or order from superseded Phase tables;
- preserve the three-Gate LLM DevOps constraint as a future product invariant, not an active task.

After CMS completion, return `MASTER CONTEXT BLOCKED` for post-CMS implementation until the team lead's
new Git decision names the confirmed Slice, owner, target repositories, scope, dependencies, and next
Gate.
