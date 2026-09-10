# 6. 오케스트레이션 제어

> 담당자: 민승준 (`tmdwns0531`)
> 현재 단계: 제품 완료 판정은 [AI Core Release Closeout](AI_CORE_RELEASE_CLOSEOUT.md)에서 관리
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.
> 주의: 아래 Work·PR·테스트 수는 과거 구현 이력이며 현재 완료 상태가 아니다.

## 기능 목표와 소유 범위

6번은 Agent 설정과 4·5번이 함께 사용하는 제한형 실행 플랫폼을 소유한다.

| 영역 | 6번 플랫폼 소유 범위 |
|---|---|
| Agent 설정 | Provider·Model, Agent·Workflow, 자연어 기능 Profile, Tool·실행 정책, 실행 모니터링, 사용량·평가 |
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

### 노드 UX Mock·스크럼 전달 기준

> 상태: 스크럼 논의용 Frontend 시각 Mock이다. Runtime·Job 계약이나 실행 범위의 변경은 아니다.

- Agent·Workflow 화면은 활성 Versioned Snapshot의 설정·편집 Canvas이고, Job별 진행 상태는 별도 실행 모니터링 화면으로 분리한다.
- 실행 모니터링은 API 연결 전까지 명시적인 Mock으로 둔다. Node 상태는 `대기`·`실행 중`·`완료`·`승인 대기`·`실패`만 사용하고, 실행 중 Node만 강조한다.
- 스크럼 논의용 화면에서는 메뉴 관리·콘텐츠 관리·템플릿 관리의 세 예시 Lane을 동시에 실행 중인 것처럼 그릴 수 있다. 이는 표시 방식의 합의용 예시일 뿐, Natural CMS Runtime의 병렬 실행·Sub-workflow 지원을 뜻하지 않는다.
- Canvas는 다크 그레이 배경과 절제된 Dot Grid, Node는 흰 카드로 유지한다. Port는 좌 입력·우 출력, Edge는 기본 중립색, 실행·오류·선택 상태만 Accent로 구분한다. Retry·Reject 우회선은 하단으로 Routing한다.
- n8n·ComfyUI·Langflow·Dify·Unreal Blueprint·Node-RED는 정보 구조와 시각 규칙의 참고 대상일 뿐이다. 외부 UI Asset·소스·상표 요소는 가져오지 않으며 이미지 제작·도입은 후순위다.
- 실제 모니터링 계약은 Natural CMS Job 의미(AI05), Runner·Checkpoint(AI06), 실행 기록(Orchestrator), 조회 API(Backend), 표시(Frontend)를 함께 합의한 뒤 별도 Work ID로 연결한다.

#### 후속 구현 작업계획·절차

1. Agent·Workflow 설정 Canvas의 다크 그레이 배경, 흰 Node, Port·Edge·우회선 규칙을 독립 Frontend Work로 처리한다.
2. 별도 실행 모니터링 화면은 메뉴 관리·콘텐츠 관리·템플릿 관리 세 Lane이 동시에 실행 중인 스크럼용 Mock으로 구현하며 실제 상태 API는 연결하지 않는다.
3. 통합 검증 Work는 Node 상태 가독성, Edge 겹침, 승인 대기·실패 표현과 Frontend Test·Typecheck·Build만 확인한다. 외부 이미지·Asset 제작은 포함하지 않는다.
4. Source 구현은 Work ID 승인과 팀원 `PLAN PASS` 후 독립 Worktree에서 시작한다. Canvas와 Monitoring Mock이 같은 파일을 수정하면 병렬화하지 않고 팀장이 순서를 정하며, 통합 검증은 두 Work 뒤에 수행한다.
5. 실제 Job·현재 Node 조회 API와 Runtime 연결은 Mock 검토 이후 AI05·AI06·Backend·Orchestrator·Frontend가 합의하는 별도 Work ID로 둔다.

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
- `AI06-034`에서는 Prompt·Completion·Source·Diff·Tool I/O·전체 LangGraph State 원문을 전송하지 않는다.
- 표준 자동평가와 Score 생성은 `AI06-035`, 서비스별 평가 보정은 `AI06-036`으로 순차 분리한다.

### Langfuse 공유 관측·보안 계약

- 관측 대상은 Langfuse Cloud Hobby의 Japan Region(`https://jp.cloud.langfuse.com`) 한 Project와
  `environment=local`로 고정한다. Self-host와 별도 Pipeline Node는 만들지 않는다.
- Runtime의 Trace 전송은 비동기·`fail-open`이다. Langfuse 지연·오류·할당량 초과나 전송 실패가 Job 실행,
  Domain 상태, Approval, Checkpoint와 CMS 반영의 성공·실패를 바꾸거나 재시도를 유발해서는 안 된다.
- Langfuse Public/Secret Key와 Host는 환경변수로만 주입한다. Key 값은 Source, Profile Snapshot, DB,
  Trace metadata, Prompt, 로그와 문서에 저장하지 않는다.
- Trace 이름은 `axms.job`으로 고정한다. Observation 이름은 `axms.node`, `axms.model`, `axms.tool`,
  `axms.check`만 사용한다. Profile·Job·Node·Operation 식별자를 이름에 넣지 않으며 Approval·Guardrail은
  별도 Observation 종류를 만들지 않고 Node 종류·상태로 표현한다.
- 허용 metadata는 `jobId`, `traceId`, `profileVersionId`, `nodeId`, Node 종류·상태, `attempt`,
  Provider·Model, 입력·출력 Token, 지연시간, 오류 Code, Tool·Check 상태로 닫는다. 관측 시각은 원문
  Payload가 아닌 플랫폼이 생성한 UTC Timestamp만 사용한다. 이 목록 밖의 값은 전송하지 않는다.
- Prompt·System Prompt·사용자 입력, Source·Diff·Patch·파일 내용·경로, Tool 인자·출력, CMS Resource의
  제목·본문·명령·Preview, 개인정보, Credential·Token·Cookie·Authorization Header, 환경변수 값,
  Prompt·Completion·전체 LangGraph State, 원문 오류 Message·Stack Trace는 전송하지 않는다. 허용 여부가
  불명확한 값은 전송하지 않는다.
- 관리자 사용량·평가 조회는 같은 Langfuse Project와 `environment=local`에서 Metrics v2,
  Observations v2, Scores v3를 사용한다. 세 조회는 같은 UTC 기간, Filter, Aggregation, Model Pricing 설정과
  Sampling 정책을 적용하며, Sampling된 결과는 전체 모집단으로 환산하지 않는다.
- Metrics v2는 사용량·Token·비용·지연시간 집계, Observations v2는 Trace·Node·Model·Tool·Check 관측 조회,
  Scores v3는 이미 저장된 Score 조회에만 사용한다. CMS는 응답을 표시할 뿐 비용·Token·Score를 재계산하거나
  서로 다른 기간·Filter의 결과를 합치지 않는다.
- Spring AI의 실제 Provider 호출 Observation과 W3C Trace Context 연결은 `AI06-034`에서 처리한다.
  Provider별 Token·비용 보정, Evaluator 실행과 Score 생성·Pipeline Gate는 포함하지 않으며 현재 계약은
  Score를 만들거나 기존 Job 완료 조건을 바꾸지 않는다.

### CMS `실행 모니터링`·`사용량·평가` 정보 구조

`Agent 설정`의 `실행 모니터링`과 `사용량·평가`는 동급 1차 Tab으로 분리한다. 나머지 설정 Tab은 유지한다.

| 1차 Tab | 표시 기준 | 연결 Work |
|---|---|---|
| `실행 모니터링` | 활성 LLM Ops·Natural CMS Job의 읽기 전용 Node 흐름·현재 상태와 우측 상세 Panel | `AI06-037` |
| `사용량·평가` | Node·Provider·품질 계측을 기간·Job 기준으로 상세 조회 | `AI06-034`·`AI06-035`, 필요 시 `AI06-036` |

`사용량·평가`는 다음 세 하위 Tab을 유지하며 AI06-037에서 재구현하지 않는다.

| 하위 Tab | 표시 기준 | 연결 Work |
|---|---|---|
| `Node 계측` | Job·Node·Tool·Check 실행 상태, Attempt와 지연시간 | `AI06-034` |
| `Provider 계측` | 실제 Provider·Model 호출 수, Token·지연시간과 Langfuse가 제공하는 비용 | `AI06-034` |
| `품질 평가` | 동일 Job·Trace·Node 단위의 034 실행 계측과 035 Score·평가 근거를 함께 표시 | `AI06-034`+`AI06-035` |

- `품질 평가`의 실행 계측과 평가 근거는 동등한 행 단위로 연결하며 별도 근거 Tab을 만들지 않는다.
- `실행 모니터링`은 Job이 고정한 `profileVersionId`의 Snapshot과 저장된 Layout을 편집 기능 없이 재사용한다.
  LLM Ops와 Natural CMS의 활성 Job을 구분하고, 동시에 여러 Job이 있으면 자동으로 하나를 추측하지 않고 선택 목록을 제공한다.
- Node 상태는 `대기`, `진행 중`, `승인 대기`, `완료`, `실패`로 표시한다. `진행 중`은 움직이는 강조선,
  `승인 대기`는 노랑, `완료`는 초록, `실패`는 빨강으로 구분해 실행과 오류를 같은 색으로 표현하지 않는다.
- 각 Node에는 `N`(Node 상태·Attempt·지연시간), `P`(실제 Provider·Model·Token·비용),
  `Q`(품질 Score·근거·보완 필요) 상태 칩만 간략히 표시하고, 선택하면 우측 상세 Panel을 연다.
  Provider를 호출하지 않은 Node와 Node에 귀속되지 않은 Trace 전체 Score를 임의로 Node에 붙이지 않는다.
- 정확한 현재 Node는 Langfuse 조회 결과가 아니라 Spring 소유 Monitoring Read Model을 기준으로 한다.
  Orchestrator는 허용된 식별자·상태만 Node 시작·종료·승인 대기·실패 전이로 전달하고 업무 Payload 원문은 보내지 않는다.
- `DRAFT`·`ACTIVE` Profile Snapshot은 Node·Edge·Config·Model·Tool Binding을 가진 불변 실행 설계도다.
  `Job Monitoring Snapshot`은 `jobId`와 고정 `profileVersionId`를 참조해 Job·Node 실행 상태를 조회 시 조합하는
  읽기 전용 응답이며 Profile Snapshot을 복제하거나 수정하지 않는다. Spring에는 복구에 필요한 Job·Node 실행 상태만 저장한다.
- Job 생성 요청은 Queue 등록과 `jobId` 응답까지 짧게 끝낸다. 원래 HTTP 응답을 Job 완료까지 열어 두지 않는다.
  Frontend는 화면이 보이고 Job이 종료되지 않은 동안 Spring의 전체 `Job Monitoring Snapshot`을 1초 간격으로 조회한다.
  응답에는 기존 `stateVersion`, 별도 `monitorRevision`, `updatedAt`, 현재 Node와 Node occurrence 상태를 포함해 짧은 Node도 복구한다.
  기존 승인·Job의 `stateVersion` 의미와 증가 조건은 변경하지 않는다. 중복·역순 응답은 현재 상태를 되돌리지 않되 유효한 늦은 완료 이력은 보존한다.
  완료·실패뿐 아니라 기존 Domain의 종료 판정에 따라 Polling을 중단한다. Job 전환·Tab 이탈·백그라운드에서는 요청을 취소하고 복귀 시 즉시 조회한다.
  이 1초 Polling 대상은 Spring Monitoring API뿐이다. Langfuse Metrics·Observations·Scores는 Tab 진입, Job·Node 선택,
  `monitorRevision` 변경 후 필요한 상세 갱신 또는 수동 새로고침 시 Spring의 제한된 Cache를 통해 조회하며 매초 원격 호출하지 않는다.
  P 상세는 선택 Job·Node에 한정한 034 조회를 사용한다. 최근 기간 50건을 Frontend에서 임의로 매칭하지 않으며 Q는 035 전까지 `평가 미설정`이다.
  화면의 진행 시간은 `startedAt`을 기준으로 Frontend에서 표시하되 서버 실행 상태나 계측값을 추정·재계산하지 않는다.
  SSE·WebSocket과 Job 요청 장기 대기는 사용하지 않는다.
- Langfuse Node·Provider·품질 값은 관측 지연이나 `fail-open`으로 늦거나 없을 수 있으므로 마지막 갱신 시각과
  `관측 대기`·`관측 연결 안 됨` 상태를 표시하고, 이 값으로 Spring Job 상태를 덮어쓰지 않는다.
  오래된 갱신 시각만으로 장애를 추정하지 않고 확인된 조회·관측 오류만 구분한다. 새 Heartbeat는 추가하지 않는다.
- `사용량·평가`는 향후 브라우저 인쇄 기반 PDF 보고서로 확장할 수 있는 고정 Section 구조만 유지한다.
  PDF 생성·다운로드 기능은 `AI06-037`에 포함하지 않고 별도 Work로 승인한다.

- `품질 평가`는 Provider 자체의 절대 품질이 아니라 Provider·Model이 해당 Profile·질문·근거 Context에서 만든
  응답 결과의 품질이다. Provider·Model별 비교는 가능하지만 Workflow와 평가 Context를 함께 표시한다.
- `품질 평가` 상단의 `현재 에이전트 모델`은 활성 Profile Version을 기준으로 Agent·Node별 Primary·Fallback
  Provider·Model과 `profileVersionId`를 표시한다. 이는 설정값이며 실제 호출 결과로 표현하지 않는다.
- 각 Score에는 해당 Trace에서 실제 호출된 Provider·Model을 `실제 평가 모델`로 표시한다. Fallback이 실행됐거나
  활성 Profile이 바뀐 경우에도 현재 설정 모델과 과거 실행 모델을 합치지 않고 각각 보여준다.
- `AI06-034`에서는 `Node 계측`과 `Provider 계측`을 연결하고 `품질 평가`는 `평가 미설정`으로 둔다.
- `AI06-035`에서 표준 Score를 `품질 평가`에 표시하고, `AI06-036`에서 같은 Tab 안에 `보완지점` 영역을 추가한다.
- `보완지점`은 별도 네 번째 하위 Tab이 아니다. 낮은 평가 항목, 근거 부족, 사람 평가와의 불일치처럼 실제
  보정이 필요한 지점과 검토 상태를 시각화하며 근거가 부족하면 개선안을 추측하지 않고 `판단 근거 부족`으로 표시한다.
- Frontend와 Spring은 세 영역의 값을 합산해 임의 종합점수를 만들지 않는다.

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

## 현재 하위 작업 기록

### `AI06-041` · 사용량·평가 Job 검색·페이지 이동

- 상태: 2026-09-10 사용자 승인 후 Source 구현·독립 검토·최신 `dev` 통합 검증과 Backend·Frontend `dev` 병합을 완료했다. UI Runtime 반영은 별도 승인 전이다. Work slug는 `axms-ai06-041-observability-job-pagination`이다.
- 범위: 전체 Job UUID 정확 검색과 기존 UTC 기간 조건, Node·Provider Observation의 서버 측 필터와 커서 기반 이전/다음 페이지 이동을 제공한다. 조건·하위 Tab 변경 시 첫 페이지로 돌아가며 Provider 집계에도 같은 Job 조건을 적용한다. 집계는 현재 페이지가 아닌 선택 기간 전체 기준이다.
- 저장소: Backend·Frontend 및 이 작업 기록만 포함한다. 각 저장소의 최신 `origin/dev` 기반 `feature/tmdwns0531_axms-ai06-041-observability-job-pagination_v0.1` 독립 Worktree를 사용했다. AI06-040·AI04-019는 `dev` 병합 후 통합했으며 미커밋 변경을 가져오지 않았다.
- 보존: `environment=local`, 최고관리자 전용 읽기, 닫힌 metadata·응답 Allowlist, bounded Cache와 원문 차단을 유지한다. DB·Flyway·Job 실행·상태·Runner·품질 평가·Score 생성과 Runtime 재시작은 제외한다.
- 검증 범위: Job·기간·관측 종류·커서별 조회/Cache 격리, 잘못된 입력·권한 거부, 페이지 마지막·역순 응답·조건 초기화, 기존 회귀와 타입 검사·빌드를 확인했다. Push·PR·Merge Gate는 승인 범위로 통과했으며 새 UI Runtime 반영은 미실행이다.
- 검증 결과: 초기 Backend 관련 5개 Test Class 30/30 및 Frontend 389/389 PASS, 독립 Backend 4개 Class 28/28 PASS다. 최종 최신 `dev` 통합 후 Backend 전체 869건 중 864 PASS·DB/live opt-in 5 SKIP·실패/오류 0, Frontend 전체 35개 파일 406/406 PASS 및 TypeScript·Vite Build PASS다. Frontend 최초 타입 검사에서 새 테스트의 잘못된 `exact` 옵션을 제거한 뒤 재검증했다. 기존 VersionTable key 경고와 Bundle 크기 경고는 이 범위에서 수정하지 않았다.
- 병합 근거: [Backend #89](https://github.com/urizo-final-org/urizo-final-backend/pull/89) (`258f46f777561b7c64b73bab90e99dc5410a4f63`), [Frontend #59](https://github.com/urizo-final-org/urizo-final-frontend/pull/59) (`7ab4c2cbee29023afff80ebedcf165901eb491d6`)가 `dev`에 MERGED이며 각 PR Head의 `origin/dev` ancestry를 확인했다. 필수 리뷰 예외 admin Merge는 현재 사용자 승인으로 수행했다.
- 실측 경계: 승인된 Japan Observations 읽기에서 기존 Job의 동일 UTC 기간·Node 종류 필터를 유지한 2건씩 두 페이지가 HTTP 200, Job 일치·중복 없음·마지막 커서 없음으로 확인됐다. 새 Source를 Runtime에 바인딩한 검증은 아니다. 앞선 인증서 조치 이후 기존 Backend의 선택 occurrence 조회는 AVAILABLE·오류 없음이며 Job은 WAITING_APPROVAL로 보존했다.

| Work ID | 작업 | 저장소·Branch | 현재 상태 |
|---|---|---|---|
| `AI06-022` | Node Canvas 시각 Mock | Frontend · `feature/tmdwns0531_axms-ai06-022-node-canvas-visual-mock_v0.1` | Frontend PR #23으로 `dev` 병합 완료 (`9122880b36fad7f8a44a54f240883909f09350da`) |
| `AI06-023` | Node 실행 모니터링 스크럼 Mock | Frontend · `feature/tmdwns0531_axms-ai06-023-node-monitoring-scrum-mock_v0.1` | API 미연결 정적 Mock과 Dirty Worktree를 참고 자료로 보존, 실제 기능으로 승격하지 않음 |
| `AI06-026` | LLM_OPS PR·배포 Profile v4 | Master, Frontend, Backend, Orchestrator · `feature/tmdwns0531_axms-ai06-026-llm-ops-pr-deploy-profile_v0.1` | 구현·Source 검증 완료, 최신 dev 반영·Push·PR 대기 |
| `AI06-028` | Profile별 기본 템플릿 Snapshot 저장·불러오기 | Master, Frontend, Backend · `feature/tmdwns0531_axms-ai06-028-default-template-snapshots_v0.1` | [Frontend #27](https://github.com/urizo-final-org/urizo-final-frontend/pull/27)·[Backend #54](https://github.com/urizo-final-org/urizo-final-backend/pull/54) `dev` 병합 완료, Source·Flyway·로컬 통합 검증 완료 |
| `AI06-029` | 노드별 Primary·Fallback 상세 모델과 추론 설정 | Master, Frontend, Backend, Orchestrator · `feature/tmdwns0531_axms-ai06-029-node-model-settings_v0.1` | [Frontend #28](https://github.com/urizo-final-org/urizo-final-frontend/pull/28)·[Backend #55](https://github.com/urizo-final-org/urizo-final-backend/pull/55)·[Orchestrator #21](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/21) `dev` 병합 완료, Source 독립·실제 Provider 검증 완료 |
| `AI06-030` | Model Catalog 현행화·기본 Model 전환·Tool 정책 최소 UI | Master, Frontend, Backend · `feature/tmdwns0531_axms-ai06-030-model-catalog-tool-policy-ui_v0.1` | [Frontend #30](https://github.com/urizo-final-org/urizo-final-frontend/pull/30)·[Backend #57](https://github.com/urizo-final-org/urizo-final-backend/pull/57) `dev` 병합 완료, Source·Flyway 독립 검증 완료 |
| `AI06-034` | Langfuse 횡단 Trace·사용량·관측 화면 | Master·Backend·Orchestrator·Frontend · `feature/tmdwns0531_axms-ai06-034-langfuse-observability_v0.1`, Backend Preview 보완 `feature/tmdwns0531_axms-ai06-034-portable-coding-preview_v0.3` | [Backend #62](https://github.com/urizo-final-org/urizo-final-backend/pull/62)·[#63](https://github.com/urizo-final-org/urizo-final-backend/pull/63)·[#65](https://github.com/urizo-final-org/urizo-final-backend/pull/65)·[Orchestrator #24](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/24)·[Frontend #38](https://github.com/urizo-final-org/urizo-final-frontend/pull/38) `dev` 병합 완료, 횡단 Trace·원문 차단·관리자 화면과 이식 가능한 Coding Preview 검증 통과 |
| `AI06-035` | Langfuse 표준 자동평가와 Score 생성 | Master·Backend·Orchestrator·Frontend · `feature/tmdwns0531_axms-ai06-035-safe-evaluation-scores_v0.1` | 후순위, 기존 작업 보존; `AI06-037` 구현·검증과 사용자 화면 확인 후 재개 |
| `AI06-036` | AX Module Studio 평가 보정·신뢰도 검증 | Master · `feature/tmdwns0531_axms-ai06-036-evaluator-calibration_v0.1` 예정, Source 보완은 결과 확인 후 별도 승인 | 후속 Work ID·선행조건 확정, `AI06-035` 평가 표본 확보 전 시작 금지 |
| `AI06-037` | 승인 범위 정합화·Migration 예약 | Master · `feature/tmdwns0531_axms-ai06-037-active-job-node-monitoring_v0.1` | 승인 계약·예약·후보·로컬 통합 검증 기록, 전체 `PARTIAL / NOT VERIFIED`; Push·PR·병합 없음 |
| `AI06-037` | Monitoring 저장·조회·선택 Job/Node 계측 | Backend · `feature/tmdwns0531_axms-ai06-037-active-job-node-monitoring_v0.1` | 후보 `f2d9a786`; Timestamp·실제 JDBC·3차 full·Natural CMS 계측·Coding v10 범위 승인 대기까지 Monitoring PASS; Push·PR·병합 없음 |
| `AI06-037` | 원문 없는 Node 전이 보고·복구 연결 | Orchestrator · `feature/tmdwns0531_axms-ai06-037-active-job-node-monitoring_v0.1` | 후보 `4de6c33`; Natural CMS 승인 대기 5 occurrence·Coding 범위 승인 대기 4 occurrence·선택 Node 귀속 PASS; Push·PR·병합 없음 |
| `AI06-037` | 실행 모니터링·우측 상세 Panel | Frontend · `feature/tmdwns0531_axms-ai06-037-active-job-node-monitoring_v0.1` | 후보 `b79f327`; Natural CMS v2·Coding v10 Canvas·N/P/Q 및 실제 terminal Polling 중단 PASS, 최종 사용자 확인·live hidden/restore 미완료; Push·PR·병합 없음 |

### 단계적 Work 실행 계약

1. `AI06-034`의 횡단 Trace·관측 기반을 Source 검증하고 저장소별 `dev` 병합까지 확인한다.
2. 완료된 `AI06-034` 다음은 `AI06-037` 계획·구현·독립 검증이다. 035·036 완료를 선행조건으로 두지 않는다.
3. `AI06-037`의 최종 사용자 화면 확인 뒤 `AI06-035`를 재개한다. 그 전에는 Q를 `평가 미설정`으로 표시한다.
4. `AI06-036`은 필요할 때만 `AI06-035`의 비교 가능한 평가·사람 검토 표본을 근거로 진행한다.
5. 후속 Work를 앞 Work의 Branch에 선행 구현하지 않는다. 각 Work 시작 시 범위·저장소·세션·완료 조건을 다시 보고한다.

### `AI06-034` · Langfuse 횡단 Trace·사용량·관측 화면

- 상태: 완료(2026-09-07, v0.3 Preview 보완 포함). 아래 Source 후보에서 관측·보안·화면 검증을 통과했고 GitHub와 `origin/dev`에서 병합을 확인했다.
- 범위: LangGraph의 Job·Node·Tool·Check Span, Python→Spring W3C `traceparent`, Spring AI 실제 Provider 호출
  Observation을 같은 Trace로 연결한다. Python의 사후 `modelObservations` 기반 Model Span은 제거한다.
- 관리자 표시: 기존 `사용량·평가` Tab의 `Node 계측`·`Provider 계측` 하위 Tab에 Metrics v2·Observations v2를
  같은 UTC 기간·Filter로 조회해 추가 계산 없이 표시한다. `품질 평가`는 `평가 미설정` 상태만 표시한다.
- 보안: `environment=local`, 비동기 `fail-open`, 폐쇄형 metadata Allowlist·원문 Denylist를 유지한다.
- 제외: Evaluator·Score 생성, 서비스별 보정, DB·Flyway, Self-host, 별도 OTel Collector, 기존 Job 완료 조건 변경.
- 시작 조건: 수정된 최종 작업계획 승인과 재사용 세션의 `PLAN PASS`·`SIMPLE PASS`·`GUARDRAIL PASS`, 기존 Dirty
  변경 보존, 저장소별 최신 `origin/dev` 포함 확인을 먼저 완료한다.
- 재개 보완: 기존 Backend·Orchestrator 작업의 사후 `modelObservations` 생성·수집 경로를 그대로 완료로 보지 않는다.
  기존 Worktree를 보존한 채 Spring AI 실제 Provider Observation과 W3C Trace 연결 계약으로 교정하고, 후보 Commit 이후
  최신 `origin/dev` 포함 여부를 다시 확인한다. 자동 Reset·Rebase·충돌 해결은 하지 않는다.
- 완료 조건: 같은 `jobId`·Trace에서 LangGraph Node와 실제 Provider 호출이 조회되고, `Node 계측`·`Provider 계측` 화면이
  같은 UTC 기간·Filter의 Langfuse 값을 재계산 없이 표시하며, Allowlist·Denylist·`fail-open`과 단위·계약 검증을 통과하고
  영향 저장소의 `dev` 병합을 확인해야 한다.

| 저장소 | PR·상태 | 최종 Push·검증 SHA | `dev` 병합 SHA |
|---|---|---|---|
| Backend | [#62](https://github.com/urizo-final-org/urizo-final-backend/pull/62)·[#63](https://github.com/urizo-final-org/urizo-final-backend/pull/63)·[#65](https://github.com/urizo-final-org/urizo-final-backend/pull/65), 2026-09-06~07 생성·병합 | `b038656c38acaa3bb6f367f9ee067784333c9220`·`e713fad2b79669d44d058c7e22361685956ae993`·`2a31626bd5fef2f17184bbb713a05a93e9e7b996` | `64baf100900823596bc0a54d45da01d56b333f7d`·`f821714991eeaae82d9450db074f0761f79d9f0e`·`c074f7032ea315ad2838e9225ee37c272ac97ef1` |
| Orchestrator | [#24](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/24), 2026-09-06 생성·병합 | `cdf690d5375ca12f4a3911f45c53ad73dae0de3b` | `4ca60892ff6cf91fdbd5a05bab32a1fadd6ce9c3` |
| Frontend | [#38](https://github.com/urizo-final-org/urizo-final-frontend/pull/38), 2026-09-06 생성·병합 | `f8bdb00b0a602e29020ea5f8371405e8d979f77d` | `ba11b29b6df46bd544ba8f9fa7a5e518345e6741` |

- 검증: Backend 전체 702개 중 698 통과·4 skip, 최종 Console 보완 33/33 및 독립 33/33 통과.
  Orchestrator 최종 219개 중 217 통과·2 skip, Frontend 246개·타입 검사·Build 및 최종 표시 보완 35개 통과.
- v0.2 보완: Backend 전체 708개 중 704 통과·4 skip, Runner·HTTP timeout 대상 7/7을 통과했다. 실제 DB의
  read-only predicate에서 종료 Job의 잔여 `CREATE_WORKTREE`는 선택 대상 0건이었고 task 원본은 변경하지 않았다.
- v0.3 Preview 보완: Backend Job의 Preview BUILD가 canonical Frontend checkout에서 Frontend image를 함께 만들고,
  PREVIEW_UP도 같은 Source를 read-only mount하도록 고정했다. Backend 전체 727개 중 723 통과·4 skip, Preview image 3종
  build와 격리 Runtime health, `/`·`/admin`·`/api/site/context`·`/nginx-health` 200을 확인했다. AI04·AI05 업무 로직,
  Orchestrator·LangGraph Core·Snapshot과 DB Schema는 변경하지 않았다.
- 통합: 고정 후보 조합의 공식 `full`에서 상시 서비스 9개 healthy, Flyway exit 0·pending 0을 확인했다.
  신규 Migration은 없으며 추가 전체 실행 없이 기존 통합 증거로 종료한다.
- 실제 관측: Coding `7e79edb0-ce31-4361-98c1-b79c9e493c09`와 Natural CMS `3b48e350-02a9-494c-9707-04ce085ac030`에서
  Node와 실제 Spring AI generation 부모 연결, Token·비용·지연시간의 관리자 표시를 확인했다.
  세 신규 Trace의 input/output은 null이고 검증용 원문 표식은 전송되지 않았다.
- 검증 한계·보존: Coding은 analyze의 infeasible 결과로 정상 완료돼 승인 이후 업무 흐름은 검증하지 않았다.
  Natural CMS는 preview valid·decision null의 `WAITING_APPROVAL`을 보존했다. v0.2에서도 신규 Coding E2E·runner·intake는
  실행하지 않았고 AI04·AI05 업무 판단·승인·저장 의미와 Orchestrator·LangGraph Core·Snapshot을 변경하지 않았다.
  잔여 Runner task `e220d3be-7c9d-4f8e-9f2e-5857d4b9c391`은 `CREATE_WORKTREE / PENDING / attempt 0`, lease 없음으로 보존했다.
  v0.2 predicate가 이 task를 제외함을 read-only로 확인했으며 LangGraph checkpoint 4개 테이블의 행 수는 검증 전후 동일했다.
  v0.3은 새 Coding intake를 만들지 않고 기존 격리 Preview Volume에서 Flyway validate/info와 화면 기동만 재검증했다.

### `AI06-035` · Langfuse 표준 자동평가와 Score 생성

- 상태: 후순위다. 기존 미완료 작업을 보존하고 `AI06-037` 구현·검증과 사용자 화면 확인 전 재개하지 않는다.
- 범위: 비식별·승인된 평가용 입력·출력·근거 Context·기대 결과를 Langfuse 내장 LLM-as-a-Judge·RAGAS 계열
  평가기에 연결하고 `correctness`, `faithfulness`, `relevance`, `instruction_following` Score를 생성한다.
- 관리자 표시: 기존 `사용량·평가` Tab의 `품질 평가` 하위 Tab 상단에 활성 Profile Version 기준 Agent별
  Primary·Fallback Provider·Model을 표시한다. 각 Score에는 해당 Trace의 실제 평가 Provider·Model·Profile과
  평가 근거 유무를 별도로 표시하며 `Node 계측`·`Provider 계측` 화면 구조는 변경하지 않는다.
- 결정적 항목: `task_success`, `tests_passed`, `schema_valid`처럼 실행 결과로 판정 가능한 값만 우리 시스템에서
  Boolean·Numeric Score로 전달한다. Spring과 Frontend는 Score를 재계산하지 않는다.
- 제외: 임의 종합 `quality` 점수, 서비스별 Rubric·임계값 보정, Production 원문 전송, Pipeline Gate 적용.
- 시작 조건: `AI06-034` 완료와 `AI06-037` 사용자 화면 확인 후 별도 작업계획 승인을 받는다.
- 완료 조건: 네 표준 Score가 생성·조회되고 Trace 전체 Score와 Node·Observation 귀속 Score를 구분해 표시하며,
  활성 Profile의 설정 모델과 실제 평가 모델을 분리하고 비식별 평가 Payload·근거 상태·실패 격리를 검증해야 한다.

### `AI06-036` · AX Module Studio 평가 보정·신뢰도 검증

- 상태: 범위와 Work ID만 확정한 시작 대기 상태다. `AI06-035` 평가 표본 확보 전 구현하지 않는다.
- 범위: 대표 사례의 사람 판정과 자동 Score를 비교해 Rubric·임계값·오탐·미탐을 보정하고 결과를 문서화한다.
  `품질 평가` 하위 Tab에는 낮은 평가 항목·근거 부족·사람 평가 불일치와 검토 상태를 묶은 `보완지점` 영역을
  별도로 시각화한다.
- 제외: 새로운 평가 엔진 자체 개발, Langfuse Score 규격 변경, 근거 없는 종합점수 생성.
- 시작 조건: `AI06-035`에서 비교 가능한 Score 표본이 확보된 뒤 영향 Source와 검증 기준을 별도 승인받는다.
- 완료 조건: 대표 표본에서 사람 판정과 자동 Score의 일치·불일치 근거, 오탐·미탐, 적용 가능한 Rubric·임계값을 문서화하고
  근거 부족을 포함한 `보완지점` 표시 계약을 확정해야 한다. Source 보완은 이 결과와 별도 승인을 받은 경우에만 진행한다.

### `AI06-037` · 활성 Job 실행 모니터링

- 상태: 2026-09-08 Timestamp 보완·실제 JDBC·독립 회귀·3차 full 및 Natural CMS v2·Coding v10 실제 Job의 승인 대기까지 자동 보고·저장 좌표 Canvas·선택 Node N/P/Q 상세는 PASS다. 격리 DB 검증과 별도 승인된 Coding 검증 Job 취소 후 실제 terminal Polling 중단도 PASS다. 최종 사용자 확인과 live hidden/restore 검증이 남아 전체 `PARTIAL / NOT VERIFIED`다. Coding 계획·구현·PR 이후 흐름의 완료를 뜻하지 않는다.
- Work slug: `axms-ai06-037-active-job-node-monitoring`. 기존 035·Mock·Dirty Worktree는 보존하고 구현 기반으로 사용하지 않는다.
- 하위 작업 · Windows Coding Runner 자동 시작·실행 안내·성공 표시 보완 (2026-09-08 사용자 편입·자동 실행 구현 및 dev 병합 승인, Source 병합·격리 회귀 PASS·실제 자동 기동 NOT VERIFIED): 별도 AI06-039 제안을 철회하고 기존 AI06-037 Work ID·work slug·Backend PR 범위에 묶는다. 보류된 AI06-038 컨테이너화 안은 포함하지 않는다.
  최소 범위는 공식 Windows `full` 시작과 healthy 재사용 경로의 Runner 자동 실행, 동일 바인딩 프로세스 재사용·수동/자동 중복 claim 방지, 실제 Coding Runtime 토큰 마운트 경로·명시적 WorkRoot 전달, 최초 정상 poll 확인과 실패 표시, Backend README 안내와 MCP workspace 성공 표시 보완이다. `spring-core`, Windows 로그인 서비스/예약 작업, Coding 업무 계약·DB·LangGraph 구조는 변경하지 않는다. LLM DevOps 경고는 Frontend `runner-status` → Spring `CodingRunnerService.lastSeenAt` → `runner.ps1`의 인증된 poll 연결로 확인했다.
  이 보완 구간은 단일 Backend의 `SINGLE TRACK`으로 인계받은 팀장 세션이 직접 구현·검증하며 새 하위 세션은 만들지 않는다. 후속 사용자 승인으로 이 세션이 037 본체를 포함한 최신 dev 통합·저장소별 PR 병합·로컬 재시작 확인을 수행했다. 기존 전체 세션 배정과 미완료 화면 검증 범위는 유지한다.
  기존 `.worktrees/ai06-037-be`의 `README.md`, `scripts/runner.ps1`, `scripts/start-cms-local.ps1`, `scripts/bootstrap-dev.ps1`과 신규 `scripts/start-coding-runner.ps1`, `scripts/verify-runner-startup.ps1`, `scripts/verify-runner-powershell-compatibility.ps1`을 보완했다. PowerShell 5.1.19041.6456과 7.6.5 각각 자동 시작 20/20 및 기존 표시·경로 회귀 7/7 PASS다. 실제 숨김 Windows 프로세스는 가짜 토큰·빈 응답 전용 임시 loopback 서버에서 시작·동일 PID 재사용·수동 중복 claim 전 차단까지 확인했다. 실패/미확인 프로세스 보존, 최초 poll 미확인 재시도 차단, healthy/full 호출, spring-core 제외, 실행 승인, 시작 실패의 DB bootstrap 전이 차단도 검증했다. 5.1과 자동 실행의 ExecutionPolicy Bypass는 자식 프로세스에만 적용하고 영구 설정은 바꾸지 않는다.
  최초 격리 회귀 단계에서는 제품 Runner claim·Job 생성·DB/Volume 변경·full/Flyway 없이 검증했다. 후속 승인에 따른 dev 통합·병합·공식 full 실행 결과는 아래 2026-09-08 병합 후 검증 기록으로 갱신한다. 실제 LLM DevOps 배너 해제·팀원 PC 실행·전체 Coding 흐름은 아직 NOT VERIFIED다.
- 2026-09-08 병합 후 검증: [Backend #74](https://github.com/urizo-final-org/urizo-final-backend/pull/74) `9826e9ce452a0f834d4e21c809547397face7343`, [Frontend #46](https://github.com/urizo-final-org/urizo-final-frontend/pull/46) `bd2ad30068a557bc5c802c70b9e8d61bb61457db`, [Orchestrator #27](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/27) `b24ad7d7d79b3880a1a9e840da69206d96289bcd`를 dev에 병합하고 각각 검증 Head의 origin/dev ancestry와 Source 내용 일치를 확인했다.
  통합 후보 Backend 관련 22/22, Orchestrator 227개 중 225 PASS·2 skip, Windows PowerShell 5.1/7 각각 Runner 27/27 PASS다. Frontend 최초 전체 병렬 검증은 311개 중 비동기 UI 2 FAIL, 전체 단일 worker 재실행은 311/311 PASS이며 TypeScript·Vite build도 PASS다. 초기 간헐 실패 이력은 보존한다.
  별도 승인한 격리 DB에서 빈 DB 36개 적용, 당시 origin/dev `340ce9f82d1a2f1b671fca5d3f17b636ec7d5b6f`의 35개에서 후보 36개로 업그레이드, 반복 변경 0건·단일 성공 history·소유권·권한·DDL 거부 42501을 확인했다. 성공 후 이번 테스트 전용 컨테이너·볼륨·네트워크만 소유권 재검증 후 삭제했다.
  공식 `full -Rebuild`는 깨끗한 기존 037 Master/Backend/Frontend/Orchestrator와 MCP `1b35750bc2887f39eb5c7dd43b4f09bf818ea40a`를 명시해 실행했다. 전체 이미지 빌드는 성공했으나 로컬 DB의 기존 누락 Revision `20260907033400506`에 대해 `Detected resolved migration not applied to database`로 Flyway exit 1이 발생했다. 이미 더 높은 순번 두 개가 적용됐고 해당 knowledge_activation_request 테이블도 없음을 읽기 전용 확인했다. DB·checkpoint 컨테이너와 역할 동기화는 공식 경로에서 실행됐으며 기존 볼륨은 보존했다. 상시 서비스 9개는 healthy지만 이전 애플리케이션 컨테이너이며 새 이미지 재기동·Runner 자동 시작 단계에는 도달하지 않았다. 실제 Runner 프로세스는 0개다.
  현재 상태는 Source dev 병합 완료 / 로컬 재기동 PARTIAL / Runner 실제 자동 기동 NOT VERIFIED다. 검증 무시·outOfOrder 활성화·Repair/Clean·history 수정·기존 DB 초기화·제품 Runner 수동 시작·추가 Job은 실행하지 않았다. 기존 Master의 미추적 bristleworm과 런타임 연결 Worktree를 보존한다. 누락된 기존 dev Revision의 로컬 적용 방식은 별도 승인 후 진행한다.
- 범위: 별도 1차 Tab `실행 모니터링`에서 LLM Ops·Natural CMS 활성 Job의 고정 Snapshot·Layout, 현재 Node와
  `N`·`P`·`Q` 칩, Node 선택 우측 상세 Panel을 제공한다. 기존 설정 Canvas의 시각 규칙을 재사용하되 편집기는 변경하지 않는다.
- 저장·보고: Spring에 Job Monitoring 상태와 Node occurrence를 저장하고 기존 `stateVersion`과 별도 `monitorRevision`을 사용한다.
  Orchestrator의 최소 전이 보고는 Langfuse 활성화와 독립되며, 보고 실패가 원래 Handler·Job 결과를 변경하지 않는다.
- 실시간 계약: Job 생성 API는 `jobId`를 즉시 반환한다. Frontend는 보이는 화면의 종료되지 않은 Job에 한해 Spring
  `Job Monitoring Snapshot` 전체를 1초 간격으로 조회하고, 완료·실패·백그라운드 전환 시 중단한다.
  원래 Job 요청 장기 대기, SSE와 WebSocket은 사용하지 않는다.
- 상태 기준: Spring Monitoring Read Model이 현재 Node·Job 상태의 기준이다. Langfuse는 Node·Provider·품질 계측만
  제공하며 관측 지연·미연결을 Job 실행 실패나 완료로 해석하지 않는다.
- 제외: Canvas 편집, Job 제어·승인 기능 중복, `사용량·평가` 재구현, 임의 종합점수, PDF, 새 평가 엔진과 기존 Job 완료 조건 변경.
- 시작 조건: 완료된 034 위에서 승인된 세션의 PLAN·SIMPLE·GUARDRAIL 확인 후 상태 계약 → 화면 → 독립 검증 순서로 진행한다.
  공용 MD 경량화와 병행하되 미검증 로더·Hook을 혼합 적용하지 않고 실제 충돌 파일·규칙만 재확인한다.
- 완료 조건: LLM Ops·Natural CMS 활성 Job을 선택해 불변 Profile Snapshot 기반 읽기 전용 Canvas를 열고, Spring 전체 상태
  Snapshot의 1초 Polling·중단·복귀·종료와 짧은 Node 복구를 검증해야 한다. Node별 적용 가능한 `N`·`P`·`Q` 칩과 상세 Panel,
  관측 지연 상태를 표시하되 Profile을 수정하지 않고 Langfuse를 1초 주기로 직접 조회하지 않아야 한다.
  독립 검증 뒤 사용자가 최종 화면을 확인해야 하며 그 전에는 035·036으로 진행하지 않는다.

- 이번 구현 결과: Spring의 전체 Node 최신 상태와 제한된 occurrence 이력을 분리했고, 유효한 늦은 과거 보고는 현재 포인터를 유지하며 `monitorRevision`만 증가시킨다.
  독립 검증에서 발견한 상충 terminal 보고 결함은 동일 상태일 때만 관측 ID 보완을 허용하는 조건과 회귀 3건으로 수정했다.
  실제 PostgreSQL 검증에서 추가 확인한 거절된 보고의 State Trace·revision 누출은 저장된 occurrence Trace만 전달하도록 보완했다. 양방향 terminal 충돌 무효와 정상 Trace 보완을 실제 SQL 롤백 및 독립 회귀 7/7로 확인했다.
  P는 정확한 occurrence metadata·Trace·기간·환경으로 유일한 Node 앵커를 최대 2건 조회한 뒤 직접 자식만 최대 50건 조회한다. 전체 Trace 스캔·추가 Pagination은 없다.
- Source 검증: 직전 Backend 후보 전체 758개 중 754 PASS·DB opt-in 4 skip. 최종 Timestamp 보완 후보는 Monitoring 관련 12/12 및 독립 회귀 7/7 PASS다.
  Orchestrator는 기존 고정 Runtime 이미지의 네트워크 차단·읽기 전용 Source mount에서 전체 227개 중 225 PASS·2 skip, 독립 핵심 30/30 PASS.
  Frontend의 이전 고정 이미지 검증은 Node 24.14.0·pnpm 11.9.0에서 Vitest 48/48·app/node TypeScript PASS였다. 2026-09-08 남은 검증 재실행에서 47 PASS·비동기 P 배지 1 FAIL이 있었고 해당 단독 재실행과 독립 단독 검증은 각각 PASS, TypeScript 둘은 PASS였다. 상세 표시를 기다린 뒤 후속 배지 render를 즉시 검사하는 테스트 경합 가능성을 기록했다. 이후 사용자가 하위 세션 감독 검증을 승인해 같은 고정 이미지·network none으로 담당 1회와 독립 검증 1회를 각각 실행했고, 모두 관련 3파일 48/48·app/node TypeScript PASS·exit 0이었다. 이번에는 실패가 재현되지 않아 Source/test 수정이나 추가 반복은 하지 않았다. 이전 47/1 이력은 보존하며 간헐 실패가 영구 해소됐다고 주장하지 않는다. 임시 의존성 Junction은 제거했다.
- 로컬 통합: 공식 `full -Rebuild` 최초 1회와 Source 결함 보완 후 재검증 1회, 사용자 예외 승인된 Timestamp 보완 재검증 1회로 총 3회를 수행했다. 최종 상시 서비스 9개 healthy, Flyway exit 0·pending 0·35개 Migration validate 및 재실행 추가 적용 없음이다.
  실제 PostgreSQL의 Production SQL을 `ai_workspace` 권한으로 실행해 Trace 보완·상충 terminal 무효·늦은 이력의 현재 포인터 보존·revision 증가를 확인하고 전부 롤백했다. Runtime의 app Schema CREATE 권한 없음과 검증 행 0건도 확인했다.
  Monitoring 목록 API 200·빈 화면 표시를 확인했다. 기존 Job 수, 대기 Runner 5건의 attempt 0·Lease 없음, Queue 6개 길이 0을 유지했고 DB 초기화·Volume 삭제·기존 대기 작업 소비는 하지 않았다.
- 검증 한계·다음 Gate: Natural CMS v2와 Coding v10의 승인 대기까지 Monitoring·선택 Node 귀속·저장 좌표 Canvas·상세를 확인했다. 격리 DB와 실제 terminal 전이 후 Polling 중단도 검증했다. 최종 사용자 화면 확인과 실제 document.hidden 중 abort·복귀 즉시 조회는 미완료다. 아래는 승인·실행 순서에 따른 이력이며, 이전 Coding 보류와 대기열 보존 경계는 후속 명시 승인 및 실행 결과로 갱신됐다.
  2026-09-08 실제 Job 각 1건 검증 승인 후 Natural CMS `a2db2645-92fe-4747-802d-3704f6537d01`은 미리보기 승인 대기에 도달했으나 Monitoring 행은 0건이었다. Production SQL의 `CASE WHEN ... THEN ? ELSE NULL` Timestamp 바인딩을 실제 PostgreSQL JDBC 42.7.3으로 재현한 결과 `SQLSTATE 42804` (`started_at`: timestamptz에 text 식 전달)로 실패했고 전부 롤백했다. 앞선 타입 명시 SQL 검증의 누락 경계다. 사용자 승인으로 기존 담당·독립 검증 세션에서 Timestamp 최소 보완 후 실제 JDBC 회귀 검증과 예외적 3차 full 1회를 진행한다.
  Coding은 Runner `alive=false`·`lastSeenAt=null`로 새 Job 생성을 보류했다. Runner의 claim은 오래된 PENDING부터 처리하며 taskId 제한이 없어 기존 대기 5건을 보존하는 조건으로 시작하지 않았다. 생성한 Natural CMS Job의 적용·승인·재실행 및 기존 대기 작업 소비는 하지 않았다.
  Timestamp 보완은 CASE 네 곳의 `CAST(? AS TIMESTAMPTZ)`와 회귀 테스트, Backend 2파일만 변경했다. 실제 PGJDBC 42.7.3의 `setTimestamp`로 네 상태 시각·Trace 보완·양방향 terminal 충돌 무효·늦은 이력의 포인터 보존·롤백 잔여 0건을 포함한 10개 assertion을 통과했다.
  3차 full 직후 목록 API 200·0건은 성공 근거로 삼지 않았다. 이후 사용자 승인으로 추가 Natural CMS Job `f4c1e6c4-cd0c-4891-9976-e77c2fed267b`를 정확히 1건 생성했다. Trace `1d33ed76-3606-4d54-a4d0-d29ec3c68c43`, 고정 Profile v1 `b59a56f7-fa8d-4234-8a8e-df93905de7be`에서 analyze·preview 각 1회 후 `WAITING_APPROVAL`, Monitoring state 1행·occurrence 5행·revision 10을 확인했다. 선택 analyze·preview 계측은 각각 AVAILABLE·SPAN/GENERATION 2건이며 Job/Node 귀속 및 실제 Provider·model·token·latency를 확인했다.
  화면은 새 Job·approval N 상세·Q 평가 미설정을 표시했으나 Profile v1 Layout 조회가 404 `PROFILE_EDITOR_LAYOUT_NOT_FOUND`이고 해당 DB 행도 0건이어서 Canvas는 표시하지 못했다. 기존 Workflow 편집기의 구버전 deterministic auto-layout fallback과 달리 Monitoring은 Layout 실패 시 Canvas 렌더링을 막는다. Profile·Layout 데이터 수정 없이 기존 배치 규칙을 읽기 전용 화면에 재사용하는 최소 보완은 별도 승인 전 진행하지 않는다.
  추가 검증 후 Natural CMS 총 11건·Coding 총 10건, 이전·신규 검증 Job 모두 승인 대기, 콘텐츠 2번 제목 `비전` 및 기존 Runner PENDING 5건의 attempt 0·Lease 없음이 유지됐다. CMS 적용·미리보기 승인·기존 대기 작업 소비·추가 Source 수정·재기동은 하지 않았다.
  사용자는 삭제를 보류하고 LLM Ops v10 유지·Natural CMS 새 버전 저장/활성화 후 Job 1건 검증을 승인했다. 기존 편집기로 v2 `46f62a39-3fb0-4825-896b-c19a6d6eaf99`와 좌표 8개를 저장했다. Node·Edge·config·allowedTools·guardrail은 동일하지만 현행 정규화에 따른 모델 selections 명시, preview Gemini 추론 `NONE → MINIMAL`, Node별 required 도구 정책 적용을 확인해 활성화 전에 별도 설명했다. 사용자가 이 현행 규칙 변환을 수용한 뒤 Backend 활성화 검증을 통과해 Natural CMS v2 ACTIVE·v1 INACTIVE로 전환했다. LLM Ops v10 ACTIVE는 유지했다.
  v2 Job `1d835bc3-dadf-4a66-937b-999a8cfa9f74`를 정확히 1건 생성했다. Trace `d4fbfceb-0284-445c-b8a8-4ffb1b3fe602`, analyze·preview 각 1회·유효 미리보기·`WAITING_APPROVAL`, occurrence 5개·revision 10 및 저장 좌표 조회 200·8개를 확인했다. 실제 브라우저에서 Job을 명시 선택해 Node 8개 Canvas와 승인 대기 N·Q 평가 미설정을 확인하고 analyze·preview 선택 P 상세를 API와 대조했다. analyze는 OpenAI `gpt-5.4-nano-2026-03-17` 265/13 token·2310ms, preview는 Google `gemini-3.5-flash-lite` 332/41 token·870ms로 각 AVAILABLE·SPAN/GENERATION 2건이다. Natural CMS 총 12건·Coding 10건, 세 검증 Job의 승인 대기·콘텐츠 2번 제목 `비전`·기존 Runner PENDING 5건 attempt 0·Lease 없음은 보존했다. Source 수정·재기동·CMS 반영·버전 삭제는 하지 않았다. 좌표 없는 v1 화면 한계는 그대로이며, 구버전 정리·삭제 기능은 이력 참조를 보존하는 별도 후속 계획 대상이다.
  기존 세션을 재사용한 남은 검증에서 실제 Job 전환·복귀와 Canvas 상세를 확인했다. 팀장은 기존 Nginx 접근 로그에서 v2 Snapshot의 약 1초 간격 조회, 화면 내 탭 이탈 `2026-09-08T00:59:59Z`부터 `01:01:09Z`까지 약 70초 조회 0건, 복귀 후 명시적 Job 재선택 시 `01:02:00Z`부터 조회 재개(01:02:36Z 확인 시 35건)를 대조했다. 이는 화면 내 탭 unmount/재선택 검증이며 브라우저 `document.hidden`·진행 중 요청 abort·실제 terminal 전이 후 중단 실측과는 구분한다. 해당 수명주기·stale 방지는 코드/단위 계약 PASS, 남은 live 경계는 `NOT VERIFIED`다.
  후속 Frontend 감독 검증에서는 v2 Snapshot GET의 visible 기준선 `01:53:45~01:54:00Z` 매초 HTTP 200을 확인했다. 문서화된 CUA 동작으로 새 visible 탭을 연 뒤에도 `01:54:19~01:54:55Z` 같은 GET 37건이 계속됐다. 이 관측만으로 원래 문서의 실제 `document.hidden=true` 전환이나 제품 hidden 동작의 정상·결함을 입증할 수 없으므로 hidden 중단·복귀 즉시성과 실제 terminal 중단은 계속 `NOT VERIFIED`다. 동일 UI 방법 반복·eval/CDP 우회·새 도구 추가·기존 Job 상태 변경은 하지 않았고 임시 탭은 정리했다. 담당 결과와 독립 검증의 증거 범위를 대조했으며 Source·Runtime·DB·Job 변경은 없다.
  Runtime 담당은 taskId 선택 인자가 없는 claim과 `RunOnce`의 동일 경로를 확인해 Coding 실행을 보류했다. 후속 코드 대조에서 종료된 Job(`COMPLETED`·`FAILED`·`CANCELLED`·`EXPIRED`)의 `CREATE_WORKTREE` 작업은 claim에서 제외됨을 명시했다. 따라서 PENDING 5건을 모두 실행 대상이라고 단정하지 않으며, 각 작업의 종류·연결 Job 상태에 따른 실제 eligible 건수는 별도 확인 대상이다. `dbeaver_reader`의 `BEGIN READ ONLY`·5초 timeout 조회는 `coding_runner_task` SELECT 권한 부족으로 exit 1, 행 출력 없이 종료돼 현재 5건 분류는 `NOT VERIFIED`다. 새 조회 View·Migration 추가 제안은 Simple 범위를 넘어 채택하지 않았다. 기존 `ai_workspace`에는 해당 테이블 SELECT 권한이 선언돼 있으나 계정 전환 조회·권한 변경·Runner 실행은 하지 않았다.
  후속 사용자 승인으로 기존 `ai_workspace`의 `REPEATABLE READ READ ONLY`·5초 timeout 메타데이터 조회 1회를 실행해 `transaction_read_only=on`, exit 0을 확인했다. PENDING 총 5건 중 `e220d3be-7c9d-4f8e-9f2e-5857d4b9c391`의 `CREATE_WORKTREE`는 연결 Job `COMPLETED`로 claim 제외, 나머지 4건은 `PREPARE_SCAN_WORKTREE`로 claim eligible이다. 전부 attempt 0·Lease 없음이며, 4건은 workspaceId 기준 Coding Job 연결이 없다는 것만 확인했다(작업의 무효·폐기 가능성을 뜻하지 않음). 현재 대기열 기준 가장 오래된 eligible은 `a6d027c0-4444-4c6a-82ec-41860c3d6a76`이다. 메타데이터 분류는 PASS지만 이 4건의 처리·보존 결정 없이 Runner를 시작하지 않는다. 원문 Payload·Secret 출력, 권한/Schema/Job/Queue 변경, claim API 호출은 없으며 Coding 실행은 계속 `NOT VERIFIED`다.
  실제 terminal 검증을 위한 Natural CMS 거절 경로도 코드만 확인했다. 현재 거절은 pipeline attempt를 증가시키고 outbox 재개 및 discard의 retry 경로를 유발할 수 있으므로 단순 즉시 종료 수단으로 간주하지 않는다. 기존 승인 대기 Job의 결정·미리보기·콘텐츠는 변경하지 않았다. 브라우저 숨김 실측은 사용자 최소화/복귀 동작을 요청했으나 아직 완료 응답이 없어 미확인이며, `02:11:20~02:19:29Z` 조회 478건에 3초 초과 공백이 없었다는 로그만으로 숨김 동작의 성공·실패를 판단하지 않는다.
  격리 DB 계획은 새 전용 Container/Volume/Network, 기존 secret의 읽기 전용 mount, loopback 동적 포트에서 빈 DB 후보 head 35개·정확한 origin/dev head `20260907072549518` 34개에서 후보로 upgrade·반복 실행·권한 검증을 수행하는 것이며, 계획 단계에는 실행하지 않고 별도 승인을 받았다.
  2026-09-08 10:26~10:27 KST 사용자 승인 후 격리 검증 1회를 실행해 exit 0을 확인했다. 빈 DB 35개 적용·반복 이력 불변, 정확한 dev head `20260907072549518` 34개에서 후보 `20260907084859068` 35개로 upgrade·반복 이력 불변, 두 DB의 History·Table·Index·소유권·Grant 검증을 통과했다. 두 Runtime CREATE TABLE 시도는 실제 `permission denied`·SQLSTATE `42501`로 거부됐고 Probe Table 부재를 확인했다. 하위 실행 요청은 승인 문맥 부재로 프로세스 생성 전 차단돼 0회로 종료했으며, 직접 사용자 승인이 보이는 팀장이 동일 검토 Script의 실행 승인을 받아 1회 수행했다. 전용 Container `axms-ai06-037-pg-62df39229868`·Volume `axms-ai06-037-pgdata-62df39229868`·Network `axms-ai06-037-net-62df39229868`는 생성 ID·소유권 확인 뒤 성공 조건으로만 제거했다. 별도 읽기 전용 재조회에서 세 자원 부재와 기존 공유 서비스 9개 healthy를 확인했다. 기존 DB·Source·Job·Queue·Runner·Profile·공유 Runtime은 변경하지 않았으며 추가 검증 실행 승인은 소진됐다.
  독립 검증 세션은 격리 DB를 재실행하지 않고 실행 기록과 고정 후보·검증 Script를 대조했으며, 직접 읽기 전용 조회로 정확한 세 자원 부재·기존 9개 서비스 healthy·세 Source 후보 clean을 확인해 `DB PASS`로 판정했다.
  2026-09-08 12:46~13:00 KST 후속 승인으로 기존 독립 Guardrail Scan 4건을 공식 Runner RunOnce 4회로 정상 처리했다. 전부 SUCCEEDED·attempt 1·Lease 없음이며 종료 Job의 제외 CREATE_WORKTREE 1건은 PENDING·attempt 0으로 보존했다. Scan Worktree는 로컬 origin/dev 기준으로 준비해 보존했다. 이어 ACTIVE LLM_OPS v10 `b40ad7b6-8bfe-4e37-bbc3-f9e04cad6547`의 새 Coding Job `6d5369e8-eac9-43e4-95e6-af4ea513cdf1`을 정상 API로 정확히 1건 생성했다(Trace `823c230c-bd71-4da5-8b80-10540b07fdbd`). 필요한 intake scan·Job workspace도 RunOnce 각 1회로 성공해 총 6회이며, 추가 Job·승인·구현·Source 수정·full/Flyway·Push/PR/병합은 없다.
  독립 DB·실제 화면 대조에서 Coding 총 11건, 새 Job stateVersion 3·WAITING_APPROVAL, Monitoring revision 8과 start·guardrail·analyze 완료 및 scope_approval 대기 4 occurrence, 고정 Snapshot Node 15개·저장 좌표 15개·Canvas 상태가 일치했다. analyze N/P/Q는 완료·연결됨·평가 미설정이며 OpenAI `gpt-5.4-nano-2026-03-17` 691/326 token·4024ms를 확인했다. 범위 승인 N 상세도 일치했다. 분석 후 범위 승인 대기까지의 Monitoring PASS이며 계획·코드·리뷰·PR·배포 실행 PASS가 아니다.
  잔여 관측: 최초 자동 Job 선택 시 상세가 비었다가 다른 Job 선택 후 복귀하자 표시된 1회 현상은 지속 결함으로 확정하지 않았다. 마지막 Runner는 DB 성공·실제 clean workspace 생성 후 콘솔에서 결과 보고 실패 HTTP 0을 출력했다. 결과 메시지 분기의 누락된 services 속성 접근이 StrictMode 예외로 같은 catch에 잡히는 것을 메모리 내 재현해 확인했으며, 성공 Task를 재실행하거나 범위 밖 Runner Source를 수정하지 않았다. 브라우저 hidden/restore와 사용자 최종 화면 확인은 계속 남는다.
  2026-09-08 13:26 KST 사용자가 지정 검증용 Coding Job `6d5369e8-eac9-43e4-95e6-af4ea513cdf1`의 정식 취소를 별도 승인했다. 정상 cancel API 단 1회가 HTTP 200, `CANCELLED / stateVersion 4 / finishedAt 2026-09-08T04:26:35.692852Z`로 완료됐고 Monitoring revision 8·occurrence 4건과 기존 Natural CMS 2건의 승인 대기는 독립 DB 조회로 보존 확인했다. 같은 모니터링 화면에서 취소 전 매초 GET 200, `04:26:36Z` 마지막 terminal 응답 수신 및 CANCELLED 표시 후 `04:26:37~04:27:55Z` 약 79초 동안 GET 0건을 확인해 실제 terminal Polling 중단 PASS로 판정했다. 관측 중 탭·Job 전환이나 새로고침은 없었다. Job 이력·작업공간 삭제, 신규 Job·Runner·Source 수정·full/Flyway·Push/PR/병합은 하지 않았다.
  최종 Source 후보는 Frontend `b79f32749abf8189d2dd1888b74fe09084f29d5d`, Backend `f2d9a786343eeeedf6172b1bb093a1170bcc61ee`, Orchestrator `4de6c335704ec46e671d67d39a6d0b573d449875`다. 3차 통합 실행의 Master는 `270d6d4e1f0784836d9127ab08e2c13229924700`, 변경 없는 MCP Server는 `5c4de948e254348ddfe1f0b78095262f53b8cbb7`다.
  승인된 3차 full 1회는 완료했으며 추가 실행은 별도 승인 대상이다. Push·PR·병합은 없다.
  기존 035 Dirty 작업을 보존하고 사용자 화면 확인 전 재개하지 않는다.

### `AI06-026` · LLM_OPS PR·배포 Profile v4

- [x] 기존 v3 Snapshot 호환을 보존한 v4/new UUID/17-node 기본 Profile 갱신
- [x] `pr_request → GITHUB approval → pr_complete → deploy_request → DEPLOY approval → dev_merge_check` 및 제한된 `not_merged` 반복 검증
- [x] Frontend starter/catalog, Backend local seed fixture, Orchestrator default/fixture/test를 동일 Snapshot으로 동기화
- [x] NATURAL_CMS·MCP Catalog·공통 Runner/Graph Builder·`common.end` 무변경 확인

### `AI06-028` · Profile별 기본 템플릿 Snapshot

- [x] `LLM_OPS`와 `NATURAL_CMS`를 `profileKey`로 분리한 기본 템플릿 계약 확정
- [x] 기존 Profile Authoring Snapshot 구조를 재사용하고 DRAFT·ACTIVE Version 불변 유지
- [x] 최신 dev 기준 LLM_OPS PR·배포 흐름과 NATURAL_CMS 흐름을 초기 기본값으로 확정
- [x] Backend 저장·조회 API와 Frontend 저장·불러오기 UI 구현·회귀 검증
- [x] Flyway `20260903145703043`와 공식 `full -Rebuild` 1회 통합 검증: 전체 Health 정상, pending 0
- [x] Frontend `bd99387`·Backend `8732b66`·Orchestrator `c05b38f`·MCP `ddf775f` 조합에서 Profile별 API 저장·조회·분리, 401/403/400 거부, 화면 불러오기 검증
- [x] 초기 기본값 LLM_OPS 17-node/24-edge·NATURAL_CMS 8-node/11-edge 확인, 기존 Profile Version 12개 전체 행 해시 불변 확인
- [x] 후속 UI: 확인 모달·저장본 되돌리기·작업별 툴바·노드 추가 명칭·저장 버튼 가독성 정리. Frontend `bb84c67` 기준 89개 테스트·타입 검사·Vite 빌드 통과
- [x] PR 전 Frontend Watch 종료·`bb84c67` 이미지 재빌드·전체 Health 통과, 실행 파일 해시 일치. Backend·DB·Flyway 재실행 없음
- [x] Frontend `d7c21fb`·Backend `0a4e7c1` 병합 Commit과 최신 `origin/dev` 포함 확인. 모델설정건 `AI06-029`는 별도 최종 계획 승인 및 구현 Gate를 유지
- 미검증: 별도 빈 DB 마이그레이션은 실행하지 않았으며 기존 공유 DB·공식 반복 실행만 검증했다.

### `AI06-029` · 노드별 상세 모델·추론 설정

- [x] 등록된 Credential Provider의 허용 Model Catalog를 Primary·Fallback 선택 흐름에 연결
- [x] 기존 `contractVersion: 1.0`과 문자열 Binding 호환을 보존하며 노드별 Provider·Model·추론 설정 저장·검증
- [x] Spring Model Gateway의 GPT·Claude·Gemini 지원 옵션 전달과 Fallback 순서·실제 Target 중복 검증
- [x] Frontend 기본 템플릿·DRAFT 저장·불러오기에서 설정 유실 방지, 구버전 작성 경로의 조용한 삭제 금지
- [x] Python LangGraph는 Provider·Credential을 소유하지 않고 Snapshot 불변성·Digest·Checkpoint 호환만 검증
- [x] AI04·AI05 Prompt·Handler 업무 로직·Approval·Result Port·상태 전이·Tool 실행 무변경 회귀
- [x] Frontend PR #28 (`b28ab94c075f854ccd9c8f3d68d33e9e0b4a30db`)·Backend PR #55 (`1c8492828965485e3af872b94d2f7ac126a2889b`)·Orchestrator PR #21 (`6db4c88bfec1daf49233b578873f43dff4ff7f8b`) `dev` 병합 및 최신 `origin/dev` 포함 확인
- 검증: Backend 전체 543건(4건 Skip) 및 독립 관련 86건, Frontend 30건·Typecheck·Build, Python Snapshot·Checkpoint 53건 통과. 프로세스 전용 truststore로 세 Credential의 `VERIFIED`를 확인하고 OpenAI `gpt-5.6-terra`와 Google `gemini-3.5-flash-lite` 실제 호출을 통과했다. Anthropic `claude-haiku-4-5-20251001`은 인증·모델·thinking 옵션을 수락해 `COMPLETED` 응답을 반환했으나 최소 Prompt의 정확한 `OK` 일치 검증은 실패했다. 공유 Runtime·DB·Flyway는 변경하지 않았다.

### `AI06-030` · Model Catalog·기본 Model·Tool 정책 최소 UI

- [x] Google `gemini-3.7-flash`·`gemini-3.6-flash`·`gemini-3.5-flash-lite`, Anthropic `claude-opus-5`·`claude-sonnet-5`·`claude-haiku-4-5-20251001`을 실제 Provider·Model ID로 Catalog에 등록
- [x] Gemini별 추론 단계와 기본값을 분리하고, Opus 5·Sonnet 5는 Spring AI 1.1.8의 수동 adaptive 표현 한계 때문에 thinking 필드를 덮어쓰지 않는 Provider 기본 경로로 고정
- [x] LLM_OPS 3개 Agent와 NATURAL_CMS 2개 Agent의 신규 기본 템플릿을 `google-genai-gemini-3-6-flash`·`MEDIUM`·빈 Fallback·완전한 selection metadata로 전환
- [x] 새 기본 템플릿·DRAFT 저장은 실제 Catalog selectionId와 사용 중 selection metadata만 저장하며, 기존 Profile Version과 legacy alias 해석은 유지
- [x] Workflow의 중복 `Profile 허용 도구` 섹션을 제거하고 `Tool·실행 정책` 탭에 등록된 13개 MCP Tool의 Profile별 허용 상한·필수/선택 실행 의미를 읽기 전용으로 표시
- [x] Flyway `20260903234407711` 예약·DML 작성, 빈 DB head·직전 revision upgrade·반복 migrate·history/guard 검증 통과
- [x] Frontend PR #30 (`b2519f7e4659075b8e981212e5e5bca0e61a29b7`)·Backend PR #57 (`ef87a6533eaf38174679801a7696429dac6609f2`) `dev` 병합 및 각 최신 `origin/dev`에 Source Commit 포함 확인
- 검증: Backend 전체 558건(4건 Skip), 관련 계약 23건, Spring AI Adapter 16건, Frontend 전체 99건과 Typecheck·Vite Build 통과. 실제 Provider 호출·제품 Runtime 재빌드·Volume 삭제·제품 DB Migration은 수행하지 않았다. 공식 Flyway 검증기의 역할 동기화 선행 단계가 PostgreSQL·DB gateway Container를 재생성했으며 기존 `axms-spring-dev-core-db` Volume 보존과 두 Container Health 정상은 확인했다.
- 범위 제외: Node Canvas 원형 MCP 배치, Node 카드·Handler/Runner Badge·잠금 표현·한글 Edge 시각 재설계는 후속 `AI06-031`로 분리한다.

## 과거 진행 기록

- 당시 상태: AI06-010 단일 MCP 플랫폼 부트스트랩을 MCP Server PR #1과 Backend PR #21로 `dev` 병합했다.
- 완료 범위: 기존 Approval·Checkpoint Runtime을 유지하면서 신규 `urizo-final-mcp-server`, 빈 생산 Catalog, 고정 Tool 이름 Allowlist, 서비스 토큰 인증과 Spring의 조건부 discovery/`tools/list` Client를 추가했다.
- 다음 게이트: 실제 Coding·CMS Tool Handler와 기존 CodingToolService 전환은 AI04/AI05 담당 범위다. AI06 공통 플랫폼은 새 Handler·Tool·DB 계약을 선행 확장하지 않는다.

## 과거 하위 작업 기록

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

### `AXMS-TLP-001` · 팀장 세션 프로토콜

- [x] `@팀장` 승인형 세션 전환과 `[팀장]`·`[작업]`·`[검증]` 역할 규칙 확정
- [x] GPT·Claude 공통 모델 프로필과 경량 PLAN·STRUCTURE 확인 기준 확정
- [x] AI Core 개인 기능 문서 구조 계약과 Codex Skill·문서 fallback 연결
- [ ] Master PR 생성·`dev` 병합 및 팀원 전체 Git 최신화 확인

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
| `AXMS-TLP-001` | `axms-tlp-001-team-lead-protocol` | 팀장 세션 프로토콜·AI Core 문서 구조 계약 | Master | 문서·검증 완료·PR 전 | `feature/tmdwns0531_team-lead-protocol-v0.1` | - | - | - |
