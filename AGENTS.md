# AX Module Studio Master Repository Rules

## 저장소 경계와 소유권

- 상위 `AX-Module-Studio-Workspace`는 Git 저장소가 아니다.
- Master, Frontend, Backend, Orchestrator, MCP Server는 각각 독립 저장소다.
- Master는 현재 제품 범위, 공통 Git·팀 정책, 상태 Snapshot, Workspace 도구만 소유하며 제품 Source를 보관하지 않는다.
- Frontend는 React UI, Backend는 Spring API·공개 계약·Flyway·Compose, Orchestrator는 Python LangGraph Coding Runtime,
  MCP Server는 MCP Service·Endpoint·Catalog와 `common` 실행 경계를 소유한다.
- 여러 저장소를 변경하면 같은 Work ID/work slug를 사용하되 Commit과 PR은 저장소별로 분리한다.
- Master 공통 기준과 공통 문서는 Min Seungjun(`tmdwns0531`)만 수정한다. 팀원은
  `docs/team/FLYWAY_RESERVATION_LEDGER.md`의 자기 작업 예약 행만 자율 갱신할 수 있고, AI 핵심 기능 담당자는 배정된 상세 문서만 수정한다.

## 항상 적용하는 규칙

- `Simple is best`를 따른다. 현재 Spec과 승인된 최소 완료 결과에 필요한 것만 만든다.
- 범위를 넘는 기능·리팩터링·추상화·설정·문서·Slice는 변경 전에 `필요 이유 / 가장 작은 대안 / 영향`을 제시하고 승인을 받는다.
- Git이 구현 상태의 기준이다. 문서·인수인계·PR 존재만으로 완료를 추정하지 않는다.
- Branch, HEAD, Dirty·Diverged·local-only 작업, DB, Docker Volume, Secret, 실행 중인 Container를 보존한다.
- 자동 Reset, Clean, Stash, Checkout, Rebase, 충돌 해결, DB 초기화, Flyway Repair/Clean, Volume 삭제를 금지한다.
- Secret 값을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다.
- Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행한다.
- Notion 쓰기, Git Push, PR 생성·Merge, 배포는 각각 현재 요청에서 승인된 경우에만 수행한다.
- 필수 컨텍스트가 없거나 서로 충돌하면 추측하지 않고 `MASTER CONTEXT BLOCKED`로 중단한다.

## 작업별 컨텍스트 Gate

Markdown 링크는 문서 본문을 자동으로 불러오지 않는다. 작업을 분류한 뒤 아래 명령으로 필요한 문서를 실제 출력하고,
모든 `chunk=1/N`부터 `chunk=N/N`까지 순서대로 읽는다.

```powershell
./scripts/load-task-context.ps1 -Profile <Profile>[,<Profile>...]
```

- Profile 값은 `Product|Git|Runtime|Database|AiFeature|TeamLead|Master` 중에서 고른다.
- `AiFeature`는 `-FeatureNumber <2|3|4|5|6>`을 함께 사용한다.
- `Database`는 활성 Backend checkout·Worktree의 절대 경로를 `-BackendSourceRoot <path>`로 명시한다.
  Loader는 고정된 `docs/DATABASE_MIGRATION_POLICY_v0.2.md`만 읽으며 누락·불일치하면 차단한다.
- 여러 조건에 해당하면 필요한 Profile을 입력 순서대로 한 번 호출한다. Loader는 각 Profile의 문서 순서를 보존하고
  같은 정규화 경로는 첫 등장 한 번만 출력한다. 단일 Profile 호출은 그대로 지원한다.
- 두 번째 이후 Chunk는 같은 Profile 목록과 첫 Receipt의 `bundleSha256`, 직전 Receipt의 `chunkSha256`을 각각
  `-ExpectedBundleSha256`, `-PreviousChunkSha256`으로 전달한다. 누락·불일치하면 문서 변경 또는 순서 위반으로 차단한다.
- 마지막 Chunk의 `complete=true`까지 확인하기 전에는 해당 작업의 수정·실행·Git 변경을 시작하지 않는다.
- 파일 누락, 읽기 실패, Chunk 누락, 안전 한도 초과는 `TASK CONTEXT BLOCKED`이며 작업을 중단한다.
- 모든 필수 Chunk와 적용 저장소의 `AGENTS.md`를 읽은 뒤에만 `TASK CONTEXT PASS`와 `MASTER CONTEXT PASS`를 보고한다.

| 작업 Trigger | 필수 Profile | 추가 확인 |
|---|---|---|
| 제품 범위 판단 또는 Source 구현 | `Product`, `Git` | 변경할 Source의 `AGENTS.md` |
| 전체 동기화, Branch, Worktree, Commit, Push, PR, Merge | `Git` | 현재 Git 상태와 승인 범위 |
| Master 정책·Hook·Workspace 도구 변경 | `Master`, `Git` | Master 소유자와 최신 `origin/dev` |
| 로컬 실행, Docker, Compose, Service 재빌드 | `Runtime` | 실제 변경 Source와 활성 Worktree |
| DB, Schema, Flyway | `Database`, `Git` | `BackendSourceRoot`, Backend Migration과 예약 Ledger |
| 로컬 `full`에서 Flyway 실행 | `Runtime`, `Database`, `Git` | 세 Profile 모두와 활성 Backend Source |
| AI 2~6 기획·설계·구현·구조 변경 | `AiFeature`, `Git` | 담당자, 배정 문서, Work ID |
| 첫 유효 토큰이 정확히 `@팀장`인 세션 | 승인 후 `TeamLead` | `axms-team-lead` Skill |

Profile별 문서와 Chunk/Receipt 계약은
`docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md`가 소유한다.

## 제품과 범위

- 현재 제품 범위는 `Product` Profile이 불러오는 CMS 최소 범위 문서가 소유한다.
- 문서에 없는 화면·기능·역할·상태·워크플로·외부 연동을 추가하지 않는다.
- 삭제된 과거 Spec, Wave, 추적표, 업무분장, 인수인계 내용을 추측하거나 복원하지 않는다.
- 현재 범위 안의 일반 설계·검증·테스트는 별도 승인 없이 진행할 수 있다. 사용자 기능 범위가 달라질 때 승인받는다.

## 작업 시작과 Git

- 작업 저장소, 최소 완료 결과, 담당자와 Work ID/work slug를 확인한다. 불명확하거나 충돌하면 구현하지 않는다.
- 공개 계약, API, Schema, App Shell, Compose처럼 여러 작업에 영향을 주는 변경은 현재 `origin/dev`와 진행 중인 의존 작업의 충돌 여부를 먼저 확인한다.
- 새 구현은 `scripts/start-feature-work.ps1 -RepositoryName <repo> -BranchName <feature/...> -ApproveNetwork`로 시작한다.
  이 Gate는 최신 `origin/dev` 기반 독립 Worktree를 만들고 Dirty canonical을 그대로 보존한다.
- `전체 Git 최신화`, `워크스페이스 최신화`는 `scripts/sync-workspace.ps1 -ApproveNetwork`를 사용한다.
  Master부터 네 Source까지 확인하며 한 저장소의 Dirty·차단 때문에 관계없는 깨끗한 Source 확인을 중단하지 않는다.
- 모든 canonical이 안전할 때만 전체 동기화가 `scripts/bootstrap-workspace.ps1 -SyncLlmHooks`로 공용 Hook을 갱신한다.
  Dirty·차단 canonical이 있으면 기존 Hook을 보존하고 다음 안전한 동기화까지 갱신을 미룬다.
- Push·PR 직전에는 Commit된 깨끗한 Feature Worktree에서 `scripts/prepare-dev-pr.ps1 -ApproveNetwork`를 실행한다.
  최신 `origin/dev` 포함 여부와 Head 전용 Receipt가 일치하지 않으면 Managed `pre-push`가 Push를 차단한다.
- Every agent-created pull request in Master, Frontend, Backend, Orchestrator, and MCP Server targets `dev`.
- `dev`와 `main` 직접 Push, Force Push, 자동 Merge, `main` 대상 PR을 금지한다.
- `main` is the team lead's periodic manual promotion branch.
- 열린 PR, 미병합 Branch, 병합 후 추가 Commit, Dirty Worktree를 자동 삭제하지 않는다.
- 문서 변경은 Commit, Push, PR, Merge를 자동으로 승인하지 않는다.

## AI 핵심 기능 작업

- AI 2~6 작업은 `AiFeature` Profile과 배정된 기능 문서를 읽고 GitHub ID·담당 범위를 확인한 뒤
  `AI FEATURE CONTEXT PASS`를 보고한다. 담당자가 아니면 해당 기능 문서를 수정하지 않는다.
- 실제 Source 구현은 Work ID 승인 후 최신 `origin/dev` 기반 독립 Worktree에서 시작한다.
- 같은 Work ID의 같은 저장소·PR은 같은 Worktree를 재사용하고, 독립된 다음 PR은 새 Work ID를 사용한다.
- 조사·분석과 기능 MD 수정만이면 Source Worktree를 만들지 않는다.
- 채번·기록·완료 판단은 `Git` Profile의 운영 정책만 따른다. Hook은 GitHub·Ledger를 자동 스캔하거나 수정하지 않는다.

## 로컬 실행

- 실행 전 `Runtime` Profile을 읽고 실제 변경 범위로 `full`, `frontend-live`, `isolated` 중 하나를 선택해
  `LOCAL RUNTIME CONTEXT PASS: mode=<full|frontend-live|isolated>; sources=<활성 Source>; reason=<근거>`를 보고한다.
- `CMS 로컬 실행`은 `scripts/start-local-cms.ps1 -Profile spring-core -ApproveLocalMutation`, 전체 재기동은
  같은 Script의 `-Profile full`을 사용한다. 여러 Source 또는 비-Live 변경 반영은 `-Rebuild -ApproveNetwork`를 추가한다.
- Frontend-only Live 허용 변경은 `scripts/start-frontend-live.ps1`, 건강한 Profile의 단일 Service 격리 변경은
  `scripts/rebuild-local-service.ps1 -Service <spring-app|frontend|coding-runtime|mcp-server> -Profile <spring-core|full> -SourceRoot <활성 Service Worktree>`를 사용한다.
- DB·Flyway·Compose·Network·Secret 영향 또는 여러 Source 변경은 부분 갱신하지 않는다.
- 같은 후보 SHA 조합의 `full`·Flyway 통합 검증은 기본 1회, 현재 범위 Source 수정 후 재검증 1회까지만 허용한다.
  세 번째 실행은 팀장 승인이 필요하다.

## 팀장 세션 프로토콜

- 사용자 메시지의 첫 유효 토큰이 정확히 `@팀장`이면 인용·설명인지 구분한 뒤 전환 승인을 한 번 요청한다.
- 승인 후 `axms-team-lead` Skill과 `TeamLead` Profile을 사용한다. 일반 세션은 상세 프로토콜을 읽지 않는다.
  승인 후 `axms-team-lead` Skill의 경로 우선순위로 선택되는 원문과 동일한 프로토콜을 `TeamLead` Profile의 모든 Chunk로 끝까지 읽은 경우에만, Skill이 요구하는 해당 원문 직접 읽기를 충족한다.
- 구조 확인은 영향받는 AI 2~6 개인 MD만 대상으로 하며 다른 담당자의 문서는 수정하지 않는다.

## 응답

- 단순 질문은 바로 답한다. 변경·조사 결과는 `상태 / 결과 / 변경 / 검증 / 남은 사항 / 승인` 순서로 짧게 보고한다.
- 기능 claim은 실행한 테스트, 코드로 확인한 경계, 미검증 항목을 구분한다.
- 완료 직전에 Git 상태를 다시 확인하고 범위 밖 변경을 숨기지 않는다.
