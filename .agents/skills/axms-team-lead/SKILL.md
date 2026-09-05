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
   - On Orca, supervised work must use one Run with Task/Dispatch ownership. Start every fresh PLAN, WORK, or VERIFY worker with `orca orchestration worker-start --model <model> --effort <thinking>` and require matching `launch.requested` and `launch.effective` values in the JSON receipt. The receipt is dispatch evidence, not independent Provider runtime readback.
   - Orca cannot combine `--terminal` reuse with `--model` or `--effort`. Reuse is allowed only for the same live agent process, an unchanged approved profile, and an original matching launch receipt. Otherwise start a fresh approved-profile worker in the same Worktree; never treat an interactive `/model` change without a new receipt as compliant.
   - Do not rely on Orca's default Git base. Create or reuse the AXMS Feature Worktree through `scripts/start-feature-work.ps1` from current `origin/dev`, then attach the Orca worker to the exact returned Worktree path.
9. For `MULTI TRACK`, fail closed before implementation:
   - Present one plan containing Work IDs, worker-session titles, repositories and Worktrees, dependencies and order, conflict files, completion checks, an independent verification session, and each session's role profile, concrete model, reasoning level, and speed.
   - Ask `이 작업계획과 세션 배정으로 진행할까요?` and stop. Earlier role-transition approval, Work ID approval, or a generic approval given before the plan does not authorize dispatch.
   - After final work-plan approval, report `TEAM PLAN APPROVED`, dispatch the same or worker/verification sessions with the approved `model` and `thinking`, and collect `PLAN PASS`, `SIMPLE PASS`, and `GUARDRAIL PASS` from each before Source changes. A plan-review-only helper does not count as a worker session.
   - If session creation or handoff fails, report `TEAM DISPATCH BLOCKED` and stop. Do not silently replace workers with the lead session or hidden helpers.
   - Report `TEAM DISPATCH PASS` only after every required session passes its plan check. The lead must not directly implement an assigned worker's Source unless the user explicitly reassigns that Work ID.
10. On a Codex native thread host, every preliminary PLAN-only and final approved `create_thread` dispatch must explicitly pass that session's recommended or approved `model` and `thinking`, and every substantive `send_message_to_thread` wake must pass the same override. On Orca, every fresh worker must pass the corresponding `--model` and `--effort`; a reused `--terminal` Dispatch must instead satisfy the immutable launch-receipt conditions above. Do not dispatch if the exact profile cannot be proved, and do not allow Source mutation before final work-plan approval.
11. Present the user-visible dispatch table with session, role profile, concrete model, reasoning level, speed, PROFILE REQUEST, PROFILE ATTEST, PROFILE RUNTIME/dispatch receipt, and state. Mark runtime readback as unsupported rather than claiming it was verified.
12. Monitor dispatched sessions with the host's wait or status mechanism until each completes, blocks, or needs user input. On Orca, use Dispatch-scoped guidance, `check --wait`, `worker_done`, and `worker-release`; a wait timeout alone is not failure. At every state change, inspect the assigned scope and Git Diff; if `SIMPLE PASS` or `GUARDRAIL PASS` is violated, stop the affected session immediately and provide only the minimum correction. Run the independent verification session after its dependencies complete and finish with `TEAM MONITOR PASS`.
13. Do not Push or create a PR before separate user approval. After approval and immediately before Push or PR creation, run `scripts/prepare-dev-pr.ps1 -ApproveNetwork` from the clean Feature Worktree.
