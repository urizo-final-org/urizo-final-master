# 3. RAG 품질 개선

> 담당자: 민은지 (`emilyjjang-jpg`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 현재 방향

- Freshness, 수집 완전성, 필수 필드 누락률·중복률, Chunk·Embedding·Vector Sync율과
  Recall@K·Hit@K·MRR·Citation·Refusal 지표를 Version 단위로 확인한다.
- 45일은 초기 검토값이며 실제 경고 기준은 API 갱신주기와 데이터 특성에 맞게 설정한다.
- 품질 저하 가능성을 관리자 대시보드에 알리고 수집·매핑·청킹·임베딩·검색 평가 단계별 원인을 보여준다.
- 일반관리자가 재빌드를 요청하고 최고관리자가 최신 API 데이터로 Build·평가·활성화한다.
- Version 비교와 Scheduler 기반 원천 API·수집 DB·Embedding 건수 차이 확인을 검토한다.

## 담당자 검토 항목

- 지표별 계산식, 경고 임계값과 Version 비교 기준
- Scheduler 주기와 원천·수집·Embedding 건수 비교 방식
- 알림 위치, 요청·처리 상태와 Golden Question 관리 위치
- 대시보드의 최소 시연 범위

## 진행 상태

- 현재: 품질 기준·대시보드·Scheduler 방향 심층 조사
- 다음: 팀 중간점검 후 지표와 최소 완료 기준 확정

## 2026-08-30 공통 Queue·Job 계약 제안

> 제안 출처: 6번 Agent 설정 연계 협의
> 상태: 담당자 검토·확정 필요
> 범위: Agent 설정이 아니라 3번의 장시간 품질 재평가·재빌드 Job 명세에만 적용

- 품질 재평가·재빌드가 장시간 실행될 때만 기존 Product Queue의 Job Type으로 추가한다. 별도 Quality Queue를 먼저 만들지 않는다.
- Job 상태의 기준은 PostgreSQL로 두고 Valkey에는 불변 jobId만 저장한다.
- DB Job·Outbox, 멱등 처리, stateVersion, Worker Lease·Heartbeat와 시작 복구 계약을 2번 Product Job과 함께 재사용한다.
- 짧은 지표 조회와 Dashboard 조회는 동기 API로 유지하고 Queue에 넣지 않는다.
- 이 기능은 현재 Agent Node Profile의 직접 소비자가 아니다. 평가 기술과 지표 선택은 3번 담당자가 독립적으로 결정한다.

### 담당자 확인 항목

- [ ] RAG_QUALITY_BUILD 또는 RAG_REBUILD Job Type이 실제로 필요한 실행 시간·복구 조건
- [ ] 재평가와 재빌드를 같은 Job으로 묶을지 분리할지
- [ ] 실패·재시도와 Knowledge Version 활성화 차단 기준
- [ ] 기존 Product Queue·Outbox 복구 계약 재사용 여부

## 하위 작업 기록

현재는 상세 작업 분류 전이므로 비워 둔다. 새 Work ID가 승인되면 같은 PR에 포함할 구현·테스트·문서·수정을
아래처럼 한 체크리스트로 묶고, 추적표에는 저장소별 진행 상태와 Git 정보를 기록한다.

```markdown
#### `<Work ID>` · `<작업명>`
- [ ] `<같은 PR에 포함할 작업>`
```

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
