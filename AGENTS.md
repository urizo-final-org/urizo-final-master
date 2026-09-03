# AX Module Studio Master Repository Rules

## 저장소 경계

- Master는 공통 기준·상태·Workspace 도구만 소유하며 제품 Source를 보관하지 않는다.
- 상위 `AX-Module-Studio-Workspace`는 Git 저장소가 아니다.
- Frontend, Backend, Orchestrator, MCP Server는 각각 독립 저장소다.
- 여러 저장소를 변경하면 같은 Slice ID/work slug를 사용하되 Commit과 PR은 저장소별로 분리한다.

## 필수 읽기

작업 전 필요한 문서만 읽는다.

1. `docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md`
2. `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`
3. `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`
4. 작업 저장소의 `AGENTS.md`
5. 2~6번 후속 기능의 기획·설계·구조·구현 작업 시
   `docs/product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md`와 배정된 기능 상세 문서
6. DB 변경 시 `docs/team/FLYWAY_RESERVATION_LEDGER.md`
7. 로컬 환경 작업 시 해당 Workspace·Infrastructure 문서

삭제된 과거 CMS Spec, Wave, 추적표, 업무분장, 인수인계 내용을 추측하거나 복원하지 않는다.

## 현재 제품 범위

현재 목표는 학원 발표용 로컬 CMS MVP다. 구현 범위는
`AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md`만 따른다.

- 문서에 포함된 기능의 일반적인 설계·검증·테스트는 별도 승인 없이 진행한다.
- 문서에 없는 화면·기능·역할·상태·워크플로·외부 연동을 추가하지 않는다.
- 실운영 대비, 미래 확장성, 감사·승인·버전 관리 등을 이유로 범위를 선행 확장하지 않는다.
- 범위를 벗어날 필요가 생기면 작업을 멈추고 팀장에게 승인 요청한다.
- 세부 구현 하나하나는 승인 대상이 아니다. 사용자 기능 범위가 달라질 때만 승인받는다.

## 단순성·범위·응답 원칙

- `Simple is best`를 기본 원칙으로 삼는다. 현재 Spec과 할당된 최소 완료 결과에 필요한 것만 만든다.
- 필요 범위를 넘는 구현·리팩터링·추상화·설정·워크플로·문서·Slice 세분화는 승인 전 절대 진행하지 않는다.
- Master 문서는 현재 결정·범위·검증에 필요한 내용만 남기고 반복 설명·개인별 이력·미확정 계획을 덜어낸다.
- 테스트와 문서는 변경 위험과 시연 범위에 비례해 최소 충분 수준으로 작성한다.
- 불가피하게 범위를 늘려야 하면 변경 전에 멈추고 `필요 이유 / 가장 작은 대안 / 영향`을 짧게 적어 팀장 승인을 요청한다.
- Codex와 Claude는 같은 기준을 사용한다. 결과를 먼저 말하고 사람이 이해하기 쉬운 짧은 문장으로 답한다.
- 단순 질문은 형식을 강제하지 않고 바로 답한다.
- 코드·문서 변경이나 조사 완료 보고는 아래 공통 형식을 짧고 명료하게 사용한다.

```text
상태: 완료 | 진행 중 | 차단

결과:
<완료한 결과 또는 판단 1~3줄>

변경:
- 변경 파일: 없음 | <주요 파일>
- 범위 밖 변경: 없음 | <내용과 이유>

검증:
- 방법: <테스트·실행·문서/코드 대조 방법>
- 결과: <통과·실패와 핵심 수치>
- 미검증: 없음 | <미검증 항목과 이유>

남은 사항:
없음 | <남은 작업 또는 사람의 결정>

승인: 없음 | <필요한 승인과 이유>
```

## 작업 시작

- 최신 Master Spec과 Snapshot, 적용 저장소 규칙을 확인한다.
- 팀장이 지정한 저장소와 최소 완료 결과, 명시적으로 지정한 담당자·Slice ID를 확인한다.
- GitHub ID를 따로 지정하지 않았으면 현재 PC의 `gh auth status` 설정 계정을 사용하고,
  조직 멤버 전체 목록은 조회하지 않는다.
- Slice ID/work slug를 따로 지정하지 않았고 최소 완료 결과가 명확하면
  `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`에 따라 work slug를 자동 생성한다.
- 명시된 담당자·GitHub ID·work slug가 있으면 자동값보다 우선한다. 현재 PC의 GitHub ID를
  확인할 수 없거나 작업 범위가 불명확하면 `MASTER CONTEXT BLOCKED`를 보고한다.
- 일치하면 `MASTER CONTEXT PASS`와 인식한 범위를 짧게 보고한다.
- 변경 저장소·최소 완료 결과가 없거나 범위가 충돌하면 `MASTER CONTEXT BLOCKED`를 보고하고 구현하지 않는다.
- `scripts/sync-workspace.ps1 -ApproveNetwork`는 Master와 Source를 저장소별로 끝까지 확인한다. Dirty canonical은 `PRESERVED`로 보고 Working Tree를 갱신하지 않으며 관계없는 깨끗한 Source 동기화는 계속한다.
- 모든 canonical이 Hook 갱신에 안전할 때만 `scripts/bootstrap-workspace.ps1 -SyncLlmHooks`로 Codex·Claude Hook과 Git Pull Gate를 갱신한다. Dirty·차단 canonical이 있으면 공용 Hook과 현재 컨텍스트 갱신만 보류하고, AGENTS 지문 기반 Full·Checkpoint 갱신은 다음 안전한 동기화에서 수행한다.
- 신규 Workspace 설정이나 표준 동기화 스크립트를 거치지 않은 수동 Master 갱신 후에는 활성 LLM이 구현 전에
  `scripts/bootstrap-workspace.ps1 -SyncLlmHooks`를 실행하고 `CONTEXT AND PULL GATE SETUP PASS` 또는 `MASTER CONTEXT BLOCKED`를 보고한다.
- Codex와 Claude Hook은 같은 AGENTS 로더를 사용한다. `startup|clear|compact`는 Master와 활성 Source 원문을 불러오고, `resume`과 일반 Pull은 짧은 Checkpoint만 불러온다. Pull 결과에 `AGENTS.md` 변경이 있을 때만 전체 원문을 한 번 갱신한다. 원문을 불러오지 못하면 자동 재시도 없이 `continue: false`와 `MASTER CONTEXT BLOCKED`로 해당 턴을 종료한다.
- Codex가 프로젝트 Hook 신뢰 확인을 처음 표시하면 팀원이 내용을 확인하고 한 번 승인한다. 이 제품 보안 확인은 LLM이 우회하지 않는다.
- Source의 dirty·diverged·local-only 작업은 보존한다. 새 작업은 깨끗한 최신 `dev` 기반 Branch나 별도 Worktree에서 시작한다.
- 새 구현 작업은 `scripts/start-feature-work.ps1 -RepositoryName <repo> -BranchName <feature/...> -ApproveNetwork`로 시작한다. 이 Gate가 깨끗한 canonical `dev`에서 `git pull --ff-only origin dev`를 성공시킨 뒤 갱신된 `origin/dev` 기반 독립 Worktree와 Feature Branch를 생성·재사용한다.
- Push·PR 직전에는 변경을 Commit한 깨끗한 Feature Worktree에서 `scripts/prepare-dev-pr.ps1 -ApproveNetwork`를 실행한다. 이 Gate는 해당 Worktree에서 `git fetch origin dev`를 한 번 실행하고 현재 `origin/dev` 포함 여부를 검증한 뒤 현재 Head 전용 Receipt를 발급한다. canonical checkout과 다른 Feature upstream은 참조하거나 변경하지 않는다. Managed `pre-push` Hook은 Receipt·Head·`origin/dev`가 모두 일치할 때만 Feature Push를 허용하고 `dev`·`main` 직접 Push를 차단한다.
- 새 작업 시작 Gate에서 canonical checkout이 `dev`가 아니거나 Dirty면 해당 변경을 건드리지 않고 Master가 만든 임시 detached Pull Worktree를 사용한다. PR Gate는 임시 Worktree를 만들지 않는다. Feature Worktree가 Dirty하거나 최신 `origin/dev`를 포함하지 않으면 자동 Merge·Rebase·충돌 해결 없이 `MASTER CONTEXT BLOCKED`로 중단한다.

## AI 핵심 기능 작업

- 2~6번 작업은 현재 PC의 GitHub ID를 담당자 표와 대조하고 공통 문서와 배정된 상세 문서를 읽은 뒤
  `AI FEATURE CONTEXT PASS`를 보고한다. 담당자가 아니면 해당 기능 문서를 수정하지 않는다.
- 실제 새 작업에 사용할 Work ID가 없으면 다음 Work ID와 work slug를 한 번 제안하고,
  담당자 동의 후 상세 문서에 작업 목록과 상태를 기록한다.
- 조사·분석과 기능 MD 수정만으로 끝나는 작업은 Worktree를 만들지 않는다. 실제 Source 구현은 Work ID 승인 후
  저장소별 최신 `origin/dev` 기반 독립 Worktree와 해당 Feature Branch에서 시작하며 기존 Worktree를 건드리지 않는다.
  같은 Work ID의 같은 PR 작업은 기존 Worktree를 재사용하고, 독립된 다음 PR은 새 Work ID와 새 Worktree를 사용한다.
- Work ID 하나는 작업 시작부터 PR 생성까지며 같은 PR의 작업을 묶는다. PR 생성 시 문서 연결을 한 번 제안하고,
  기록된 PR은 담당 LLM이 GitHub와 `origin/dev`를 확인해 현행화한다. Context Hook은 GitHub·Ledger를 스캔하지 않고 읽기 전용 Checkpoint만 만든다.
- 상세 채번·기록 규칙은 `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`만 따른다.

## 팀장 세션 프로토콜

- 사용자 메시지의 첫 유효 토큰이 정확히 `@팀장`이면 인용·설명인지 구분한 뒤 팀장 전환 승인을 한 번 요청한다.
- 승인 후 발견 가능한 `axms-team-lead` Skill을 사용하고, 없으면 `docs/team/TEAM_LEAD_PROTOCOL_v0.1.md`를 읽는다. 일반 세션은 상세 프로토콜을 로드하지 않는다.
- 구조 확인은 영향받는 2~6번 개인 MD만 대상으로 하며 기본값은 `STRUCTURE PASS`다. 다른 담당자의 문서는 수정하지 않는다.

## Git Pull과 전체 동기화

`전체 Git 최신화`, `워크스페이스 최신화`처럼 전체 범위를 명시한 요청은
`scripts/sync-workspace.ps1 -ApproveNetwork`를 의미한다. 일반 `git pull`은 요청된 저장소 범위에서 수행할 수 있다.

- Master 먼저, 이어서 Frontend·Backend·Orchestrator·MCP Server를 확인하되 한 저장소의 보존·차단 결과 때문에 관계없는 깨끗한 Source 확인을 중단하지 않는다.
- Dirty canonical은 fetch로 원격 Ref만 갱신하고 `PRESERVED`로 보고하며 Working Tree를 갱신하지 않는다.
- 모든 canonical이 깨끗하고 차단되지 않았을 때만 같은 스크립트가 Workspace AGENTS, Codex·Claude Context Hook, Git pre-push Pull Gate를 자동 동기화한다. Dirty·차단 canonical이 있으면 공용 Hook과 현재 컨텍스트 갱신을 보류 사유와 함께 보고한다.
- 자동 Branch 전환, Rebase, 충돌 해결, Reset, Stash Pop, 로컬 변경 삭제를 하지 않는다.
- Codex·Claude `PostToolUse` Hook은 성공한 일반 `git pull`을 감지하면 4KB 이하 Checkpoint를 주입한다. Pull 결과에 `AGENTS.md` 변경이 나타난 경우에만 Master와 활성 Source 원문을 한 번 주입하며 Workspace AGENTS 원문은 native directory routing과 중복 주입하지 않는다.
- 활성 LLM은 주입된 `AGENTS.md`와 실제 변경 범위를 기준으로 아래 세 실행 모드 중 적용 대상을 판단하고
  `LOCAL RUNTIME CONTEXT PASS`로 보고한다.
  1. 최초 실행·전체 재기동·여러 Source 변경은 `full` 전체 실행 Script
  2. Frontend-only Live 허용 변경은 Watch·HMR
  3. 그 외 단일 Service 격리 변경은 해당 Image와 Container만 갱신한 뒤 실행 Profile 전체 Health 확인
- 실제 변경 범위는 이번 작업에서 사용하는 각 Source Worktree의 staged·unstaged·untracked 파일과
  `origin/dev`에 아직 없는 현재 Work ID Commit을 함께 확인한다. 다른 Work ID의 보존 Worktree는 현재 변경 범위로 세지 않는다.
- `Frontend만 반영`처럼 Frontend를 명시했더라도 Backend·Orchestrator·MCP Server 변경이 함께 있거나,
  Frontend의 `package.json`, Lockfile, Dockerfile, Vite·Nginx 설정처럼 Image Build 대상 변경이 있으면 Watch를 쓰지 않고 `full`로 재빌드한다.
- 자연어 요청은 LLM이 위 근거로 해석하되 실행 Script에는 해석된 `Profile`, `Service`, 활성 `SourceRoot`만 전달한다.
  실행 대상을 특정할 수 없거나 안전한 두 모드의 결과가 달라지는 모호함이 남으면 추측하지 않고 한 번 질문한다.
- 실행 직전 `LOCAL RUNTIME CONTEXT PASS: mode=<full|frontend-live|isolated>; sources=<활성 Source>; reason=<판단 근거>`를 짧게 보고한다.

## CMS 로컬 실행

로컬 실행은 임의 Docker 명령 조합이 아니라 `scripts/start-local-cms.ps1` 한 경로로 처리한다.

- 명시적인 로컬 실행 요청을 받으면 `-ApproveLocalMutation`을 사용한다.
- `CMS 로컬 실행`, `CMS만 띄워줘`는 `-Profile spring-core`를 사용한다.
- `시스템 띄워줘`, `전체 재기동`, `로컬 재기동`은 `-Profile full`을 사용하며 MCP Server도 성공 조건에 포함한다.
- 직전 전체 동기화에서 Source 하나라도 Fast-forward됐거나 `전체 재기동`·`로컬 재기동`을 명시하면
  `-Profile full -Rebuild -ApproveNetwork`로 전체 Image를 재빌드하고 Container를 재생성한다.
- 요청 Profile이 이미 정상이면서 반영할 Source 변경이 없으면 기존 Container를 재사용하고 즉시 종료한다.
- 중지 상태면 기존 Image로만 기동하며, 최초 실행처럼 Image가 없으면 Network 승인 후 `-ApproveNetwork`를 추가한다.
- 여러 Source 변경, 전체 재빌드 요청, DB·Flyway·Compose·Network·Secret 영향 또는 Frontend 비-Live 변경을
  Image에 반영할 때는 `-Profile full -Rebuild -ApproveNetwork`와 이번 작업의
  `-BackendSourceRoot`, `-FrontendSourceRoot`, `-OrchestratorSourceRoot`, `-McpSourceRoot`를 사용한다.
- `spring-core` 실행에서는 Coding Runtime과 MCP Server를 성공 조건으로 삼지 않는다.
- 공통 Script가 정확한 원인으로 차단한 경우에만 해당 원인을 수정한다. 전체 실행 실패를 임의 Docker 명령으로 우회하지 않는다.

이미 건강한 CMS의 격리된 부분 변경은 전체 실행과 구분한다.

- DB·Flyway·Compose·Network·Secret에 영향이 없고 변경 Service가 명확할 때만 해당 Image와 Container를 갱신한다.
- `scripts/rebuild-local-service.ps1 -Service <spring-app|frontend|coding-runtime|mcp-server> -Profile <spring-core|full> -SourceRoot <활성 Service Worktree> -ApproveLocalMutation -ApproveNetwork`를 사용한다.
- `coding-runtime`과 `mcp-server`는 `full`에서만 부분 갱신한다. DB·Flyway·Volume Service는 이 Script의 대상이 아니다.
- 부분 갱신은 이미 건강한 Profile에서만 수행하며 DB·Volume을 변경하지 않고 완료 후 해당 Profile 전체 Health를 확인한다.

### 검증 빈도와 종료 상한

- 같은 Work ID의 같은 저장소·PR은 하나의 Feature Worktree를 끝까지 재사용한다. 같은 PR의 보완·검증 때문에
  새 Branch나 Worktree를 만들지 않으며, 독립 PR 또는 동시에 충돌하는 구현만 별도 Worktree로 분리한다.
- 후보 Source SHA 조합을 고정하기 전에는 변경 범위의 단위·계약·정적 검증을 우선한다. 코드 수정마다
  `full` 재빌드나 Flyway를 반복하지 않는다.
- `full` 재빌드·Flyway 통합 검증은 후보 SHA 조합을 고정한 뒤 한 번 실행한다. 첫 실행이 현재 범위의 Source 결함으로
  실패해 수정 Commit이 생긴 경우에만 한 번 더 실행할 수 있으며, 한 Work ID의 같은 통합 검증에서 총 2회를 넘기지 않는다.
  세 번째 실행은 팀장의 명시적 승인이 필요하다.
- 외부 Service, 선행 Product Job, 기존 공유 Volume·Secret처럼 현재 범위 밖 원인으로 실패하면 환경·제품 범위를
  추가 보완하지 않고 즉시 `PARTIAL` 또는 `NOT VERIFIED`와 재현 명령을 보고한다. 같은 원인으로 두 번 실패하면 세 번째 재시도를 금지한다.
- 여러 Worktree의 Source 구현과 단위 테스트는 병렬로 진행할 수 있지만, 공유 DB·Volume을 사용하는 `full`·Flyway 검증은
  한 번에 하나의 통합 작업만 직렬로 실행한다.
- Flyway는 Migration·Schema 변경 검증 또는 공식 `full` 통합 흐름에 필요한 경우에만 실행한다. 관련 없는 Source 변경의
  중간 검증으로 단독 실행하지 않으며 Flyway Repair/Clean, DB 초기화, Volume 삭제로 통과시키지 않는다.

### Frontend Live 개발

- 사용자가 Frontend-only 반영을 명시하고 이번 작업의 Source 변경이 Frontend Live 허용 파일에만 있을 때,
  건강한 CMS에서 Image 재빌드 대신
  `scripts/start-frontend-live.ps1 -FrontendSourceRoot <활성 Frontend Worktree> -ApproveLocalMutation`을 사용한다.
- 한 번에 하나의 활성 Work ID·Frontend Worktree만 Watch 대상으로 연결한다. Worktree를 바꾸기 전에 기존 Watch를 종료한다.
- Watch는 `src`, `public`, `index.html`만 실행 중인 Frontend Container에 동기화하며 Git·Secret·`node_modules`는 동기화하지 않는다.
- `package.json`, Lockfile, Dockerfile, Vite·Nginx 설정, Backend, DB 또는 공통 환경 변경은 Live 대상이 아니다.
- Watch는 `Ctrl+C`로 종료한 뒤 같은 Script에 `-RestoreImageOnly`를 사용해 Image-only Frontend를 복원한다.
  정상 Shell 종료 시 Script도 복원을 시도하며, `-RestoreImageOnly`는 이미 복원된 상태에서 반복 실행해도 안전하다.
- PR 전에는 Live를 종료하고 실제 Image Build, Frontend 테스트·타입 검사와 전체 Health를 통과한다.

## 소유권

- Frontend: React UI와 브라우저 동작
- Backend: Spring API, 공개 계약, Flyway, Compose, 로컬 실행·검증
- Orchestrator: Python LangGraph Coding Runtime
- MCP Server: 단일 MCP Service·Endpoint·Catalog와 `common` 실행 경계
- Master: 현재 제품 범위, 공통 Git/팀 정책, 상태 Snapshot, Workspace 도구

Master 공통 기준과 공통 문서는 Min Seungjun(`tmdwns0531`)만 수정한다. 단,
`docs/team/FLYWAY_RESERVATION_LEDGER.md`의 자기 작업 예약 행 추가와 상태 갱신은 팀원별 LLM 자율 기록 예외다.
AI 핵심 기능 담당자는 `docs/product/ai-core/`에서 자신에게 배정된 상세 문서만 Feature Branch와 `dev` 대상 PR로 수정할 수 있다.
다른 기능 문서와 다른 사람의 Flyway 예약 행은 읽기 전용으로 사용한다.

## Git 정책

- 개발은 최신 `dev`에서 Feature Branch를 만들어 시작한다.
- Branch, Commit, PR 제목·본문은 `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`의 한글 공통 형식을 사용하고 지정된 Slice ID 또는 work slug와 GitHub ID를 포함한다.
- Every agent-created pull request in Master, Frontend, Backend, Orchestrator, and MCP Server targets `dev`.
- GitHub Ruleset에서 Min Seungjun(`tmdwns0531`)은 `dev` 대상 PR의 직접 병합 예외 Actor다. 현재 요청에서 병합까지
  명시적으로 승인됐고 PR Base가 `dev`, Head SHA가 의도한 Commit, `mergeable=MERGEABLE`이며 일반 Merge가 필수 리뷰 조건으로만
  차단되면 `gh pr merge --merge --admin`으로 이 예외를 적용할 수 있다.
- 이 예외는 `dev`·`main` 직접 Push, 자동 Merge, `main` 대상 PR, Force Push 또는 다른 계정의 Ruleset 우회를 허용하지 않는다.
- 현재 Work ID의 PR이 `dev`에 병합됐음을 GitHub와 `origin/dev`에서 확인하면 해당 PR의 원격 Head Branch와
  로컬 Branch를 제거하고, 연결된 Worktree가 깨끗하면 함께 제거한다. 원격 Branch가 이미 삭제됐으면 Fetch·Prune으로 현행화한다.
- Branch 정리 전 PR Base·병합 상태·Head SHA와 로컬 Dirty·Diverged·local-only Commit을 확인한다.
  열린 PR, 미병합 Branch, 병합 후 추가 Commit, Dirty Worktree는 자동 삭제하지 않고 보존 상태를 보고한다.
- `dev`와 `main`에 직접 Push하지 않는다.
- `main` is the team lead's periodic manual promotion branch.
- `main` 대상 PR, Force Push, 자동 Merge를 금지한다.
- 여러 저장소 변경은 같은 work slug로 저장소별 별도 Commit/PR을 만든다.
- 문서 변경은 Commit, Push, PR, Merge를 자동으로 승인하지 않는다.

## 공통 변경

공개 계약, Flyway Schema, Frontend Router/App Shell, 공통 Auth/Error, Backend Compose·Bootstrap처럼
여러 작업에 영향을 주는 변경은 현재 `dev`와 진행 중인 의존 작업을 기준으로 충돌 여부를 먼저 확인한다.

DB 변경이 필요하다고 판단한 LLM은 SQL 작성 전에 Master Flyway Ledger와 Backend Migration 파일명을 확인하고
현재 UTC의 `yyyyMMddHHmmssSSS` 17자리 Revision을 생성한다. 중복이면 새 시각으로 다시 생성하며,
자기 작업 예약 행을 즉시 `RESERVED`로 기록한다. 이 예약에는 Min Seungjun 또는 Integration/Contract 담당자의
별도 승인이 필요하지 않다. 기존 14자리 Revision과 같은 작업에 이미 예약된 Revision은 그대로 재사용한다.
이후 빈 DB·기존 DB·반복 실행·Runtime DDL 거부를 확인한다.

## Notion

- Notion은 현재 Git 작업의 자동 대상이 아니다.
- Min Seungjun이 현재 요청에서 명시적으로 지시한 경우에만 쓴다.
- Git이 구현 상태의 기준이며 Notion과 다르면 Git을 따른다.
- 팀원은 Notion 연결을 요구받지 않는다.

## 안전

- Branch, HEAD, 로컬 변경, DB, Docker Volume, Secret, 실행 중인 Container를 보존한다.
- 자동 Reset, Clean, Stash, Checkout, Rebase, DB 초기화, Flyway Repair/Clean, Volume 삭제를 금지한다.
- Secret 값을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다.
- Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행한다.
- Notion 쓰기, Git Push, PR 생성·Merge, 배포는 각각 별도 요청이 있을 때만 수행한다.
