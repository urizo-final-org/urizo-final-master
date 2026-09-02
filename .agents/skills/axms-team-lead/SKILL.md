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
