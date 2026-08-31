# AI06 구현 작업 임시 원장

> 상태: AI04-002·AI05-001-01 `[제안]` 최소 수직 실행 연결 `dev` 병합 완료
> 작성 기준일: 2026-08-31
> 용도: Work ID별 범위·검증·PR·Merge 결과를 이어 가기 위한 임시 실행 원장
> 종료 처리: 구현 캠페인이 끝나면 확정 결과만 `06_ORCHESTRATION_CONTROL.md`에 반영하고 이 파일은 삭제한다.

## 1. 사용 원칙

- 이 파일은 공통 아키텍처와 기능 상세를 다시 설명하지 않는다. 확정 기준은 공통 AI 문서와 2~6번 기능 상세 문서가 소유한다.
- 한 Work ID는 한 PR 수명이다. 여러 저장소를 함께 바꾸면 같은 Work ID·work slug를 쓰되 저장소별 Commit·PR을 분리하고 서로 연결한다.
- Work ID 내부 작업은 `구현 → 해당 단위 테스트 → 전체 회귀 검증 → Commit → Push → dev 대상 PR → CI 확인 → dev 병합` 순으로 진행한다.
- 승인된 자동 범위에서는 Work ID 내부 병합과 다음 승인된 Work ID 진입을 선조치 후보고할 수 있다.
- Git이 상태의 기준이다. 이 파일에는 진행 상태, 검증 명령·결과, PR URL, dev Merge SHA, 후속 위험만 기록한다.
- 현재 다른 팀원이 작업 중이지 않으므로 충돌 확인은 가볍게 한다. 시작 직전 대상 저장소의 Branch·Working Tree·동일 Work ID Branch/PR 존재 여부만 확인한다.

## 2. 현재 구현 기준

- Orchestrator `dev`는 현행 Coding Graph·Worker 호환 경로를 유지하면서 Job에 고정된 Profile Version Snapshot 실행, 공통 Start·Guardrail·Check·Approval·End Handler와 Checkpoint 승인 재개 경로를 production Registry에 연결했고, 123개 회귀 테스트가 있다.
- 기존 Runtime을 새로 쓰거나 한 번에 교체하지 않는다. Snapshot 경로를 옆에 추가하고 기존 경로를 회귀 기준으로 유지한 뒤 단계적으로 연결한다.
- Backend 기본 Checkout은 깨끗하지만 최신 `origin/dev`보다 뒤에 있으므로 구현·검증은 기존 Checkout을 건드리지 않고 최신 `origin/dev` 기반 독립 Worktree에서 진행한다.
- 4·5번은 Job·도메인 상태·결과 표시와 기능별 Handler/Tool 로직을 소유한다. 6번은 Snapshot Runner·Graph Builder·Registry·공통 Runtime과 공통 Handler/MCP 계약을 소유한다.
- PostgreSQL이 Job 상태의 기준이고 Valkey에는 `jobId`만 전달한다. 다음 Node 선택은 Versioned Snapshot의 Edge를 해석하는 Runner가 담당한다.
- Frontend AI06-002 PR [#12](https://github.com/urizo-final-org/urizo-final-frontend/pull/12)는 `dev`에 병합됐으며 Merge SHA는 `2f1113140bb68d4e41d90484f0bce5315913f958`이다.
- Frontend AI06-003 PR [#13](https://github.com/urizo-final-org/urizo-final-frontend/pull/13)는 `dev`에 병합됐으며 Head SHA는 `b481573b9edaee353e56de5764ccd19438228bbc`, Merge SHA는 `673974bca136b5bad1b6deb7f0a4a72684f73251`이다.
- Orchestrator AI06-004 PR [#5](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/5)는 69개 전체 테스트와 28개 Python 파일 문법 검사를 통과해 `dev`에 병합됐으며 Head SHA는 `d487adc20e4fb10d416a4bef1746e04e59ed3684`, Merge SHA는 `55e1d83416e7aa8893f180f053498a5b668e9586`이다.
- Orchestrator AI06-005 PR [#6](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/6)는 집중 16개·전체 85개 테스트와 32개 Python 파일 문법 검사를 통과해 `dev`에 병합됐으며 Head SHA는 `dd706b9623c7c7290dccd1c9b84936f454960185`, Merge SHA는 `c35e292e950c4992e70a2fba36188e9041b3be0a`이다.
- Orchestrator AI06-006 PR [#7](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/7)은 Snapshot Runner 집중 10개·WorkerLoop 집중 5개·전체 96개 테스트와 34개 Python 파일 문법 검사를 통과해 `dev`에 병합됐으며 Head SHA는 `1faae3b96fa4c95b2be2ca0c049b54ec09e837ed`, Merge SHA는 `8c139060a0a3709a32ea6d18464382d9f7d6485f`이다. GitHub Status Check는 없었고, 관리자 권한을 재확인한 뒤 self-review Ruleset만 이 PR에 한해 우회했으며 Ruleset은 변경하지 않았다.
- Backend AI06-007 PR [#15](https://github.com/urizo-final-org/urizo-final-backend/pull/15)는 Profile 집중 15개, 계약 Fixture 107 valid·50 invalid, Flyway empty-head·직전 Revision upgrade·repeat, Product 118개·Control 114개 테스트와 두 JAR Build를 통과해 `dev`에 병합됐으며 Head SHA는 `64714e064517dffe37c277832eac917f31e6df6d`, Merge SHA는 `3c59ab10e433ed097ffd884fc08fffda9b9afb5e`이다.
- Orchestrator AI06-007 PR [#8](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/8)은 집중 21개·전체 107개 테스트, 38개 Python 파일 문법 검사, frozen-lock production Image Build와 non-root 실행 검증을 통과해 `dev`에 병합됐으며 Head SHA는 `e3ebaed3b3cb9476f456feb60a917c5e87be2d4e`, Merge SHA는 `29a7ae5f123b57717f2d383e8123a5e0cc89bac8`이다. 두 PR 모두 GitHub Status Check는 없었고, 관리자 권한을 재확인한 뒤 self-review Ruleset만 해당 PR에 한해 우회했으며 Ruleset은 변경하지 않았다.
- Frontend AI06-012 PR [#14](https://github.com/urizo-final-org/urizo-final-frontend/pull/14)는 Runtime과 맞지 않던 AI 운영 목업을 간소화한 뒤 `dev`에 병합됐으며 Head SHA는 `accf65dc96fed707c8476bd4f5833b982079b03d`, Merge SHA는 `9ec93aef012e653aae9f62e5c8e4b988d2495d92`이다.
- Backend AI06-013 PR [#17](https://github.com/urizo-final-org/urizo-final-backend/pull/17)은 Profile Version Repository의 Spring Proxy 시작 문제를 수정한 뒤 `dev`에 병합됐으며 Head SHA는 `f89d440823c5bde9d1e0f3387635d119e5c1f721`, Merge SHA는 `bc741c5256d896b8c49ed1d443c989879bbe2eeb`이다.
- Backend AI04-001 Runner PR [#18](https://github.com/urizo-final-org/urizo-final-backend/pull/18)은 Head SHA `2ce33fa55976a5ccac15f06f944e14ae2ed140b6`, Merge SHA `55b382c889d4bbe39a0ecd8b80d2bd4e51c77c53`으로 `dev`에 병합됐다.
- Backend AI06-009 PR [#19](https://github.com/urizo-final-org/urizo-final-backend/pull/19)은 Head SHA `a6c8dcfd1461597d721ac19d2f7936906df6d935`, Merge SHA `9f0b529e4e0d702b7d30c95db3e48d838097e531`으로 `dev`에 병합됐다. Merge Commit의 첫 Parent는 #18 Merge SHA라 Flyway 순서를 보존한다.
- Orchestrator AI06-009 PR [#10](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/10)은 Head SHA `2f34b7e1185b9466822aef9e835ec6a1d71683e4`, Merge SHA `8ffdace39ed91309f67759f65238ce50f3a5f324`로 `dev`에 병합됐다.
- MCP Server AI06-010 PR [#1](https://github.com/urizo-final-org/urizo-final-mcp-server/pull/1)은 Head SHA `8a91fd3416c80f5d46072700abb6f23ce877481d`, Merge SHA `e6595aeaeda5a98512004ee3252cc1b02067feec`으로 `dev`에 병합됐다.
- Backend AI06-010 PR [#21](https://github.com/urizo-final-org/urizo-final-backend/pull/21)은 Head SHA `b64c9e6d595a556113ece3a7988d0df057ee048d`, Merge SHA `e736f7e8a4c87718bb0659b38591ed3c5fed1c3e`으로 `dev`에 병합됐다. 두 PR 모두 관리자 개별 bypass만 사용했고 Ruleset은 변경하지 않았다.
- Master AI06-010 PR [#22](https://github.com/urizo-final-org/urizo-final-master/pull/22)는 Head SHA `5a77955e21c62caf2be30896636d4b6c4ec42ab3`, Merge SHA `8ba1714912a9d0d8da6b87b760ddbb4495913a63`으로 `dev`에 병합됐다.

## 3. 제안 Work ID

| 순서 | Work ID / work slug | 저장소 | 최소 구현 범위 | 완료·회귀 기준 | 진입 정책 | 상태 |
|---:|---|---|---|---|---|---|
| UI | `AI06-003` / `axms-ai06-003-natural-profile-management-mock` | Frontend | Agent 설정의 `자연어 기능 Profile` Tab, 시스템 설정의 `CMS 기본 설정`·중앙 `Guardrail Profile` 2개 Tab, 별도 사이트 관리 화면을 최고관리자 전용 로컬 목업으로 만든다. 저장 API와 Runtime은 연결하지 않는다. | Route·Tab·권한·로컬 상호작용 테스트 통과, 기존 Frontend 회귀 통과 | 엔진과 독립된 UI 트랙. AI06-002 `dev` 병합 후 최신 `origin/dev` 기반 새 Worktree에서 우선 진행 | `dev` 병합 완료 · PR #13 |
| 1 | `AI06-004` / `axms-ai06-004-snapshot-contract` | Orchestrator | Versioned Snapshot의 `nodes`·`edges`·`config`·`handlerKey`·Result Port를 표현하는 불변 모델, JSON Loader·Validator, 테스트 Fixture를 추가한다. 현행 Graph 실행 경로는 바꾸지 않는다. | 정상/오류 JSON 계약 테스트 통과, 기존 52개 전체 회귀 통과 | 자동 진행 가능 | `dev` 병합 완료 · PR #5 |
| 2 | `AI06-005` / `axms-ai06-005-registry-graph-builder` | Orchestrator | Node Registry와 공통 Invocation/Result 계약, Snapshot 기반 `add_node`·`add_edge`·조건부 Edge·`compile()` Builder를 추가한다. 테스트 Handler만 사용한다. | 선형·분기·반복·미등록 Handler·잘못된 Port 테스트, 전체 회귀 통과 | `AI06-004` dev 병합 후 자동 진입 가능 | `dev` 병합 완료 · PR #6 |
| 3 | `AI06-006` / `axms-ai06-006-snapshot-runner-compat` | Orchestrator | 기존 `CodingGraphRunner`와 WorkerLoop에 Snapshot Provider/Runner 호환 경로를 연결한다. `jobId == thread_id`, Checkpoint, 멱등성, 승인 중단·재개를 보존하고 현행 Graph는 호환 Adapter로 유지한다. | 기존 Coding 흐름과 Snapshot 흐름의 동일 Job 중복 억제·재시도·중단/재개 테스트, 전체 회귀 통과 | `AI06-005` dev 병합 후 자동 진입 가능 | `dev` 병합 완료 · PR #7 |
| 4 | `AI06-007` / `axms-ai06-007-profile-version-read-contract` | Backend, Orchestrator | Spring이 활성 Versioned Snapshot JSON을 보관·조회하고 Orchestrator가 Job에 고정된 Version을 읽는 최소 API/Client를 구현한다. | API 계약, Version 불변성, 없는/비활성 Version 거부, 양 저장소 회귀 통과 | **시작 전 협의**: 공통 Profile Table/Flyway·API 계약 확정 | `dev` 병합 완료 · Backend #15 / Orchestrator #8 |
| 5 | `AI06-008` / `axms-ai06-008-job-snapshot-binding` | Backend, Orchestrator | Job 생성 시 `profileVersionId`를 고정하고 Queue에는 `jobId`만 전달하며, Claim/Runner가 Spring 기준 Snapshot을 가져와 실행하도록 연결한다. | Queue Payload 최소성, Job-Version 불변성, 재전달 멱등성, 로컬 통합 회귀 통과 | 공통 Job/Event 계약 변경 승인 완료 | `dev` 병합 완료 · Backend #16 / Orchestrator #9 |
| 6 | `AI06-009` / `axms-ai06-009-approval-check-guardrail-runtime` | Backend, Orchestrator | 등록된 Result Port를 기준으로 공통 Approval·Check·Guardrail과 Checkpoint 재개 경로를 일반화한다. 기능별 정책 내용은 넣지 않는다. | 승인·반려·Check 실패·재개·중복 Callback·우회 방지 테스트, 통합 회귀 통과 | `AI06-008` 병합 후, 공통 상태/보안 계약 확인 뒤 진행 | `dev` 병합·종료 검증 완료 · Backend #19 / Orchestrator #10 |
| 7 | `AI06-010` / `axms-ai06-010-mcp-common-platform-bootstrap` | 신규 MCP 저장소, Backend, Master | 계획된 단일 MCP Repository에 `common`·`coding`·`cms` Package, Service·Catalog 골격과 Spring 왕복 계약을 만든다. MCP의 Core DB 직접 접근은 금지한다. | Spring→MCP→Spring 왕복 계약, Catalog allowlist, DB 직접 접근 부재, 보안 회귀 통과 | 신규 저장소·Service 생성 승인 완료 | `dev` 병합·현행화 완료 · MCP #1 / Backend #21 / Master #22 |
| 8 | `AI04-002` / `axms-ai04-002-coding-handler-integration` | Backend, Orchestrator, MCP | 4번 소유 Coding Job/Candidate/Attempt 결과와 기능별 Coding Handler·Tool을 등록된 계약 안에서 연결한다. | Coding Job E2E, Diff/승인/반려/재시도, 기존 공통 Runtime 회귀 통과 | 사용자 승인 `[제안]` 흐름만 구현; 담당자 확정과 새 공통 계약은 별도 게이트 | `dev` 병합 완료 · Backend #22 / Orchestrator #11 / MCP #2 / Master #23 |
| 9 | `AI05-001-01` / `axms-ai05-001-01-cms-handler-integration` | Backend, Orchestrator, MCP | 5번 소유 Natural CMS Job/Resource/Preview 결과와 기능별 CMS Handler·Tool을 등록된 계약 안에서 연결한다. | CMS Preview/승인/반려/게시 조건, 기존 공통 Runtime 회귀 통과 | 사용자 승인 `[제안]` 최소 수직 연결만 구현; 담당자 확정과 새 공통 계약은 별도 게이트 | `dev` 병합 완료 · Backend #23 / Orchestrator #12 / MCP #3 / Master #24 |
| 10 | `AI06-011` / `axms-ai06-011-admin-profile-settings-integration` | Frontend, Backend | Agent 설정과 중앙 `Guardrail Profile` 목업을 Spring Profile Version·권한·검증 API에 연결한다. 잠금 Guardrail은 UI에서 삭제·비활성화할 수 없게 한다. | 최고관리자 권한, 불변 Version 저장·활성화, 잘못된 설정 거부, UI·Backend 회귀 통과 | `AI06-009` 이후 진행. 공통 Profile/Guardrail 계약 변경 시 협의 | 후속·게이트 |
| 11 | `AI05-002` / `axms-ai05-002-cms-site-settings-integration` | Frontend, Backend | `CMS 기본 설정`과 별도 사이트 관리 화면을 5번 소유 CMS Domain의 저장·조회 API에 연결한다. 공통 Profile Schema를 사이트 설정 저장소로 사용하지 않는다. | 최고관리자 권한, 사이트별 설정 격리, 저장·조회·오류 처리, UI·Backend 회귀 통과 | 5번 범위로 별도 시작. 공통 Table 변경 없으면 자율 진행 | 후속·미시작 |

### UI 목업과 실제 연결의 구분

| 화면 | 목업 Work | 실제 저장·실행 연결 | 최종 소유 경계 |
|---|---|---|---|
| Agent 설정 4개 Tab | `AI06-002` | 기존 실제 연결 Work와 `AI06-011` | 6번 공통 Agent 설정 |
| 자연어 기능 Profile Tab | `AI06-003` | `AI06-007`·`AI06-011` | 6번 Profile 시스템, 4·5번 Profile 내용 |
| 시스템 설정 · 중앙 Guardrail Profile | `AI06-003` | `AI06-009`·`AI06-011` | 6번 공통 Guardrail |
| 시스템 설정 · CMS 기본 설정 | `AI06-003` | `AI05-002` | 5번 CMS Domain |
| 별도 사이트 관리 | `AI06-003` | `AI05-002` | 5번 CMS Domain |

현재 `AI06-002`의 `Tool·실행 정책` Tab에 있는 최소 Guardrail 토글은 로컬 UI 검토용이며 중앙 `Guardrail Profile`이 아니다. 기존 범용 설정 화면의 `일반`·`권한`·`API Key`·`알림` Tab과 공개 사이트 열기 링크도 `AI06-003`의 시스템 설정 2개 Tab·사이트 관리 화면을 대신하지 않는다.

## 4. 자동 진행 범위와 중단 조건

### 자동 진행 가능

- 기존 공통 계약을 만족하는 내부 버그 수정과 테스트 보강
- 등록된 `handlerKey`와 Result Port 안의 Node/Handler/Tool 로직 구현·수정
- 기존 계약을 깨지 않는 내부 Class·Package·Adapter 추가
- 기능 전용 Table 추가가 필요한 경우, 공유 Table을 건드리지 않고 Flyway 예약 원장을 먼저 확인·예약한 변경
- Work ID 범위 안의 Commit·Push·dev 대상 PR·필수 Check 통과 후 병합과 다음 자동 허용 Work ID 진입

### 즉시 중단하고 협의

- Snapshot Schema 또는 공통 Result Port의 하위 호환 불가 변경
- 새로운 Handler·Result Port·Domain 부작용 추가
- 공통 Job/Profile/Approval Table의 구조·컬럼명·상태·관계 변경
- 인증·인가·Secret·Repository 경계·Tool allowlist 등 보안 불변조건 변경
- 4·5·6번 소유권 또는 Spring/Orchestrator/MCP 책임 경계 변경
- 신규 저장소·Service 생성, Branch 보호 우회, CI 실패 상태 병합, 직접 `dev`/`main` Push 필요
- 동일 Work ID Branch/PR 충돌, 테스트 회귀 실패, 원인을 한 Work ID 안에서 안전하게 격리할 수 없는 경우

## 5. Work ID 실행 기록 Template

아래 블록을 시작한 Work ID마다 복사해서 사용한다.

```md
### AI06-XXX · 제목

- 상태: 미시작 | 구현 중 | 검증 중 | PR 검증 중 | dev 병합 완료 | 중단
- 시작 기준: origin/dev SHA
- Worktree/Branch:
- 변경 저장소·Package:
- 구현 Checkpoint:
  - [ ] 단위 1 구현
  - [ ] 단위 1 테스트 및 전체 회귀
  - [ ] 단위 2 구현
  - [ ] 단위 2 테스트 및 전체 회귀
- 검증 명령·결과:
- PR:
- dev Merge SHA:
- 후속 위험/결정:
```

## 6. 현재 다음 행동

- AI06-010 MCP Server #1, Backend #21, Master #22의 `dev` 병합과 공통 기록 현행화를 완료했다.
- `AI04-002 / axms-ai04-002-coding-handler-integration`은 사용자가 승인한 `[제안]` 흐름에 한해 Backend·Orchestrator·MCP Server 최소 구현과 `dev` 병합을 완료했다.
- `AI05-001-01 / axms-ai05-001-01-cms-handler-integration`은 같은 실행 뼈대에 CMS 기능 전용 Resource·Structured Command·Preview 경계를 연결하고 `dev` 병합을 완료했으며, 5번 담당 기능의 최종 확정은 아니다.
- 생산 Tool Catalog에는 승인 범위의 Coding Tool 7개와 CMS Tool 6개만 등록한다. 새로운 공통 Handler/Tool/Result/Snapshot Schema, 공통 Job/Profile/Approval Schema와 보안 경계 변경은 계속 별도 승인 게이트를 따른다.
- Orchestrator Production Snapshot Handler는 Spring Stage API에서 새 결과를 생성한 뒤 기존 Backend Result API로 저장하며, 준비된 Result만 소비하던 Executor는 테스트·호환 용도로만 남겼다.

### AI04-002 · Coding Handler 연동 `[제안]` 구현

- 상태: `[제안]` 최소 수직 실행 연결 `dev` 병합 완료
- Work ID / work slug: `AI04-002` / `axms-ai04-002-coding-handler-integration`
- 승인 기준: 2026-08-30 사용자 구두 합의를 기능 확정이 아닌 `[제안]` 노드 템플릿으로 적용하며, 4번 담당자 `jcy644542`가 이후 직접 변경·기능 테스트한다.
- 시작 기준: Backend `37e8f413` / Orchestrator `8ffdace39` / MCP Server `e6595aea`
- Worktree/Branch: 저장소별 최신 `origin/dev` 기반 독립 Worktree / `feature/tmdwns0531_axms-ai04-002-coding-handler-integration_v0.1`
- 구현 Checkpoint:
  - [x] 요구사항 분석·코딩 가능성 검증 → 일반관리자 승인 → 코딩 → 코드리뷰 → 미리보기 → PR 요청 → GitHub 최고관리자 수동 승인 → CMS 일반관리자 승인 → 최고관리자 배포 승인 → 배포 순서
  - [x] 리뷰 반려 시 코딩·리뷰를 총 3회까지 반복하고, 미리보기 반려 시 요구사항 분석으로 돌아가 전체 Pipeline을 총 3회까지 반복
  - [x] Backend의 기능 소유 Job/Candidate/Attempt/Result/Approval, Orchestrator 14-node 제안 Graph·Handler, MCP Coding Tool 7개 연결
  - [x] 최신 code candidate → passed review → preview 후보 연결, 상태 Version·재시도 멱등성·Result 동시성·역할/승인 주체 검증
  - [x] AI04 전용 Stage Executor가 제한된 최대 8회 Model↔Tool 루프에서 기존 MCP 7-tool allowlist만 호출하고 Tool 결과를 다음 Model 입력으로 환류
  - [x] Orchestrator Production Executor가 Stage 결과를 기존 Result Port/Backend Result API에 저장하고 동일 resultId 재전달 시 저장 결과를 재사용
- 검증 결과:
  - Backend 보완 집중 테스트 통과, Product 전체 회귀에서 기준선 CRLF 1개 제외 178개 통과·환경 게이트 4개 Skip, Control에서 같은 CRLF 1개 제외 174개 통과·환경 게이트 4개 Skip, 두 실행 JAR Build 통과
  - Control 원형 회귀에서 추가로 관찰된 `JwtTokenProviderTest.aModifiedSignatureNeverDecodes` 1회 실패는 단독 즉시 재실행과 Product 회귀에서 통과해 비결정적 기준선으로 분리했다.
  - Backend runtime production Image는 저장소의 opt-in CA Secret 경로로 Build 통과했으며 인증서 내용은 Image·로그·Git에 포함하지 않았다.
  - Orchestrator 전체 151개·`compileall` 통과, Stage API POST→기존 Result PUT 연결 및 Backend Model→Tool 결과 환류 테스트 통과
  - MCP 전체 29개 통과·Windows symlink 권한 1개 Skip, `compileall`·보호 경로/경쟁 조건·diff/secret 검증 통과
  - Backend·Orchestrator staged `git diff --check`, 두 변경 저장소의 고신뢰 credential 패턴 검사 통과
- Commit / Draft PR:
  - Backend `4a497a601b6f7febb8c19f79c3d3f6d860329189` / [#22](https://github.com/urizo-final-org/urizo-final-backend/pull/22)
  - Orchestrator `fa1e9ab274b12d4c7090d36fb01109cbad07113a` / [#11](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/11)
  - MCP Server `b21d69564fa8d7a62eec4e20fb1299c47c744f44` / [#2](https://github.com/urizo-final-org/urizo-final-mcp-server/pull/2)
- PR 상태: Backend #22, Orchestrator #11, MCP Server #2와 Master #23 모두 `dev` 병합 완료
- dev Merge SHA: Backend `acdfa58d7278e59567157ec089531595647fd86c` / Orchestrator `221d64175129dd065f23de2d9c7c81863a9932aa` / MCP Server `6f0380f8e5749e4a71de80fdbbb7d3fdbcf5f93c` / Master `8dbda3591263449b825e7dc68f9010ac50aa6771`
- 남은 차단/결정:
  - 실제 Provider·사전 준비 MCP Workspace·DB를 함께 사용한 live Production Job 실행은 로컬 CMS를 건드리지 않는 이번 보완 조건에 따라 수행하지 않았다. 자동 검증 범위는 Model→Tool 결과 환류와 Stage API→기존 Result 저장 계약이다.
  - Orchestrator·MCP Production Image Build는 `files.pythonhosted.org` 인증서 `UnknownIssuer` 환경 오류로 완료하지 못했다. Backend의 최초 무-Secret Build도 Maven Central PKIX에서 같은 환경 문제를 보였고 안전한 opt-in CA Secret 적용 시 통과했다. TLS 검증 완화는 사용하지 않았다.
  - MCP Workspace는 Production에서 UID 10001이 쓸 수 있는 사전 준비된 하위 Git Workspace를 mount해야 하며, clone/provision 계약은 이번 범위 밖이다.
  - 실제 DB/Flyway 실행과 로컬 CMS 재빌드·재기동은 하지 않았다.
  - 4번 담당자의 제안 노드 템플릿 최종 확정·기능 테스트는 별도 후속 게이트다.

### AI05-001-01 · Natural CMS Handler 연동 `[제안]` 구현

- 상태: `[제안]` 최소 수직 실행 연결 `dev` 병합·Closeout 검증 완료
- 마감 Work ID / work slug: `AI05-001-01-CLOSEOUT` / `axms-ai05-001-01-post-merge-closeout`
- Work ID / work slug: `AI05-001-01` / `axms-ai05-001-01-cms-handler-integration`
- 승인 기준: 2026-08-31 사용자 승인 범위만 구현하며, 5번 담당자 `LEEJAEWOOK1` 소유의 상세 기능 문서와 AI05-001 Backend #20 변경은 수정·재작성하지 않는다.
- 시작 기준: Backend `acdfa58d7278e59567157ec089531595647fd86c` / Orchestrator `221d64175129dd065f23de2d9c7c81863a9932aa` / MCP Server `6f0380f8e5749e4a71de80fdbbb7d3fdbcf5f93c` / Master `8dbda3591263449b825e7dc68f9010ac50aa6771`
- Worktree/Branch: 저장소별 최신 `origin/dev` 기반 독립 Worktree / `feature/tmdwns0531_axms-ai05-001-01-cms-handler-integration_v0.1`
- 구현 Checkpoint:
  - [x] 기존 Snapshot Runner·Registry에 8-node `NATURAL_CMS` Snapshot과 CMS Stage Handler를 등록하고 Analyze→Preview→Approval→Apply 및 Rejected→Discard→Analyze 제한 재시도 Edge를 연결
  - [x] Spring Stage Executor에서 최대 8회 Model↔Tool 반복, Tool 결과의 다음 Model 입력 환류, CMS 기능 전용 Result 저장을 연결
  - [x] 예약 CMS Tool 6개만 MCP 생산 Catalog에 등록하고 MCP는 Spring이 전달한 Snapshot을 순수 변환하며 Core DB에 직접 접근하지 않음
  - [x] 승인 전에는 Preview 경계만 저장하고, 승인 직전 MCP 재검증 뒤 기존 `CmsRequestValidator`와 `CmsService.updateContent` Transaction으로만 최종 반영
  - [x] CMS 저장 경계에는 `resource`, `structuredCommand`, `previewId`, `previewHash`만 사용하고 Worktree·Candidate SHA·Diff·PR·Git 필드를 추가하지 않음
- 검증 결과:
  - Backend 집중 계약 테스트와 JAR Build 통과. 전체 회귀는 183개 통과·환경 게이트 4개 Skip이며, 기존 Windows CRLF 기준선 테스트 1개만 실패
  - Orchestrator 전체 155개와 Snapshot 승인·반려 E2E 계약 테스트, Python `compileall` 통과
  - MCP CMS/Catalog/Service 집중 11개 통과. 기존 생산 Image 기반 전체 회귀는 30개 통과, Windows bind mount 파일 모드 기준선 2개만 실패
  - 세 Source 저장소 `git diff --check`, staged credential 패턴 검사, CMS 생산 경계의 Coding 전용 필드 부재 검사 통과
  - Backend·Orchestrator·MCP production Image Build는 외부 Maven Central/PyPI 인증서 `UnknownIssuer` 환경 오류로 중단했으며 TLS 검증을 완화하지 않음
- 5번 담당자 인수인계 변경점:
  - Resource Schema와 검증 규칙은 Backend `NaturalCmsResourceService`, Preview·게시 의미와 승인 직전 적용 순서는 `NaturalCmsStageService`에서 변경한다.
  - 노드 순서·Result Port·반려 재시도는 Orchestrator `default_natural_cms_snapshot.py`와 `natural_cms_handlers.py`, 순수 Preview 계산은 MCP `cms/preview.py`에서 변경한다.
  - 이번 제안은 `CONTENT UPDATE(title, body)`만 지원한다. 확장 시에도 기존 `CmsRequestValidator`·`CmsService`를 재사용하고 MCP Core DB 직접 접근 금지를 유지한다.
  - 공통 Job/Profile/Approval/Result/Snapshot Schema와 Worker dispatch 계약은 변경하지 않았다. 실제 생산 Queue dispatch가 필요하면 공통 계약 승인 후 별도 Work로 연결한다.
- Commit / PR:
  - Backend `e4cc38bd72660a848db548fd96709bd3221b3fa1` / [#23](https://github.com/urizo-final-org/urizo-final-backend/pull/23)
  - Orchestrator `d89bc770791ed45cb571f8be05405b4abaff1abb` / [#12](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/12)
  - MCP Server `f3392ecc9654f316b60d52dcc2ef03de6af88d62` / [#3](https://github.com/urizo-final-org/urizo-final-mcp-server/pull/3)
  - Master [#24](https://github.com/urizo-final-org/urizo-final-master/pull/24)
- PR 상태: Backend #23, Orchestrator #12, MCP Server #3, Master #24 모두 `dev` 병합 완료
- dev Merge SHA: Backend `5d10afde15c52c7748e6998416c02438692d6ac6` / Orchestrator `1332543171e4993ad9fffb9edee097b880103705` / MCP Server `1fbf2bd2ca650bb33d1518713b49220af942ecb3` / Master `24018692f332afe0bf65b4f39843c51480e6afd5`
- 로컬 CMS 재빌드·재기동, 실제 DB/Flyway 실행, Volume 변경은 하지 않았다.

### AI06-010 · MCP 공통 플랫폼 부트스트랩

- 상태: MCP Server·Backend·Master `dev` 병합·현행화 완료
- 시작 기준: Backend `9f0b529e4e0d702b7d30c95db3e48d838097e531` / Master `d500096c28fd09fb9bbc9f5c3d0bc1046e76dd70` / MCP 신규 Repository
- Worktree/Branch: 저장소별 격리 Worktree / `feature/tmdwns0531_axms-ai06-010-mcp-common-platform-bootstrap_v0.1`
- 변경 저장소·Package: MCP `common`·`coding`·`cms`, Backend `integration.ai.mcp`, Master Workspace manifest·AI06 기록
- 구현 Checkpoint:
  - [x] 공식 MCP Python SDK 기반 단일 인증 Streamable HTTP `/mcp`와 빈 생산 Catalog
  - [x] Backend 고정 Allowlist·조건부 Client와 실제 discovery/`tools/list` 왕복
  - [x] Core DB 접근 부재, 양 저장소 전체 회귀·production Image·diff/secret 검증
- 검증 명령·결과:
  - MCP Python 단위 테스트 11개와 `compileall` 통과, frozen lock production Image Build 통과
  - MCP Image를 non-root `10001:10001`, read-only rootfs, `no-new-privileges`, localhost 격리 포트로 실행해 readiness `READY`, 빈 Tool Catalog, 미인증 `401` 확인
  - Spring 실제 `server/discover`·`tools/list` 왕복 1개 통과, Backend 집중 14개 통과
  - Backend Product 전체 145개·Control 전체 141개에서 실패·오류 0, 환경 게이트 각 3개 Skip, 두 JAR Build 통과
  - dev/preview Compose config, Backend PowerShell parse, 세 저장소 diff check와 staged credential scan 통과
- PR: MCP Server [#1](https://github.com/urizo-final-org/urizo-final-mcp-server/pull/1) / Backend [#21](https://github.com/urizo-final-org/urizo-final-backend/pull/21) / Master [#22](https://github.com/urizo-final-org/urizo-final-master/pull/22) · 병합 완료
- dev Merge SHA: MCP `e6595aeaeda5a98512004ee3252cc1b02067feec` / Backend `e736f7e8a4c87718bb0659b38591ed3c5fed1c3e` / Master `8ba1714912a9d0d8da6b87b760ddbb4495913a63`
- 후속 위험/결정:
  - 실제 Coding·CMS Tool Handler, 기존 CodingToolService 전환, Frontend와 새 DB/Flyway는 후속 AI04/AI05 범위다.
  - 실행 중인 로컬 CMS는 재빌드·재기동하지 않는다.

### AI06-009 · Approval·Check·Guardrail Runtime

- 상태: `dev` 병합·종료 검증 완료
- 마감 Work ID: `AI06-009-CLOSEOUT` / `axms-ai06-009-post-merge-closeout`
- 시작 기준: Backend `bc741c5256d896b8c49ed1d443c989879bbe2eeb` / Orchestrator `e411fbbfffa85635b9969aa1ce09c38e9d5d6248`
- Worktree/Branch: Backend 새 Worktree / `feature/tmdwns0531_axms-ai06-009-approval-check-guardrail-runtime_v0.2`, Orchestrator 기존 clean Worktree / `feature/tmdwns0531_axms-ai06-009-approval-check-guardrail-runtime_v0.1`
- 변경 저장소·Package: Backend Coding Job lifecycle/Worker 계약, Orchestrator 공통 Handler·Registry·Snapshot resume
- 구현 Checkpoint:
  - [x] 기존 상태·lifecycle command를 재사용한 승인·반려 전이와 중복 Callback 억제
  - [x] 공통 Start·Guardrail·Check·Approval·End Handler와 production Registry 연결
  - [x] 승인·반려·Check 실패·재개·기술 재시도·우회 방지와 양 저장소 전체 회귀
- 검증 명령·결과:
  - Backend offline contract gate: 7 documents, 41 operations, 829 local references, Fixture 108 valid·50 invalid 통과
  - Backend 집중 product/control 각 19개 통과, 전체 product 133개·control 129개에서 실패·오류 0, 환경 게이트 DB Integration 각 2개 Skip, 두 JAR Build 통과
  - Backend 최종 `dev` Merge Tree `9f0b529e4e0d702b7d30c95db3e48d838097e531`에서 계약 7문서·41 operation·829 local reference·108 valid/50 invalid Fixture, Product 133개·Control 129개와 두 JAR Build를 다시 통과했다.
  - 최종 Product 첫 실행에서 기존 공용 `JwtTokenProviderTest.aModifiedSignatureNeverDecodes` 간헐 실패가 1회 재현됐고, 동일 테스트 6회 연속 통과 후 전체 Product 재실행이 통과했다. AI06-009 변경과 무관한 기존 테스트 취약점으로 별도 후속 처리한다.
  - Flyway 정적 마감 검증은 18개 Migration, `20260830073257815` 다음 `20260830074952891`, 검증 Script Parser Error 0, 승인 조회 5개 Column만 Grant, Table-level SELECT 없음으로 통과했다.
  - Orchestrator 집중 50개·전체 123개 테스트와 40개 Python 파일 문법 검사 통과
  - Orchestrator frozen `uv.lock` production Image Build, non-root UID 10001, production common Handler Key 5개 확인
  - 양 저장소 `git diff --check`, added-line Secret Scan, 독립 최종 정적 감사 통과; reportable P1/P2/blocker 없음
  - Backend Flyway 전체 격리 검증은 기존 로컬 `migration_owner` 인증 불일치(28P01)로 새 Revision 적용 전에 중단됐다. 생성된 임시 검증 DB는 정리했고 실행 중 CMS DB에는 새 Revision을 적용하지 않았으며 `/api/readiness`는 `READY`다.
- PR: Backend [#19](https://github.com/urizo-final-org/urizo-final-backend/pull/19) / Orchestrator [#10](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/10) · `dev` 병합 완료
- dev Merge SHA: Backend `9f0b529e4e0d702b7d30c95db3e48d838097e531` / Orchestrator `8ffdace39ed91309f67759f65238ce50f3a5f324`
- 후속 위험/결정:
  - Backend `v0.1` Worktree의 중단 시점 미커밋 초안은 폐기하지 않고 별도 보존하며, 실제 구현은 최신 `dev` 기반 `v0.2`에서 진행한다.
  - Backend #19 Merge Commit의 첫 Parent가 #18 Merge SHA `55b382c889d4bbe39a0ecd8b80d2bd4e51c77c53`이며, 결합된 최종 `dev` 전체 회귀로 Flyway 순서와 호환성을 마감 확인했다.
  - `resume=true`는 정확한 `WAITING_APPROVAL → RUNNING` 승인 claim만 뜻한다. higher attempt는 기술 재시도이며 승인 interrupt를 소비하지 않고, 반려는 Spring `CANCELLED`로 종료한다.
  - Flyway empty-head·직전 Revision upgrade는 정상 격리 자격 증명이 있는 CI 또는 수동 게이트에서 확인해야 한다.
  - 실행 중인 로컬 CMS는 재빌드·재기동하지 않았으며 새 Migration도 적용하지 않았다.
  - 새 공통 Schema·상태·Handler/Tool/Result Port나 기능별 정책이 필요하면 구현 전에 별도 승인받는다.

### AI06-008 · Job–Snapshot 바인딩

- 상태: `dev` 병합 완료
- 시작 기준: Backend `3c59ab10e433ed097ffd884fc08fffda9b9afb5e` / Orchestrator `29a7ae5f123b57717f2d383e8123a5e0cc89bac8`
- Worktree/Branch: 저장소별 새 Worktree / `feature/tmdwns0531_axms-ai06-008-job-snapshot-binding_v0.1`
- 변경 저장소·Package: Backend Coding Job·Worker/Flyway, Orchestrator Worker·Snapshot production wiring
- 구현 Checkpoint:
  - [x] Job 생성 시 ACTIVE `profileVersionId` 고정 및 Queue `jobId` 전용 계약
  - [x] Claim 응답과 Snapshot 읽기·Runner production 연결
  - [x] 중복 전달·재시도 불변성 및 양 저장소 전체 회귀
- 검증 명령·결과:
  - Backend 계약 검증 7 documents·41 operations·108 valid/50 invalid, `mvnw clean verify` 127 tests, `-Pspring-ai-control` 123 tests, Flyway empty/previous→head와 불변성·권한 검증 PASS
  - Orchestrator 전체 112 tests, Python AST 38 files, production image build, diff/secret scan PASS
  - 독립 최종 검토에서 ACK/NACK 안전 경계 포함 blocker/high finding 없음
- PR: Backend [#16](https://github.com/urizo-final-org/urizo-final-backend/pull/16) / Orchestrator [#9](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/9) · 병합 완료
- dev Merge SHA: Backend `620f09b2032c616daec035fe393469e6092fde35` / Orchestrator `e411fbbfffa85635b9969aa1ce09c38e9d5d6248`
- 후속 위험/결정:
  - AI06-009 Approval·Check·Guardrail 일반화는 AI06-008 범위에 포함하지 않았고, 이후 별도 Work ID로 시작했다. MCP 실연동은 계속 후속 범위다.
  - 6번은 LLM Ops·Natural CMS의 실행 골격·표준·안전 경계만 소유하고, 기능별 UX·업무 규칙·Profile 내용·Handler·Tool·Domain·메뉴는 4·5번 상세 문서가 소유한다.
  - 공통 플랫폼 작업이 모두 끝난 뒤 실제 Runtime과 일치하는 Snapshot/Node/Edge/Handler/Result Port, Job/Queue/Checkpoint/Approval, MCP 보안 경계·확장 지점·불변조건·승인 게이트·회귀 체크리스트를 공통 AI 문서에 최종 정리한다.
