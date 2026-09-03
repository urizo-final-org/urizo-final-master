# AX Module Studio Workspace Agent Rules

## 저장소 경계

- 이 상위 폴더에는 `.git`을 만들지 않는다.
- Master, Frontend, Backend, Orchestrator, MCP Server는 각각 독립 저장소다.
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
  `urizo-final-master/scripts/sync-workspace.ps1 -ApproveNetwork`로 Master plus all four Source repositories를 저장소별로 끝까지 확인한다. Dirty canonical은 `PRESERVED`로 보고 Working Tree를 보존하며 관계없는 깨끗한 Source 동기화는 계속한다.
- Dirty·차단 canonical이 있으면 공용 Hook과 현재 컨텍스트 갱신만 보류한다. 모든 canonical이 안전할 때만 Hook을 갱신하고 AGENTS 지문에 따라 Full 또는 4KB 이하 Checkpoint를 불러온다.
- Codex·Claude Context Hook은 `startup|clear|compact`에서 Master와 활성 Source 원문을 불러오고 `resume`과 `PostToolUse`가 감지한 일반 Pull에서는 4KB 이하 Checkpoint만 불러온다. Pull 결과에 `AGENTS.md` 변경이 있을 때만 전체 원문을 한 번 갱신하며 Workspace AGENTS 원문은 중복 주입하지 않는다.
- 새 구현 작업은 `urizo-final-master/scripts/start-feature-work.ps1 -RepositoryName <repo> -BranchName <feature/...> -ApproveNetwork`로 시작한다. 이 Gate가 canonical `dev` Pull과 최신 `origin/dev` 기반 독립 Worktree 생성을 수행한다.
- Push·PR 직전에는 깨끗한 Feature Worktree에서 `urizo-final-master/scripts/prepare-dev-pr.ps1 -ApproveNetwork`를 실행한다. 이 Gate는 해당 Worktree에서 `git fetch origin dev`를 한 번 실행하고 현재 dev 포함 여부를 검증한 뒤 Head 전용 Receipt를 발급한다. canonical checkout과 다른 Feature upstream은 참조하거나 변경하지 않는다. Managed `pre-push` Hook은 유효한 Receipt가 있을 때만 Feature Push를 허용하고 `dev`·`main` 직접 Push를 차단한다.
- 새 작업 시작 Gate에서 canonical checkout이 `dev`가 아니거나 Dirty면 해당 변경을 건드리지 않고 Master가 만든 임시 detached Pull Worktree를 사용한다. PR Gate는 임시 Worktree를 만들지 않는다. Feature Worktree가 Dirty하거나 최신 `origin/dev`를 포함하지 않으면 기존 상태를 보존하고 자동 Merge·Rebase·충돌 해결 없이 `MASTER CONTEXT BLOCKED`로 중단한다.
- 주입된 `AGENTS.md`와 이번 작업의 활성 Source Worktree 변경 범위를 기준으로 `full` 전체 실행,
  Frontend Watch·HMR, 단일 Service 격리 갱신 중 적용 모드를 LLM이 판단하고 `LOCAL RUNTIME CONTEXT PASS`로 보고한다.
- 변경 범위는 staged·unstaged·untracked 파일과 `origin/dev`에 아직 없는 현재 Work ID Commit을 함께 본다.
  Frontend-only Live 허용 변경이면 HMR을 쓰지만, Frontend와 Backend·Orchestrator·MCP Server 변경이 함께 있거나
  Frontend의 Package·Lockfile·Dockerfile·Vite·Nginx 설정 변경이 있으면 `full` 전체 재빌드·재기동을 사용한다.
- 자연어는 LLM이 이 근거로 판단하고 Script에는 확정된 `Profile`, `Service`, 활성 `SourceRoot`만 넘긴다.
  대상을 특정할 수 없거나 안전한 실행 결과가 달라지는 모호함이 남으면 추측하지 않고 한 번 질문한다.
- 실행 직전 `LOCAL RUNTIME CONTEXT PASS: mode=<full|frontend-live|isolated>; sources=<활성 Source>; reason=<판단 근거>`를 보고한다.
- 신규 Workspace 설정이나 수동 Master 갱신처럼 표준 최신화를 거치지 않았을 때만 활성 LLM이
  `urizo-final-master/scripts/bootstrap-workspace.ps1 -SyncLlmHooks`를 직접 실행한다.
- 두 도구는 같은 Master 원문 로더를 사용하며 실패 시 자동 재시도 없이 `continue: false`와 `MASTER CONTEXT BLOCKED`로 해당 턴을 종료한다. Codex 최초 신뢰 확인은 팀원이 한 번 승인한다.
- `CMS 로컬 실행`, `CMS만 띄워줘`는 `urizo-final-master/scripts/start-local-cms.ps1 -Profile spring-core -ApproveLocalMutation`,
  `시스템 띄워줘`, `전체 재기동`, `로컬 재기동`은 같은 Script의 `-Profile full`로 처리한다. 여러 Source 또는 비-Live 변경 반영은
  `-Rebuild -ApproveNetwork`를 추가하며 `full`에는 MCP Server를 포함한다. 직전 전체 동기화에서 Source가 하나라도 갱신됐거나
  전체·로컬 재기동을 명시한 경우도 `-Rebuild -ApproveNetwork`와 네 활성 SourceRoot로 전체 Image와 Container를 갱신한다.
  단일 Service 격리 변경은 `urizo-final-master/scripts/rebuild-local-service.ps1 -Service <spring-app|frontend|coding-runtime|mcp-server> -Profile <spring-core|full> -SourceRoot <활성 Service Worktree>`로
  허용 Service만 갱신하고 해당 Profile 전체 Health를 확인한다.
- 같은 Work ID의 같은 저장소·PR은 하나의 Worktree를 끝까지 재사용한다. 후보 SHA 고정 전에는 단위·계약·정적 검증을 우선하고
  코드 수정마다 `full` 재빌드나 Flyway를 반복하지 않는다.
- 후보 SHA 조합의 `full`·Flyway 통합 검증은 기본 1회, 현재 범위의 Source 결함 수정 후 재검증 1회까지만 허용한다.
  같은 Work ID에서 세 번째 실행은 팀장 승인이 필요하며, 범위 밖 blocker 또는 같은 원인 2회 실패는 추가 보완 없이
  `PARTIAL`·`NOT VERIFIED`와 재현 명령으로 종료한다.
- 병렬 Worktree는 Source 구현·단위 테스트에 사용하고 공유 DB·Volume의 `full`·Flyway는 한 번에 하나만 직렬 실행한다.
  Flyway는 Migration·Schema 변경 또는 공식 `full` 흐름에 필요할 때만 실행하며 Repair/Clean, DB 초기화, Volume 삭제로 우회하지 않는다.
- 동기화는 자동 Branch 전환, Rebase, 충돌 해결, Reset, Stash Pop, 로컬 변경 삭제를 하지 않는다.
- Master 공통 기준과 공통 문서는 Min Seungjun(`tmdwns0531`)만 수정한다. 단, 팀원별 LLM은
  `urizo-final-master/docs/team/FLYWAY_RESERVATION_LEDGER.md`에 자기 작업 예약 행을 추가하고 상태를 갱신할 수 있다.
  AI 핵심 기능 담당자는 `urizo-final-master/docs/product/ai-core/`에서 자신에게 배정된 상세 문서만 Feature Branch와 `dev` 대상 PR로 수정한다.
- 2~6번 작업에서는 현재 PC GitHub ID와 담당자 표를 대조해 공통 문서와 배정된 상세 문서를 읽고
  `AI FEATURE CONTEXT PASS`를 보고한다. 새 작업의 Work ID·work slug는 작업 시작 전에 한 번 제안한다.
- 조사·분석과 기능 MD 수정만이면 Worktree를 만들지 않는다. 실제 Source 구현은 Work ID 승인 후 저장소별
  최신 `origin/dev` 기반 독립 Worktree에서 시작한다. 같은 PR은 재사용하고 다음 독립 PR은 새 Work ID와 Worktree를 쓴다.
- Work ID는 작업 시작부터 PR 생성까지며 같은 PR의 작업을 묶는다. PR 생성 시 문서 연결을 한 번 제안하고,
  기록된 PR은 담당 LLM이 GitHub와 `origin/dev`를 확인해 현행화한다. Context Hook은 GitHub·Ledger를 스캔하지 않으며 상세 규칙은 Master 운영 정책을 따른다.
- Every agent-created PR in Master, Frontend, Backend, Orchestrator, and MCP Server targets `dev`.
- GitHub Ruleset에서 Min Seungjun(`tmdwns0531`)은 `dev` 대상 PR의 직접 병합 예외 Actor다. 병합이 명시적으로 승인됐고
  Base·Head SHA·Mergeable을 확인했으며 일반 Merge가 필수 리뷰로만 막히면 `gh pr merge --merge --admin`을 사용할 수 있다.
  이 예외는 직접 Push, 자동 Merge, `main` 대상 PR, Force Push 또는 다른 계정의 우회를 허용하지 않는다.
- 현재 Work ID의 PR이 `dev`에 병합됐음을 GitHub와 `origin/dev`에서 확인하면 해당 원격 Head Branch와 로컬 Branch를 제거하고,
  연결된 Worktree가 깨끗하면 함께 제거한다. 열린 PR, 미병합 Branch, 병합 후 추가 Commit, Dirty·Diverged·local-only 작업은 보존하고 보고한다.
- `main` is reserved for periodic manual promotion by Min Seungjun.
- Git이 구현 상태의 기준이다.
- Notion은 Min Seungjun이 현재 요청에서 명시적으로 지시한 경우에만 쓴다.

## 팀장 세션 프로토콜

- 사용자 메시지의 첫 유효 토큰이 정확히 `@팀장`이면 인용·설명인지 구분한 뒤 팀장 전환 승인을 한 번 요청한다.
- 승인 후 발견 가능한 `axms-team-lead` Skill을 사용하고, 없으면 `urizo-final-master/docs/team/TEAM_LEAD_PROTOCOL_v0.1.md`를 읽는다. 일반 세션은 상세 프로토콜을 로드하지 않는다.
- 구조 확인은 영향받는 2~6번 개인 MD만 대상으로 하며 기본값은 `STRUCTURE PASS`다. 다른 담당자의 문서는 수정하지 않는다.
<!-- AXMS-MANAGED-LOCAL-LLM-POLICY:END -->

## 작업·안전

- 새 작업은 깨끗한 최신 `dev` 기반 Feature Branch나 별도 Worktree에서 시작한다.
- Dirty, Diverged, local-only 작업을 자동 Reset, Clean, Stash, Checkout, Rebase하지 않는다.
- DB, Docker Volume, Secret, 실행 중 Container를 보존한다.
- Secret을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다.
- Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행한다.
- `dev/main` 직접 Push, `main` 대상 PR, Force Push, 자동 Merge를 금지한다.
- 공개 계약, Flyway Schema, App Shell/Router, 공통 Auth/Error, Compose/Bootstrap은 현재 `dev`와 의존 작업의 충돌을 먼저 확인한다.
- DB 변경은 LLM이 Flyway Ledger와 Backend Migration 파일명을 확인한 뒤 UTC `yyyyMMddHHmmssSSS` Revision을
  중복 없이 생성하고 자기 작업을 즉시 `RESERVED`로 기록한다. 예약 자체에는 별도 사람 승인이 필요하지 않다.
  기존 예약은 재사용하고 빈 DB·기존 DB·반복 실행·Runtime DDL 거부를 확인한다.
- 요청받지 않은 Push, PR, Merge, Notion 쓰기, 배포는 하지 않는다.
