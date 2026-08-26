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
- 단계의 의미, 승인 조건, 결과와 실패 처리는 4번 담당자가 결정한다.

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

## 하위 작업 기록

현재는 상세 작업 분류 전이므로 비워 둔다. 새 Work ID가 승인되면 같은 PR에 포함할 구현·테스트·문서·수정을
아래처럼 한 체크리스트로 묶고, 추적표에는 저장소별 진행 상태와 Git 정보를 기록한다.

```markdown
#### `<Work ID>` · `<작업명>`
- [ ] `<같은 PR에 포함할 작업>`
```

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
