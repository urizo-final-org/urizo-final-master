# 4. 제한형 LLM DevOps

> 담당자: 장차윤 (`jcy644542`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 확정된 상위 흐름

```text
자연어 요청
→ Agent 1 요구사항 분석·코딩 가능 영역 검증
→ 일반관리자 승인
→ Agent 2 코딩
→ Agent 3 코드 리뷰
→ 일반관리자 승인
→ Agent 3 PR 요청
→ 최고관리자 승인 후 배포
```

- 요구사항 분석, 코딩, 코드 리뷰의 3-Agent 구조를 사용한다.
- 최고관리자가 6번 기능에서 각 Agent 단계에 사용할 Provider·Model을 매핑한다.
- 단계의 업무 의미, 승인 역할, Job Domain 결과·실패 기준은 4번 담당자가 확정한다. 합의된 실행 순서·조건·반복·승인·반려 경로는 4번 Source에 하드코딩하지 않고 6번의 Versioned Template Snapshot에 기록한다.

## 현재 방향

- 코딩은 격리 Worktree에서 수행하고 허용된 Test, Secret Scan, Path 검증, Diff와 Preview를 남긴다.
- 최고관리자가 Repository별 쓰기 허용 경로를 관리하며 인증·Secret·Migration 등 고정 Denylist는 허용하지 않는다.
- 승인은 Candidate SHA, 적용 Policy와 Test 결과에 결합하고 Patch가 바뀌면 다시 검토한다.
- 승인·반려와 단계별 실행 결과를 관리자에게 알린다.
- PR 전 취약점 점검에 SonarQube 같은 도구를 사용할지는 담당자가 검토한다.

## 담당자 검토 항목

- 단계별 입력·출력 계약과 승인·반려 후 재개 방식
- 3-Agent 실행과 Spring Backend·Python LangGraph 책임 분리
- PathPolicy, Tool Allowlist, Test·보안 검사 최소 범위
- PR·배포 연계 방식과 실패·재시도 처리

## 진행 상태

- 현재: 3-Agent Pipeline과 Guardrail·CI/CD 방향 심층 조사
- 다음: 팀 중간점검 후 단계별 계약과 최소 완료 기준 확정

## 2026-08-30 Agent 설정 연계 제안

> 제안 출처: 6번 Agent 설정의 LLM_OPS Profile 협의
> 상태: 담당자 검토·확정 필요
> 구현 원칙: 4번은 Agent 설정 저장 구조를 직접 조회하지 않고 실행 시 고정된 Profile Snapshot만 사용

### 권장 기본 Node Template

~~~text
Start
→ 요구사항 분석 Agent
→ Approval
→ 코딩 Agent
→ 잠금 Package Allowlist Check
→ 코드 리뷰 Agent
→ 잠금 PR 전 Check
→ Diff Preview
→ Approval
→ PR 요청
→ End
~~~

- 위 순서는 LLM_OPS의 최초 기본 Template이며, 4번 담당자가 업무 의미·완료 기준·불변조건을 제안·확정하면 6번 Agent 설정이 필수 Approval·Guardrail을 포함한 Node·Edge·Config로 저장한다.
- Runtime은 Registry에 등록된 Node만 사용하고 Snapshot의 순서·연결을 활성화 전 검증한 뒤 LangGraph에 조립한다. 기존 Node의 재배치는 가능하지만 병렬·Sub-workflow·임의 반복선·사용자 정의 Node는 초기 범위에서 제외한다.
- Approval Node가 없으면 승인 완료가 아니라 APPROVAL_NOT_REQUIRED로 다음 단계에 진행한다.
- Approval Node가 있으면 LangGraph가 대기하고 Spring 상태를 통해 승인·반려 UI를 표시한다.
- Check Node는 사람이 아니라 Orchestration이 실행하며 passed/failed로 분기한다.
- Guardrail은 자동 삽입·잠금 상태로 표시하고 Spring Tool Gateway에서도 강제한다.
- 활성 Snapshot의 Node·Edge·Config가 코드 작성·리뷰 반복, Check 호출 시점, Approval 위치와 승인·반려 다음 경로의 유일한 실행 원본이다. 4번 Source에 같은 순서·분기·반복을 다시 구현하지 않는다.
- 6번 공통 Snapshot Runner가 JSON의 `handlerKey`와 Edge를 읽어 LangGraph의 `add_node`, `add_edge`, 조건부 Edge, `compile()`을 수행한다. 4번 담당자는 Graph 조립 코드를 기능별로 만들지 않는다.
- 4번은 자연어 요청·Repository·Coding Job·Candidate·Attempt·승인 기록·PR 상태의 저장과 원자 Backend 기능·API, 실행 상태·Diff·Preview·승인·PR 화면, 완료 기준·불변조건을 담당한다. 이 Domain 기능은 현재 Node 작업 결과를 반환할 뿐 다음 Node를 선택하지 않는다.
- 등록된 Handler와 결과 Port 범위에서 Review 횟수, Approval 위치, 승인·반려 Edge와 Node 순서를 바꾸는 작업은 Template Version 변경으로 끝낸다. 새로운 Handler·결과 Port·Domain 부작용이 필요할 때만 4·6번 공통 계약과 Source를 함께 변경한다.

### 실행 소유 경계

| 구분 | 실행 소유 |
|---|---|
| Node가 수행할 작업 | 6번 Node Registry·Handler·Coding MCP Tool과 4번의 원자 Coding Domain API를 계약으로 연결한다. |
| 다음 Node 선택 | 6번 Snapshot Runner가 현재 Node의 `NodeResult` Port와 Snapshot Edge를 보고 결정한다. |
| 코드 리뷰 반복 | `reviewRound`, 최대 횟수와 `changes_requested` Edge를 Snapshot Config·Edge에 둔다. |
| 승인·반려 경로 | Approval의 `approved/rejected` Edge를 Snapshot에 두고 4번은 승인 역할·기록·Domain 불변조건을 담당한다. |
| Coding Job 상태 | 4번 Spring `coding`이 Job·Candidate·Attempt·Approval·PR의 원자 상태 변경과 조회를 담당한다. |
| Git 실행 | 6번 Coding MCP Tool이 영향 Repository의 Worktree·Diff·검사를 수행하고 4번은 Job·Candidate와 결과를 연결한다. |

따라서 4번은 단순 결과 화면이 아니라 Coding Job 제품을 구현한다. 다만 `if rejected then analysis` 같은 다음 단계 제어는 Backend에 두지 않고 Snapshot Edge로 실행한다.

### Coding Tool 제안

~~~text
read_file
search_code
read_diff
apply_patch
run_check
check_package_allowlist
scan_changed_files
~~~

- Approval은 사람의 제어 Node이므로 MCP Tool로 만들지 않는다.
- Check는 결정적 MCP Tool을 호출할 수 있지만 임의 Shell 명령은 허용하지 않는다.
- run_check는 정해진 Test·Typecheck·Build Profile만 실행한다.
- Diff Preview는 read_diff 결과를 화면에 표현하며 별도 git_diff Tool을 중복 추가하지 않는다.

### Coding Job·Worktree 제안

- 자연어 코딩 요청 하나를 Job 하나로 관리하고 불변 jobId를 Queue·LangGraph·Spring·MCP·승인·PR까지 전파한다.
- Job 하나가 여러 Repository를 포함할 수 있지만 Git Worktree는 Repository에 속하므로 영향 Repository별로 하나씩 만든다.
- 분석과 범위 승인 후 실제 수정이 필요한 Repository만 Worktree를 만든다.
- 초기 동시 활성 Coding Job은 1개로 제한하고 추가 요청은 Coding Queue에서 대기시킨다.
- PostgreSQL이 Job 상태의 기준이며 Valkey에는 jobId만 저장한다. 승인 대기 중에는 Worker Lease를 점유하지 않는다.
- 자율코딩 Work ID·slug·Branch는 Spring이 SYSTEM-LLMOPS-*, system-llmops-*, system/llmops-* 형식으로 발급하고 LLM이 임의로 만들지 않는다.

### 승인·반려 제안

- 승인: Preview 확인 → 승인 → Repository별 Branch Push·PR 생성 → 로컬 Worktree 폐기 → 병합 → 배포 승인·배포
- 반려: 피드백·Diff 요약 저장 → Candidate SHA 무효화 → Worktree 폐기 → pipelineAttempt 증가 → 같은 Job의 요구사항 분석으로 회귀
- 위 승인·반려 순서와 회귀 지점은 `approved/rejected` Edge와 등록된 정리 Handler로 Snapshot에 표현한다. 4번 Backend는 Candidate 무효화·Attempt 증가·승인 기록 같은 원자 Domain 기능을 제공하고 다음 Node를 직접 고르지 않는다.
- 기술 재시도는 executionAttempt, 업무 반려 재시도는 pipelineAttempt로 구분한다.
- 승인 기록에는 Repository별 Candidate SHA와 Diff를 함께 묶고 Repository별 PR은 같은 System Work ID·slug로 연결한다.
- Repository별 변경 위치·Preview 기능 테스트 화면은 4번 담당자가 최소 범위와 UI를 확정한다.

### 4번 담당자 확인 항목

- [ ] 최초 기본 Node 순서·필수 Approval 위치와 허용 가능한 Template 변경 범위
- [ ] 일반관리자·최고관리자의 승인 역할과 Domain 상태 기록 계약
- [ ] passed/failed/approved/rejected Edge 입력·출력
- [ ] Candidate SHA, Repository별 Preview·PR과 배포 완료 기준
- [ ] 반려 후 분석 회귀 횟수·종료 조건
- [ ] 6번의 LLM_OPS Profile Snapshot 계약과 일치 여부

## 하위 작업 기록

### AI04-009 · PR·dev 병합 확인·배포 Domain 완결

> Work slug: `axms-ai04-009-llm-ops-pr-deploy-domain`
> 구현 상태: Backend·Orchestrator·Master 격리 Worktree에서 팀장 검토 대기. Commit·Push·PR·실제 배포·공유 DB Migration은 아직 수행하지 않았다.

- [x] 기존 `coding.pr_request / requested`를 유지하면서 실제 PR 완료 영수증을 `coding.pr_complete / completed`로 분리했다.
- [x] v4 부작용 순서는 `pr_request → GITHUB 승인 → pr_complete → deploy_request → DEPLOY 승인 → dev_merge_check → deploy`이며, Spring Stage preflight와 결과 저장 경계가 같은 승인 subject를 각각 검사한다.
- [x] Host Runner가 승인된 MCP Workspace의 staged Diff를 승인 Candidate의 직접 자식인 재현 가능한 commit으로 만든다. PR 영수증은 `repository=backend`, `base=dev`, 발급 Branch, 승인 Candidate SHA, 생성 head SHA, PR 번호·URL을 저장하며 같은 입력의 재실행은 고정 task ID와 동일 head SHA로 기존 PR을 다시 조회한다.
- [x] `coding.dev_merge_check / merged|not_merged|blocked`를 추가했다. 정확한 repository/base/head/candidate의 열린 PR은 `not_merged`, 병합된 PR은 `merged`, 불일치·미병합 종료·권한 차단은 `blocked`로 처리한다. timeout·rate limit·5xx만 기술 재시도한다.
- [x] v4 배포 요청은 `jobId + pipelineAttempt + repository + prNumber + candidateSha + source validationHash + server target/config digest`로 고정 `deploymentRequestId`와 승인 subject hash를 만든다. merge SHA는 이 키에 포함하지 않는다.
- [x] 실제 실행 멱등 키는 `deploymentRequestId + mergeSha`로 만들고 `coding.deploy / completed|blocked` 결과를 저장한다. 결과에 호스트 포트를 공개하지 않는다.
- [x] 초기 배포 Adapter는 서버 고정 `local-docker-compose / full:backend:spring-app`만 허용한다. Host Runner가 `origin/dev`를 갱신해 승인 merge SHA 포함 여부를 확인하고, 그 SHA를 가리키는 깨끗한 전용 detached deploy Worktree만 `rebuild-local-service.ps1`의 SourceRoot로 사용한다. Snapshot·요청 payload가 Profile·Service·명령을 선택할 수 없다.
- [x] 기존 LLM_OPS v3 Snapshot과 NATURAL_CMS 계약은 변경하지 않았다. 새 Handler를 사용하는 기본 v4 Snapshot 활성화는 AI06-026 범위로 남긴다.
- [x] Flyway revision `20260903065222608`을 예약하고 결과 타입·포트·Handler·Runner kind 제약 확장 SQL을 작성했다.
- [ ] 팀장 Diff 검토 후 저장소별 Commit·Push·dev 대상 PR을 생성한다.
- [ ] 승인된 후보 조합에서 실제 GitHub·Docker·Flyway 통합 검증을 1회 수행한다.

AWS 전환 시에는 같은 `DeploymentAdapter` 계약의 구현만 교체한다. Handler 결과 타입, 승인 subject, 멱등 키와 Snapshot Port는 유지한다.

```markdown
#### `<Work ID>` · `<작업명>`
- [ ] `<같은 PR에 포함할 작업>`
```

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
| `AI04-009` | `axms-ai04-009-llm-ops-pr-deploy-domain` | PR 생성·dev 병합 확인·고정 로컬 배포 Domain | Backend | 로컬 구현·선택 테스트 완료, 검토 대기 | `feature/jcy644542_axms-ai04-009-llm-ops-pr-deploy-domain_v0.1` | 미Push | 미생성 | 해당 없음 |
| `AI04-009` | `axms-ai04-009-llm-ops-pr-deploy-domain` | Handler·Port·승인 subject 연계 | Orchestrator | 로컬 구현·선택 테스트 완료, 검토 대기 | `feature/jcy644542_axms-ai04-009-llm-ops-pr-deploy-domain_v0.1` | 미Push | 미생성 | 해당 없음 |
| `AI04-009` | `axms-ai04-009-llm-ops-pr-deploy-domain` | 담당 문서·Flyway 예약 | Master | 로컬 문서 갱신, 검토 대기 | `feature/jcy644542_axms-ai04-009-llm-ops-pr-deploy-domain_v0.1` | 미Push | 미생성 | 해당 없음 |
