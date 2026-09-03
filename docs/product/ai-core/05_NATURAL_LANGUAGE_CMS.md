# 5. 자연어 CMS 관리

> 담당자: 이재욱 (`LEEJAEWOOK1`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 현재 방향

- 일반관리자가 메뉴, 콘텐츠, 게시판과 사용자 페이지 Template을 자연어로 관리한다.
- 각 관리 화면 우측 Assistant는 현재 화면의 관리 대상만 변경할 수 있다.
- 자연어 CMS 관리는 기존 데이터·Template 관리이며 새로운 애플리케이션 기능 추가와 구분한다.
- LLM은 임의 HTML·CSS·JavaScript 대신 구조화 Draft를 만들고 기존 Renderer와 허용된
  Component·Template Variant·Design Token 범위 안에서만 변경한다.
- Schema·권한·접근성 검증과 Desktop·Mobile Preview 후 게시한다.
- 첨부 이미지 기반 Template 확장은 담당자가 범위와 Guardrail을 검토한다.

## 담당자 검토 항목

- 메뉴·콘텐츠·게시판·Template별 허용 명령과 데이터 경계
- 화면별 Assistant UI, Draft·Preview·승인 흐름
- 이미지 기반 Template 확장의 입력·출력과 안전 범위
- Version·복구와 게시 최소 범위

## 진행 상태

- 현재: 화면별 자연어 관리 범위와 Guardrail 심층 조사
- 다음: 팀 중간점검 후 사용자 흐름과 최소 완료 기준 확정

## 2026-08-30 Agent 설정 연계 제안

> 제안 출처: 6번 Agent 설정의 NATURAL_CMS Profile 협의
> 상태: 담당자 검토·확정 필요
> 구현 원칙: 일반 CMS CRUD는 기존 Spring 동기 API를 유지하고 자연어 CMS Job만 Node Profile을 사용

### 권장 기본 Node Template

~~~text
Start
→ 요청 분석 Agent
→ 구조화 명령 JSON 생성 Agent
→ CMS 대상 확인 Tool
→ 잠금 4단계 검증 Check
→ Preview 생성
→ Desktop·Mobile Preview
→ Approval
→ 잠금 재검증 Check
→ CMS 반영
→ CMS Version 게시
→ End
~~~

- LLM Ops와 같은 Python LangGraph Runtime을 사용하되 NATURAL_CMS 별도 Graph·Profile로 실행한다.
- 위 순서는 NATURAL_CMS의 최초 기본 Template이며, 5번 담당자가 Resource 규칙·업무 의미·완료 기준을 제안·확정하면 6번 Agent 설정이 필수 검증·Approval을 포함한 Node·Edge·Config로 저장한다.
- Runtime은 Registry에 등록된 Node만 사용하고 Snapshot의 순서·연결을 활성화 전 검증한 뒤 LangGraph에 조립한다. 기존 Node의 재배치는 가능하지만 병렬·Sub-workflow·임의 반복선·사용자 정의 Node는 초기 범위에서 제외한다.
- 검증은 종류, 필수 값, 전체 구조, Resource 규칙의 4단계 고정 Check로 시작한다.
- Guardrail Node는 자동 삽입·잠금 상태로 표시하고 Spring Tool Gateway에서도 강제한다.
- 활성 Snapshot의 Node·Edge·Config가 검증 순서, Preview·Approval 위치와 승인·반려 다음 경로의 유일한 실행 원본이다. 5번 Source에 같은 순서·분기·반복을 다시 구현하지 않는다.
- 6번 공통 Snapshot Runner가 JSON의 `handlerKey`와 Edge를 읽어 LangGraph의 `add_node`, `add_edge`, 조건부 Edge, `compile()`을 수행한다. 5번 담당자는 Graph 조립 코드를 기능별로 만들지 않는다.
- 5번은 Natural CMS Job·CMS Resource·Preview·승인 상태의 저장과 원자 Backend 기능·API, 실행 상태·Preview·승인 화면, Resource 규칙·게시 완료 기준을 담당한다. 6번이 CMS Handler·MCP Tool과 적용 Adapter를 제공하되 Core DB 최종 반영은 기존 Spring CMS Domain Service가 담당한다.
- 등록된 Handler와 결과 Port 범위에서 검증·Approval 위치, 승인·반려 Edge와 Node 순서를 바꾸는 작업은 Template Version 변경으로 끝낸다. 새로운 Handler·결과 Port·Domain 부작용이 필요할 때만 5·6번 공통 계약과 Source를 함께 변경한다.

### CMS Tool 제안

~~~text
resolve_cms_target
validate_cms_command
create_cms_preview
discard_cms_preview
revalidate_cms_preview
apply_cms_preview
~~~

- MCP Server는 CMS Core DB에 직접 접근하지 않는다.
- Spring이 현재 CMS Snapshot·Schema·권한 규칙을 준비하고 MCP Tool은 구조화 명령 계산·검증·Preview 결과를 반환한다.
- 승인 후 최종 DB 반영은 Spring의 기존 CMS Domain Service가 Transaction으로 수행한다.
- Agent 설정 UI에서는 하나의 MCP Catalog 아래 CMS Tree로 표시하고 NATURAL_CMS Profile에만 기본 허용한다.

### Natural CMS Job·Preview 제안

- 자연어 CMS 요청 하나를 Job 하나로 관리하고 불변 jobId를 Natural CMS Queue·LangGraph·Spring·MCP·승인까지 전파한다.
- PostgreSQL에는 Job·Attempt·승인·Preview Hash를, Valkey에는 TTL이 있는 임시 Preview Snapshot과 previewId를 저장한다.
- 승인 전에는 CMS Core DB를 변경하지 않는다. 승인 요청에는 원문 명령이 아니라 previewId만 전달한다.
- 승인 직전에 현재 CMS 상태를 다시 읽고 Preview를 재검증한다.
- 승인: 재검증 성공 → Spring CMS Domain Service 반영 → CMS Version 게시 → End
- 반려: 피드백 저장 → Preview 무효화·폐기 → pipelineAttempt 증가 → 같은 Job의 요청 분석으로 회귀
- 자연어 CMS는 Git Worktree·Candidate SHA·PR을 사용하지 않는다.

### 5번 담당자 확인 항목

- [ ] MENU, BOARD, CONTENT, TEMPLATE, CMS_COMPOSITE Resource별 구조화 명령 Schema
- [ ] 4단계 검증 규칙과 실패 사유 표시
- [ ] Preview TTL, Desktop·Mobile Preview 최소 범위
- [ ] 일반관리자·최고관리자의 승인 역할과 반려 종료 조건
- [ ] CMS Version 게시·복구 완료 기준
- [ ] 6번의 NATURAL_CMS Profile Snapshot 계약과 일치 여부

## 하위 작업 기록

#### `AI05-009` · `Orchestrator Resource Types`
- [x] Orchestrator의 MENU, BOARD, CONTENT, TEMPLATE Resource 타입 최소 계약 구현·독립 테스트 완료
- 작업자: 현재 요청에서 `tmdwns0531`으로 재배정·승인됨. 기능 문서 상단 담당자 `LEEJAEWOOK1`은 유지함.

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|---|
| AI05-009 | axms-ai05-009-orchestrator-resource-types | Master 작업 기록 | Master | 완료 | `feature/tmdwns0531_axms-ai05-009-orchestrator-resource-types_v0.1` | Push 없음 | PR 없음 | dev 병합 전 |
| AI05-009 | axms-ai05-009-orchestrator-resource-types | Orchestrator Resource 타입 최소 계약 | Orchestrator | 완료 | `feature/tmdwns0531_axms-ai05-009-orchestrator-resource-types_v0.1` | Push 없음 | PR 없음 | dev 병합 전 |

#### `AI05-010` · `Natural CMS Resource DB Contract`
- [x] Natural CMS Job·Handler Result DB CHECK가 MENU, BOARD, CONTENT, TEMPLATE을 허용하도록 확장
- [x] Flyway 회귀 테스트와 PostgreSQL 트랜잭션 적용·롤백 검증 완료
- [ ] 실제 MENU Job 통합 검증 완료
- 로컬 통합 차단: 공유 DB에 미병합 `AI06-025` Migration `20260903023350023`이 먼저 적용되어 Flyway validation이 중단됨. Repair·Ignore·DB 초기화로 우회하지 않음.
- 작업자: `tmdwns0531` (팀장)

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|---|
| AI05-010 | axms-ai05-010-natural-cms-resource-db-contract | Flyway 예약·작업 기록 | Master | 완료 | `feature/tmdwns0531_axms-ai05-010-natural-cms-resource-db-contract_v0.1` | `f19b22c` · 2026-09-03 | [Master #51](https://github.com/urizo-final-org/urizo-final-master/pull/51) · MERGED · 2026-09-03 | `93666b3` · 2026-09-03 |
| AI05-010 | axms-ai05-010-natural-cms-resource-db-contract | Natural CMS Resource DB CHECK 확장 | Backend | 완료 | `feature/tmdwns0531_axms-ai05-010-natural-cms-resource-db-contract_v0.1` | `56c2210` · 2026-09-03 | [Backend #47](https://github.com/urizo-final-org/urizo-final-backend/pull/47) · MERGED · 2026-09-03 | `071aa97` · 2026-09-03 |

#### `AI05-011` · `Natural CMS Outbox Conflict Privilege`
- [ ] Natural CMS Job Outbox 멱등 INSERT에 필요한 `event_key` 최소 조회 권한 추가
- [ ] Flyway 회귀 테스트와 PostgreSQL 권한·트랜잭션 검증
- [ ] 실제 MENU Job이 `WAITING_APPROVAL`까지 도달하고 승인 전 CMS 원본을 변경하지 않는지 확인
- 작업자: `tmdwns0531` (팀장 승인 재배정)

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|---|
| AI05-011 | axms-ai05-011-natural-cms-outbox-conflict-privilege | Flyway 예약·작업 기록 | Master | PR 검증 중 | `feature/tmdwns0531_axms-ai05-011-natural-cms-outbox-conflict-privilege_v0.1` | `924be53` · 2026-09-03 | [Master #54](https://github.com/urizo-final-org/urizo-final-master/pull/54) · OPEN · 2026-09-03 | dev 병합 전 |
| AI05-011 | axms-ai05-011-natural-cms-outbox-conflict-privilege | Natural CMS Outbox 최소 권한 보완 | Backend | PR 검증 중 | `feature/tmdwns0531_axms-ai05-011-natural-cms-outbox-conflict-privilege_v0.1` | `d43ea5f` · 2026-09-03 | [Backend #49](https://github.com/urizo-final-org/urizo-final-backend/pull/49) · OPEN · 2026-09-03 | dev 병합 전 |

새 Work ID가 승인되면 같은 PR에 포함할 구현·테스트·문서·수정을 아래처럼 한 체크리스트로 묶고,
추적표에는 저장소별 진행 상태와 Git 정보를 기록한다.

```markdown
#### `<Work ID>` · `<작업명>`
- [ ] `<같은 PR에 포함할 작업>`
```

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
