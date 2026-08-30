# 2. 도메인·RAG 교체

> 담당자: 민은지 (`emilyjjang-jpg`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 현재 방향

- 최고관리자가 공공데이터 API URL, 인증 Key, 요청 Parameter와 응답 매핑을 등록한다.
- RAG 교체는 파싱, 정제, 의미 기반 청킹, 임베딩, Vector 적재와 검색 평가 순서로 진행한다.
- 최고관리자가 Build 결과를 확인해 새 Knowledge Version을 활성화하거나 이전 Version으로 복구한다.
- 사용자 페이지의 챗봇과 통합검색은 활성화된 Version만 사용한다.
- Version별 데이터와 결과를 관리하며 비활성 Version을 사용자 검색에 사용하지 않는다.

## 담당자 검토 항목

- 지원할 공공데이터 API 범위와 응답 매핑 방식
- 인증 Key 보관과 갱신 방식
- 의미 기반 청킹 기준과 Build 실패·재시도 처리
- Version 비교·활성화·복구의 최소 사용자 흐름

## 진행 상태

- 현재: 기능 범위와 구현 방향 심층 조사
- 다음: 팀 중간점검 후 사용자 흐름·계약·최소 완료 기준 확정

## 2026-08-30 공통 Queue·Job 계약 제안

> 제안 출처: 6번 Agent 설정 연계 협의
> 상태: 담당자 검토·확정 필요
> 범위: Agent 설정이 아니라 2번의 비동기 Queue·Job 명세에만 적용

- Product Queue는 하나의 Lane으로 유지하고 Connector 동기화와 Knowledge Build를 서로 다른 Job Type으로 구분할지 검토한다.
- Job 상태의 기준은 PostgreSQL로 두고 Valkey에는 Job 전체 데이터가 아니라 불변 `jobId`만 저장한다.
- DB Job과 Outbox, 멱등 처리, `stateVersion`, Worker Lease·Heartbeat와 시작 시 `QUEUED` Job 복구를 공통 계약으로 재사용한다.
- Connector Sync와 Knowledge Build를 항상 별도 Job으로 나누는 것은 확정하지 않는다. 사용자 요청·재시도·활성화 경계를 담당자가 정한 뒤 가장 작은 Job Type만 둔다.
- 이 기능은 현재 Agent Node Profile의 직접 소비자가 아니다. 향후 Agent 실행이 실제 요구될 때만 6번 Profile 계약을 별도 협의한다.

### 담당자 확인 항목

- [ ] `CONNECTOR_SYNC`, `KNOWLEDGE_BUILD` Job Type 분리 필요 여부
- [ ] Job별 입력·완료·실패·재시도 기준
- [ ] Build 성공과 Knowledge Version 활성화의 분리 여부
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
