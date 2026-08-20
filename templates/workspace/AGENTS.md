# AX Module Studio Workspace Agent Rules

## 저장소 경계

- 이 상위 폴더에는 `.git`을 만들지 않는다.
- Master, Frontend, Backend, Orchestrator는 각각 독립 저장소다.
- 여러 저장소를 변경하면 같은 Slice ID/work slug를 쓰고 Commit/PR은 분리한다.

## 현재 기준

- 먼저 `urizo-final-master/AGENTS.md`, 현재 CMS 최소 범위, 상태 Snapshot을 읽는다.
- 제품 Source는 해당 Source 저장소에만 작성한다.
- 현재 CMS 문서에 없는 기능은 구현하지 않는다.
- 범위 안의 세부 구현은 자율적으로 진행한다.
- 새로운 화면·기능·역할·워크플로·외부 연동이 필요하면 멈추고 팀장 승인을 요청한다.
- 과거 CMS Spec, handoff, traceability, Wave, 업무분장은 복원하지 않는다.

<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:BEGIN -->
## 자동 작업 정책

- 구현 전 Master 현재 기준과 변경할 Source `AGENTS.md`를 읽고 할당된 범위와 저장소를 확인한다.
- Codex와 Claude 모두 Master의 `Simple is best`, 범위 확장 승인 게이트, 공통 응답 형식을 따른다.
- 필요 범위를 넘는 구현·리팩터링·추상화·설정·문서·Slice는 승인 전 절대 진행하지 않는다.
- 일치하면 `MASTER CONTEXT PASS`, 다르거나 범위 확장이 필요하면 `MASTER CONTEXT BLOCKED`를 보고한다.
- `깃 pull 해줘`, `전체 Git 최신화`, `워크스페이스 최신화`는
  `urizo-final-master/scripts/sync-workspace.ps1 -ApproveNetwork`로 Master plus all three Source repositories를 확인한다.
- 동기화는 자동 Branch 전환, Rebase, 충돌 해결, Reset, Stash Pop, 로컬 변경 삭제를 하지 않는다.
- Only Min Seungjun(`tmdwns0531`) writes Master. 팀원은 Master를 읽기 전용으로 사용한다.
- Every agent-created PR in Master, Frontend, Backend, and Orchestrator targets `dev`.
- `main` is reserved for periodic manual promotion by Min Seungjun.
- Git이 구현 상태의 기준이다.
- Notion은 Min Seungjun이 현재 요청에서 명시적으로 지시한 경우에만 쓴다.
<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:END -->

## 작업·안전

- 새 작업은 깨끗한 최신 `dev` 기반 Feature Branch나 별도 Worktree에서 시작한다.
- Dirty, Diverged, local-only 작업을 자동 Reset, Clean, Stash, Checkout, Rebase하지 않는다.
- DB, Docker Volume, Secret, 실행 중 Container를 보존한다.
- Secret을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다.
- Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행한다.
- `dev/main` 직접 Push, `main` 대상 PR, Force Push, 자동 Merge를 금지한다.
- 공개 계약, Flyway, App Shell/Router, 공통 Auth/Error, Compose/Bootstrap은 공통 담당과 충돌을 먼저 확인한다.
- DB 변경은 Flyway Revision을 예약하고 빈 DB·기존 DB·반복 실행·Runtime DDL 거부를 확인한다.
- 요청받지 않은 Push, PR, Merge, Notion 쓰기, 배포는 하지 않는다.
