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
- `전체 Git 최신화`, `워크스페이스 최신화`처럼 전체 범위를 명시한 요청은
  `urizo-final-master/scripts/sync-workspace.ps1 -ApproveNetwork`로 Master plus all three Source repositories를 확인한다.
- 일반 `git pull`은 요청된 저장소 범위에서 수행할 수 있으며, 성공한 Pull은 Codex·Claude `PostToolUse` Hook이 감지해
  기존 공통 로더로 Workspace·Master·현재 저장소 `AGENTS.md`를 활성 세션에 다시 주입한다.
- 표준 Workspace 최신화는 Master와 Source 확인 뒤
  `urizo-final-master/scripts/bootstrap-workspace.ps1 -SyncLlmHooks`를 자동 실행해 Codex·Claude `SessionStart` Hook을 함께 갱신한다.
  활성 LLM은 같은 턴에 Master 기준을 다시 읽고, 새 Hook은 다음 `startup`·`resume`·`clear`·`compact`와 성공한 `git pull` 뒤 적용한다.
  주입된 `AGENTS.md`와 실제 변경 범위를 기준으로 전체 실행 Script, Frontend Watch·HMR, 그 외 격리 Service 갱신 중
  적용 모드를 LLM이 판단하고 `LOCAL RUNTIME CONTEXT PASS`로 보고한다.
- 신규 Workspace 설정이나 수동 Master 갱신처럼 표준 최신화를 거치지 않았을 때만 활성 LLM이 Hook 동기화를 직접 실행한다.
- 두 도구는 같은 Master 원문 로더를 사용하며 실패 시 자동 재시도 없이 `continue: false`와 `MASTER CONTEXT BLOCKED`로 해당 턴을 종료한다. Codex 최초 신뢰 확인은 팀원이 한 번 승인한다.
- `CMS 로컬 실행`, `시스템 띄워줘`, `로컬 재기동`은
  `urizo-final-master/scripts/start-local-cms.ps1 -ApproveLocalMutation`으로 처리한다. 이미 정상이면 `spring-core`를 즉시 재사용하고, 최초 Image 준비는 `-ApproveNetwork`, Source 변경 반영은 `-Rebuild -ApproveNetwork`를 추가한다. CMS 실행 때문에 범위 밖 Coding Runtime을 기다리거나 임의 Docker 명령을 조합하지 않는다.
- 동기화는 자동 Branch 전환, Rebase, 충돌 해결, Reset, Stash Pop, 로컬 변경 삭제를 하지 않는다.
- Master 공통 기준과 공통 문서는 Min Seungjun(`tmdwns0531`)만 수정한다. AI 핵심 기능 담당자는
  `urizo-final-master/docs/product/ai-core/`에서 자신에게 배정된 상세 문서만 Feature Branch와 `dev` 대상 PR로 수정한다.
- 2~6번 작업에서는 현재 PC GitHub ID와 담당자 표를 대조해 공통 문서와 배정된 상세 문서를 읽고
  `AI FEATURE CONTEXT PASS`를 보고한다. 새 작업의 Work ID·work slug는 작업 시작 전에 한 번 제안한다.
- 조사·분석과 기능 MD 수정만이면 Worktree를 만들지 않는다. 실제 Source 구현은 Work ID 승인 후 저장소별
  최신 `origin/dev` 기반 독립 Worktree에서 시작한다. 같은 PR은 재사용하고 다음 독립 PR은 새 Work ID와 Worktree를 쓴다.
- Work ID는 작업 시작부터 PR 생성까지며 같은 PR의 작업을 묶는다. PR 생성 시 문서 연결을 한 번 제안하고,
  기록된 PR은 다음 `SessionStart`에서 현행화한다. Hook은 읽기 전용이며 상세 규칙은 Master 운영 정책을 따른다.
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
