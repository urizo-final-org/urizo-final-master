# 6. 오케스트레이션 제어

> 담당자: 민승준 (`tmdwns0531`)
> 현재 단계: AI06-008 `dev` 병합 완료 · AI06-009 별도 승인 게이트
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 기능 목표와 소유 범위

6번은 Agent 설정과 4·5번이 함께 사용하는 제한형 실행 플랫폼을 소유한다.

| 영역 | 6번 플랫폼 소유 범위 |
|---|---|
| Agent 설정 | Provider·Model, Agent·Workflow, 자연어 기능 Profile, Tool·실행 정책, 사용량·평가 |
| Template | 실행 가능한 Node·Edge·Config 편집·검증, 불변 Versioned Snapshot JSON과 Profile 활성화 |
| 공통 Runtime | JSON Loader·Snapshot Runner·Graph Builder·Node Registry, `NodeInvocation`·`NodeResult`, Checkpoint와 Approval Interrupt·재개 |
| 공통 Handler | Agent 호출, Approval, Check, Guardrail과 Node 상태·결과 기록 |
| Handler·Tool 계약 | Coding·CMS Handler·MCP Tool의 공통 호출 형식, Registry 연결, 보안 경계와 Contract Test 기반 |
| MCP 공통 플랫폼 | 단일 Service·Catalog, `common` Package, 인증·Allowlist·공통 호출 Adapter |
| 관측 | Langfuse SDK·OpenTelemetry·API 연계와 최소 관리자 표시 |

4번은 LLM Ops Job Domain·Profile 내용과 LLM Ops 전용 Handler·`coding` Tool 기능 로직·테스트를,
5번은 Natural CMS Job Domain·Profile 내용과 Natural CMS 전용 Handler·`cms` Tool 기능 로직·테스트를
소유한다. 두 담당자는 공통 계약 안에서 이를 독립적으로 구현·수정할 수 있다. 6번은 두 기능의 Domain 상태와
업무 의미를 임의로 정하지 않고, 4·5번은 공통 Runtime·Registry·보안 경계를 기능 코드에 복제하지 않는다.

장기 문서화에서도 6번은 실행 골격·표준·안전 경계만 고정하고 기능별 UX·업무 규칙·Profile 내용·Handler·Tool·Domain·메뉴는
`04_LIMITED_LLM_DEVOPS.md`와 `05_NATURAL_LANGUAGE_CMS.md`가 소유한다. 공통 플랫폼 작업이 모두 끝난 뒤 실제 구현과 일치하는
Runtime 구조, Snapshot/Node/Edge/Handler/Result Port 표준, Job/Queue/Checkpoint/Approval 규칙, MCP 보안 경계와 필수 회귀를 최종 정리한다.

## 현재 UI 작업과 다음 범위

### AI06-002 현재 목업

- 최고관리자 전용 기존 `Agent 설정` Route에서 제공한다.
- Provider·Model, Agent·Workflow, Tool·실행 정책, 사용량·평가 4개 Tab을 로컬 상태로 구현했다.
- Start·Agent·MCP Tool·Approval·Check·End Node의 추가·삭제·이동·연결을 시각적으로 검토한다.
- 저장 API, Profile Version, Backend 검증, LangGraph·MCP·Langfuse 실제 실행은 포함하지 않는다.
- OmniRoute와 Langfuse 영역은 `향후 적용 예정`으로만 표시한다.

### AI06-003 확정 범위

- Agent 설정에 `자연어 기능 Profile` Tab을 추가한다.
- 시스템 설정의 `CMS 기본 설정`, 중앙 `Guardrail Profile`과 별도 사이트 관리 화면을 목업으로 검토한다.
- Agent 설정·시스템 설정·사이트 관리는 최고관리자 전용으로 유지한다.
- 실제 저장·검증·Runtime 연결은 UI 목업과 분리된 후속 Work에서 시작한다.

AI06-002·003은 사용자 흐름 협의를 위한 UI 목업이다. 실제 Runtime 구현 승인을 의미하지 않는다.

## 확정 Runtime 경계

```text
Frontend
→ Spring Job API
→ PostgreSQL Job·Versioned Profile JSON + Outbox
→ Valkey jobId
→ Orchestrator가 Spring에서 profileVersionId의 JSON 조회
→ handlerKey를 Node Registry 함수에 연결·LangGraph 내부 compile()
→ Spring Model·Tool Gateway
→ urizo-final-mcp-server
→ Spring 상태·결과 저장
→ LangGraph 재개 또는 승인 대기
→ Frontend 조회
```

- LLM Ops와 자연어 CMS는 같은 Python LangGraph Service에서 `LLM_OPS`, `NATURAL_CMS` Profile로 실행한다.
- Spring은 인증·권한, Job, Profile Version, Tool 정책과 Domain 상태의 원자 변경·저장 기준이다.
- LangGraph는 활성 Snapshot의 `nodes`, `edges`, `config`에 따라 Node 순서·분기·제한된 반복과 Approval Interrupt를 실행한다.
- Spring과 4·5번 Backend는 다음 Node를 선택하지 않는다. Snapshot Runner가 Handler의 결과 Port와 Edge를 해석한다.
- MCP Server는 고정 Tool만 실행하고 Core DB에 직접 접근하지 않는다.
- 일반 CMS CRUD는 기존 Spring 동기 API를 유지한다. 자연어 CMS 최종 반영은 기존 CMS Domain Service가 수행한다.

## Versioned Profile 계약

Profile JSON과 Job 실행 Context는 분리한다. 공통 필드 정의는
[`AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md`](../AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md)의
`Snapshot과 Job 실행 계약`을 원본으로 사용한다.

- Profile JSON에는 `contractVersion`, Profile 식별자, `nodes`, `edges`, `config`, `modelBindings`,
  `toolPolicy`, `guardrailProfileKey`를 저장한다.
- Job별 `jobId`, `pipelineAttempt`, `executionAttempt`, `stateVersion`, `workspaceId`, `toolCallId`,
  `traceId`는 Profile JSON에 넣지 않고 실행 Envelope·Node Context로 전달한다.
- Job은 시작 시 불변 `profileVersionId`를 고정한다. 실행 중 Job은 같은 Version을 유지하고 새 ACTIVE Version은 신규 Job부터 적용한다.
- Spring Profile Resolver가 활성 설정을 PostgreSQL의 Versioned JSON으로 저장하고 Orchestrator는 Spring을 통해 조회한다.

## SIMPLE IS BEST 제한형 Graph

### 최초 Runtime 구성

| 구성 | 최소 원칙 |
|---|---|
| Node Registry | Start·Agent·Approval·Check·잠금 Guardrail·End와 승인된 Coding·CMS Handler만 Source에 등록한다. |
| 공통 호출 | 개념상 `run_node(context, config) -> NodeResult`로 호출하고 Job·Profile Version·Node·Attempt와 결과 Port를 전달한다. |
| Graph Builder | `handlerKey`를 Registry 함수에 연결하고 `add_node`, `add_edge`, 조건부 Edge와 `compile()`로 메모리 실행 객체를 조립한다. |
| 활성화 검증 | Start·End, 허용 Node·Handler, 필수 잠금 Guardrail, Port, 도달 가능성과 최대 Node 수를 검사한다. |

- 등록되지 않은 사용자 정의 Node·Plugin은 실행하지 않는다.
- 병렬 실행, Sub-workflow, 임의 Cycle과 동적 MCP 등록은 초기 범위에서 제외한다.
- Guardrail은 Profile에 자동 삽입하고 삭제·비활성화할 수 없게 하며 Spring Tool Gateway에서도 강제한다.
- Approval은 사람의 제어 Node이며 MCP Tool이 아니다. 없으면 `APPROVAL_NOT_REQUIRED`로 기록한다.
- Check는 등록된 결정적 Handler·Tool을 자동 실행하고 결과 Port를 반환한다.
- Handler는 현재 작업 결과만 반환한다. 다음 Node는 공통 Runner가 Snapshot Edge로 결정한다.
- `compile()`은 바이너리·Script·공유 파일을 만들지 않는다. 초기에는 Compile 결과 Cache도 만들지 않는다.

### 기능 담당자의 자율 수정 경계

4·5번은 다음 변경을 6번의 사전 요청·승인 없이 수행할 수 있다.

- 기존 `handlerKey` 내부의 담당 기능 로직·오류 처리·테스트 수정
- 기존 Tool 이름·입출력 계약 안의 `coding`·`cms` Tool 구현·버그 수정
- 승인된 Work ID 안에서 공통 호출 형식·인증·권한·Spring 최종 저장 경계를 유지하는 담당 Package의
  기능 전용 leaf Tool 병렬 추가·미사용 Tool 삭제와 Catalog·Allowlist·Profile 참조·테스트 동시 갱신
- 기존 Result Port 안의 반환 조건과 내부 계산 수정
- 담당 Profile의 Node·Edge·Config와 Scenario Fixture 변경
- 담당 Package 내부 리팩터링과 회귀 테스트 추가
- 담당 Spring Domain만 사용하는 내부 Table 추가와 Flyway Migration

다음은 공통 플랫폼·계약 변경이므로 관련 기능 담당자와 6번이 함께 처리한다.

- 새로운 Node Type·`handlerKey`, 공통·공유 Tool 또는 Result Port 추가
- 공통 Tool 호출 형식·기존 Tool 입출력 계약·Catalog·Allowlist 구조, Result Port 의미, Snapshot Schema 변경
- Runner·Graph Builder·Registry·Checkpoint·Approval Interrupt 변경
- 공통 Approval·Check·Guardrail, 인증·권한·Allowlist·보안 경계 변경
- 다른 기능 또는 Spring Domain에 새로운 부작용 추가
- 공통 Job·Profile·Approval Table의 구조·Column·상태·관계 변경

자율 수정도 Core DB 직접 접근 금지, 임의 Shell 금지, 잠금 Guardrail과 Spring 최종 저장 원칙을 지켜야 한다.
담당자는 공통 Contract Test와 기능 Scenario Test를 통과시킨 뒤 자신의 기능 PR로 검토한다.
기능 전용 Table도 Flyway 예약·검증을 거치며 MCP·LangGraph는 Table을 만들거나 Core DB에 접근하지 않는다.

## 한 MCP Project와 Tool Tree

```text
urizo-final-mcp-server
├─ common
├─ coding
│  ├─ read_file
│  ├─ search_code
│  ├─ read_diff
│  ├─ apply_patch
│  ├─ run_check
│  ├─ check_package_allowlist
│  └─ scan_changed_files
└─ cms
   ├─ resolve_cms_target
   ├─ validate_cms_command
   ├─ create_cms_preview
   ├─ discard_cms_preview
   ├─ revalidate_cms_preview
   └─ apply_cms_preview
```

- 계획 저장소·Container·Service Endpoint·Tool Catalog는 각각 하나만 두고 공통 골격과 계약은 6번이 소유한다.
- `common` Package와 인증·Allowlist·공통 호출 Adapter는 6번이 구현·수정한다.
- `coding` Package의 기능 로직·오류 처리·테스트는 4번이 구현·수정한다.
- `cms` Package의 기능 로직·오류 처리·테스트는 5번이 구현·수정한다.
- UI에서는 Coding·CMS Tree로 구분하고 `LLM_OPS`는 Coding, `NATURAL_CMS`는 CMS Tool만 기본 허용한다.
- `run_check`는 사전 등록한 Test·Typecheck·Build Profile만 실행하고 임의 Shell을 받지 않는다.
- Diff Preview는 `read_diff` 결과를 4번 화면에서 렌더링하며 별도 `git_diff` Tool을 추가하지 않는다.
- Coding Tool은 영향 Repository의 Job Worktree에서 실행하고 4번이 결과를 Coding Job·Candidate와 연결한다.
- 자연어 CMS Agent가 구조화 Command를 만들고 5번 CMS Tool은 대상 확인·검증·Preview·재검증 결과를 계산한다.
- `apply_cms_preview`는 Core DB에 직접 쓰는 Tool이 아니다. 승인된 결과의 최종 Transaction과 Version 게시는 기존 Spring CMS Domain Service가 수행한다.
- 임의 MCP Server·Tool·Shell, Marketplace, 복잡한 DSL과 다중 Server Routing은 초기 범위에서 제외한다.

## Job·Queue 소비 경계

- Queue Lane은 Product, Coding, Natural CMS 세 개만 사용한다.
- PostgreSQL이 Job 상태의 기준이고 Valkey Queue에는 `jobId`만 저장한다.
- 같은 `jobId`를 Spring·Valkey·LangGraph·MCP·승인·PR까지 전파한다.
- 개별 MCP Tool Call은 새 Job이 아니라 기존 Job의 `toolCallId`로 기록한다.
- 업무 반려는 `pipelineAttempt`, 기술 재시도는 `executionAttempt`로 구분한다.
- 승인 대기는 PostgreSQL·Checkpoint에 저장하고 Worker Lease를 점유하지 않는다.
- 6번은 공통 Queue 실행 계약을 제공하지만 4·5번 Job Domain 상태의 업무 의미는 소유하지 않는다.

## Guardrail과 관측

- 작업 경로·보호 파일·Package·Agent별 Tool Allowlist와 Secret 노출 차단을 최소 Guardrail로 둔다.
- 인증·Secret·Migration 보호 대상은 고정 Denylist로 항상 차단하며 관리자가 허용 경로로 바꿀 수 없다.
- Langfuse 전체 Self-host와 Pipeline Node는 도입하지 않는다.
- SDK·OpenTelemetry·API로 `jobId`, Trace, Model, Token, 지연시간과 Tool·Check 결과를 연결한다.
- Prompt·Source·Diff 원문은 기본 전송하지 않고 별도 결정이 있을 때만 허용한다.
- RAGAS와 평가 점수의 Pipeline Gate 사용은 기능 완료 기준이 정해진 뒤 별도 협의한다.

## 제외·후순위

| 항목 | 현재 판단 |
|---|---|
| OmniRoute | `향후 적용 예정` 목업만 유지하고 실제 Routing·Token 압축은 연결하지 않는다. |
| n8n·Orca | 기존 LangGraph·Spring Job 책임과 중복되므로 Runtime으로 도입하지 않는다. |
| Plannotator | 4번 분석·리뷰·승인 흐름과 중복되므로 도입하지 않는다. |
| LangSmith | 현재 범위에서 제외한다. |
| 병렬·Sub-workflow | 초기 제한형 Graph 범위에서 제외한다. |
| 외부 MCP 등록 | 초기 범위에서 제외한다. |

## 기능별 협의 상태

| 기능 | 6번이 전달한 공통 경계 | 상태 |
|---|---|---|
| 2번 | Product Queue Job Type·공통 Job Envelope·복구 | Agent 설정과 무관한 담당자 검토 제안 |
| 3번 | 장시간 품질 재평가·재빌드 Job Type·공통 Job Envelope·복구 | Agent 설정과 무관한 담당자 검토 제안 |
| 4번 | 공통 LLM_OPS Runtime 계약과 4번 소유 전용 Handler·Coding Tool 경계 | 담당 문서 소유권 문구 현행화 필요 |
| 5번 | 공통 NATURAL_CMS Runtime 계약과 5번 소유 전용 Handler·CMS Tool 경계 | 담당 문서 소유권 문구 현행화 필요 |

## 진행 상태

- 현재: AI06-010 단일 MCP 플랫폼 부트스트랩을 MCP Server PR #1과 Backend PR #21로 `dev` 병합하고 전체 회귀·production Image·실제 왕복 검증을 완료했다.
- 완료 범위: 기존 Approval·Checkpoint Runtime을 유지하면서 신규 `urizo-final-mcp-server`, 빈 생산 Catalog, 고정 Tool 이름 Allowlist, 서비스 토큰 인증과 Spring의 조건부 discovery/`tools/list` Client를 추가했다.
- 다음 게이트: 실제 Coding·CMS Tool Handler와 기존 CodingToolService 전환은 AI04/AI05 담당 범위다. AI06 공통 플랫폼은 새 Handler·Tool·DB 계약을 선행 확장하지 않는다.

## 하위 작업 기록

### `AI06-001` · Agent 설정 메뉴 정리

- [x] 별도 `Agent 관리` 사이드바 메뉴 숨김
- [x] Provider·Model 통합 화면의 사이드바 메뉴명을 `Agent 설정`으로 변경
- [x] 기존 Route와 상세 화면 제목을 유지하고 Frontend 회귀 테스트 확인

### `AI06-002` · Agent 설정 Workspace 목업

- [x] Provider·Model, Agent·Workflow, Tool·실행 정책, 사용량·평가 4개 Tab
- [x] Start·Agent·MCP Tool·Approval·Check·End Node의 로컬 추가·삭제·이동·연결
- [x] 최고관리자 전용 Route와 범위 집중 테스트·전체 테스트·TypeScript·Build 검증
- [x] Frontend PR #12 `dev` 병합 (`2f1113140bb68d4e41d90484f0bce5315913f958`)

### `AI06-003` · 자연어 Profile·통합 관리 목업

- [x] AI06-002 병합 후 우선 진행 확정
- [x] 최고관리자 전용 Frontend 로컬 목업 구현·검증·`dev` 병합 (PR #13, `673974bca136b5bad1b6deb7f0a4a72684f73251`)

### `AI06-004` · Snapshot Contract

- [x] 최신 Orchestrator `origin/dev` 기반 독립 Worktree 준비
- [x] 현행 Graph 실행 경로를 유지한 불변 Snapshot 모델·JSON Loader·Validator·Fixture 구현·검증·`dev` 병합 (PR #5, `55e1d83416e7aa8893f180f053498a5b668e9586`)

### `AI06-005` · Registry·Graph Builder

- [x] 최신 AI06-004 병합 `origin/dev` 기반 독립 Worktree 준비
- [x] 테스트 Handler만 사용하는 Registry·공통 Invocation/Result·Snapshot Graph Builder 구현·검증·`dev` 병합 (PR #6, `c35e292e950c4992e70a2fba36188e9041b3be0a`)

### `AI06-006` · Snapshot Runner 호환

- [x] 최신 AI06-005 병합 `origin/dev` 기반 독립 Worktree 준비
- [x] 현행 Coding Graph·Worker 계약과 Snapshot Runner 호환 경로 구현·검증·`dev` 병합 (PR #7, `8c139060a0a3709a32ea6d18464382d9f7d6485f`)

### `AI06-007` · Profile Version 읽기 계약

- [x] 공통 Profile Table/Flyway·내부 API 최소 계약 승인과 Revision 예약
- [x] Backend 불변 Snapshot JSON 저장·조회와 내부 API 구현·검증·`dev` 병합 (PR #15, `3c59ab10e433ed097ffd884fc08fffda9b9afb5e`)
- [x] Orchestrator 조회 Client/Provider 구현·검증·`dev` 병합 (PR #8, `29a7ae5f123b57717f2d383e8123a5e0cc89bac8`)

### `AI06-008` · Job–Snapshot 바인딩

- [x] Backend Job 생성 시 ACTIVE `LLM_OPS` Profile Version 불변 고정과 Flyway `20260830025553074` 검증
- [x] Queue/Outbox/Valkey를 `jobId` 단일 payload로 제한하고 DB 권위 Claim Context 연결
- [x] Orchestrator production Snapshot Runner, 중복·재시도·terminal replay와 안전한 ACK/NACK 경계 구현·검증
- [x] Backend PR #16 (`620f09b2032c616daec035fe393469e6092fde35`)과 Orchestrator PR #9 (`e411fbbfffa85635b9969aa1ce09c38e9d5d6248`) `dev` 병합

### `AI06-009` · Approval·Check·Guardrail Runtime

- [x] Spring 소유 승인·반려 상태 전이와 동일 Job·Profile Version·Checkpoint 재개 계약 구현
- [x] 공통 Start·Guardrail·Check·Approval·End Handler와 production Registry 연결
- [x] Backend PR #19 (`9f0b529e4e0d702b7d30c95db3e48d838097e531`)과 Orchestrator PR #10 (`8ffdace39ed91309f67759f65238ce50f3a5f324`) `dev` 병합·종료 검증

### `AI06-010` · MCP 공통 플랫폼 부트스트랩

- [x] 신규 단일 Repository·Service 생성 승인과 Work ID 범위 확정
- [x] `common` Catalog·인증과 빈 `coding`·`cms` 확장 Package, 단일 `/mcp` Service 구현
- [x] Backend 고정 Allowlist와 discovery/`tools/list` 왕복, 전체 회귀·Image 검증
- [x] MCP Server PR #1 (`e6595aeaeda5a98512004ee3252cc1b02067feec`)과 Backend PR #21 (`e736f7e8a4c87718bb0659b38591ed3c5fed1c3e`) `dev` 병합

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
| `AI06-001` | `axms-ai06-001-agent-settings-menu` | 담당 기능 MD 작업 등록 | Master | 변경 완료·PR 전 | `feature/tmdwns0531_axms-ai06-001-agent-settings-menu_v0.1` | - | - | - |
| `AI06-001` | `axms-ai06-001-agent-settings-menu` | Agent 설정 메뉴 정리 | Frontend | 구현 완료·PR 전 | `feature/tmdwns0531_axms-ai06-001-agent-settings-menu_v0.1` | - | - | - |
| `AI06-002` | `axms-ai06-002-agent-settings-workspace-mock` | Agent 설정 Workspace 목업 | Frontend | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-002-agent-settings-workspace-mock_v0.1` | `1a48debed798b1e4f7a34e164a318cb0680f1504` | [#12](https://github.com/urizo-final-org/urizo-final-frontend/pull/12) · 병합 완료 | `2f1113140bb68d4e41d90484f0bce5315913f958` |
| `AI06-003` | `axms-ai06-003-natural-profile-management-mock` | 자연어 Profile·통합 관리 목업 | Frontend | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-003-natural-profile-management-mock_v0.1` | `b481573b9edaee353e56de5764ccd19438228bbc` | [#13](https://github.com/urizo-final-org/urizo-final-frontend/pull/13) · 병합 완료 | `673974bca136b5bad1b6deb7f0a4a72684f73251` |
| `AI06-004` | `axms-ai06-004-snapshot-contract` | Versioned Snapshot 불변 모델·Loader·Validator | Orchestrator | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-004-snapshot-contract_v0.1` | `d487adc20e4fb10d416a4bef1746e04e59ed3684` | [#5](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/5) · 병합 완료 | `55e1d83416e7aa8893f180f053498a5b668e9586` |
| `AI06-005` | `axms-ai06-005-registry-graph-builder` | Node Registry·공통 Invocation/Result·Snapshot Graph Builder | Orchestrator | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-005-registry-graph-builder_v0.1` | `dd706b9623c7c7290dccd1c9b84936f454960185` | [#6](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/6) · 병합 완료 | `c35e292e950c4992e70a2fba36188e9041b3be0a` |
| `AI06-006` | `axms-ai06-006-snapshot-runner-compat` | Snapshot Runner 호환 경로 | Orchestrator | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-006-snapshot-runner-compat_v0.1` | `1faae3b96fa4c95b2be2ca0c049b54ec09e837ed` | [#7](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/7) · 병합 완료 | `8c139060a0a3709a32ea6d18464382d9f7d6485f` |
| `AI06-007` | `axms-ai06-007-profile-version-read-contract` | Profile Version 저장·내부 읽기 계약 | Backend, Orchestrator | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-007-profile-version-read-contract_v0.1` | Backend `64714e064517dffe37c277832eac917f31e6df6d` / Orchestrator `e3ebaed3b3cb9476f456feb60a917c5e87be2d4e` | Backend [#15](https://github.com/urizo-final-org/urizo-final-backend/pull/15) / Orchestrator [#8](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/8) · 병합 완료 | Backend `3c59ab10e433ed097ffd884fc08fffda9b9afb5e` / Orchestrator `29a7ae5f123b57717f2d383e8123a5e0cc89bac8` |
| `AI06-008` | `axms-ai06-008-job-snapshot-binding` | Job–Profile Version 고정·jobId Queue·production Snapshot Runner | Backend, Orchestrator | `dev` 병합 완료 | `feature/tmdwns0531_axms-ai06-008-job-snapshot-binding_v0.1` | Backend `c357a5adef49b6795306dd579620fe08f5582a29` / Orchestrator `db80060772187149634c7eff52f38332ddacf812` | Backend [#16](https://github.com/urizo-final-org/urizo-final-backend/pull/16) / Orchestrator [#9](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/9) · 병합 완료 | Backend `620f09b2032c616daec035fe393469e6092fde35` / Orchestrator `e411fbbfffa85635b9969aa1ce09c38e9d5d6248` |
| `AI06-009` | `axms-ai06-009-approval-check-guardrail-runtime` | Approval·Check·Guardrail과 Checkpoint 재개 | Backend, Orchestrator | `dev` 병합·종료 검증 완료 | 저장소별 AI06-009 Feature Branch | Backend `a6c8dcfd1461597d721ac19d2f7936906df6d935` / Orchestrator `2f34b7e1185b9466822aef9e835ec6a1d71683e4` | Backend [#19](https://github.com/urizo-final-org/urizo-final-backend/pull/19) / Orchestrator [#10](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/10) · 병합 완료 | Backend `9f0b529e4e0d702b7d30c95db3e48d838097e531` / Orchestrator `8ffdace39ed91309f67759f65238ce50f3a5f324` |
| `AI06-010` | `axms-ai06-010-mcp-common-platform-bootstrap` | 단일 MCP Service·Catalog와 Spring 왕복 | MCP Server, Backend, Master | Source `dev` 병합 완료·Master 현행화 | `feature/tmdwns0531_axms-ai06-010-mcp-common-platform-bootstrap_v0.1` | MCP `8a91fd3416c80f5d46072700abb6f23ce877481d` / Backend `b64c9e6d595a556113ece3a7988d0df057ee048d` | MCP Server [#1](https://github.com/urizo-final-org/urizo-final-mcp-server/pull/1) / Backend [#21](https://github.com/urizo-final-org/urizo-final-backend/pull/21) · 병합 완료 | MCP `e6595aeaeda5a98512004ee3252cc1b02067feec` / Backend `e736f7e8a4c87718bb0659b38591ed3c5fed1c3e` |
