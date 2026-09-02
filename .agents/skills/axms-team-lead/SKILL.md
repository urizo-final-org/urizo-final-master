---
name: axms-team-lead
description: Activate the AX Module Studio session-level team-lead protocol when the first user token is exactly "@팀장" or the user explicitly asks to enter team-lead mode. Ask once before activation; do not activate for quoted or explanatory mentions.
---

# AXMS Team Lead

1. If the user has not yet approved the transition, ask `팀장 프로토콜로 전환할까요?` once and stop before changing the role, title, files, or task state.
2. After approval, read the first existing protocol path completely:
   - `urizo-final-master/docs/team/TEAM_LEAD_PROTOCOL_v0.1.md` from the parent workspace
   - `docs/team/TEAM_LEAD_PROTOCOL_v0.1.md` from the Master repository
3. For AI02~AI06 document or Work ID planning, also read the first existing `AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md` under the corresponding Master path.
4. Load only impacted personal feature documents. Do not load all AI02~AI06 documents or edit another owner's document merely to normalize formatting.
5. Keep team-lead mode scoped to the current session until the user says `@팀장 종료`.
6. Before any Source mutation, classify the work and report `TEAM TRACK PASS: mode=<SINGLE|MULTI>; reason=<reason>`. Two or more independent Work IDs are always `MULTI TRACK`, even in one repository.
7. For `SINGLE TRACK`, obtain Work ID and work-slug approval before implementation. A separate worker session is optional.
8. For `MULTI TRACK`, bind one per-session profile before implementation:
   - The lead recommends `provider`, `role`, `model`, `thinking`, and `speed`; never permanently hardcode a product model name to a role.
   - The lead first proposes a PLAN-only profile-review session. The user must give preliminary approval for `프로필 검토 세션 생성`; this authorizes no Source mutation or final work dispatch.
   - A new PLAN-only task is created and dispatched with the recommended `model` and `thinking`; for a reused task, disclose the profile-review reuse and obtain the same preliminary approval before sending the PLAN prompt with those overrides.
   - Each assigned session must assess support and fit with `PROFILE PLAN PASS` or `PROFILE PLAN ALTERNATIVE`. The lead then presents the confirmed candidate in the final work plan for user approval. An alternative requires the lead to restate that final plan and a new user approval.
   - After approval, retain `PROFILE REQUEST`, `PROFILE ATTEST`, and `PROFILE RUNTIME` as separate evidence. Runtime proves only dispatch request/receipt: this host has no independent runtime model/thinking readback.
   - Omission, mismatch, unsupported settings, automatic fallback, or unapproved downgrade is `MODEL PROFILE BLOCKED` and `TEAM DISPATCH BLOCKED`; do not dispatch.
9. For `MULTI TRACK`, fail closed before implementation:
   - Present one plan containing Work IDs, worker-session titles, repositories and Worktrees, dependencies and order, conflict files, completion checks, and an independent verification session.
   - Ask `이 작업계획과 세션 배정으로 진행할까요?` and stop. Earlier role-transition approval, Work ID approval, or a generic approval given before the plan does not authorize dispatch.
   - After final work-plan approval, report `TEAM PLAN APPROVED`, dispatch the same or worker/verification sessions with the approved `model` and `thinking`, and collect `PLAN PASS` from each before Source changes. A plan-review-only helper does not count as a worker session.
   - If session creation or handoff fails, report `TEAM DISPATCH BLOCKED` and stop. Do not silently replace workers with the lead session or hidden helpers.
   - Report `TEAM DISPATCH PASS` only after every required session passes its plan check. The lead must not directly implement an assigned worker's Source unless the user explicitly reassigns that Work ID.
10. Every preliminary PLAN-only and final approved `create_thread` dispatch must explicitly pass that session's recommended or approved `model` and `thinking`. Every substantive `send_message_to_thread` that wakes a reused task for PLAN, WORK, VERIFY, or remediation must explicitly pass the corresponding recommended or approved `model` and `thinking` override. Do not dispatch if the exact values cannot be supplied, and do not allow Source mutation before final work-plan approval.
11. Present the user-visible dispatch table with session, role, approved profile, PROFILE REQUEST, PROFILE ATTEST, PROFILE RUNTIME/dispatch receipt, and state. Mark runtime readback as unsupported rather than claiming it was verified.
12. Monitor dispatched sessions with the host's wait or status mechanism until each completes, blocks, or needs user input. Run the independent verification session after its dependencies complete and finish with `TEAM MONITOR PASS`.
