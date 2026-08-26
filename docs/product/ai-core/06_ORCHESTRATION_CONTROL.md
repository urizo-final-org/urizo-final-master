# 6. 오케스트레이션 제어

> 담당자: 민승준 (`tmdwns0531`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 확정된 상위 방향

- 최고관리자가 OpenAI·Claude·Gemini 등 Provider Key를 등록한다. Key 원문은 저장 후 다시 표시하지 않는다.
- LLM DevOps는 요구사항 분석, 코딩, 코드 리뷰의 3-Agent 구조를 사용한다.
- 최고관리자가 `AI 운영 > Agent 관리`에서 각 Agent 단계에 사용할 Provider·Model과 Model Tier를 매핑한다.
- Agent 단계와 승인 흐름의 의미는 4번 기능이 소유하고, 6번은 해당 단계의 실행 모델 배치를 소유한다.

## 현재 방향

- Frontend의 현재 `AI 운영 > Agent 관리`, Provider·Model 관리와 LLM DevOps Mock UI를 기준으로 상세 화면을 검토한다.
- Python LangGraph Runtime은 고정 State Machine, Checkpoint, 재시도와 관리자 승인 Interrupt를 담당한다.
- Spring Backend와 Core DB가 권한, Provider·Model 설정과 Job 상태의 기준이 된다.
- Node 기반 UI를 사용하더라도 확정된 3-Agent 단계의 Model Mapping을 관리하는 범위로 제한하고,
  단계 순서 변경은 4번 담당자와 함께 결정한다.
- LangSmith·Langfuse 등 실행 모니터링 도구의 적용 여부를 조사한다.
- Agent는 DB·Shell·Secret에 직접 접근하지 않고 승인된 Tool Gateway만 사용한다.

## 담당자 검토 항목

- Provider Key 등록·교체와 Model Tier·Agent Mapping 계약
- Agent 관리 UI와 Spring Backend·LangGraph 간 상태 흐름
- Node 기반 Mapping UI의 최소 범위
- Monitoring 도구, Checkpoint와 실행 이력의 최소 시연 범위

## 진행 상태

- 현재: Provider·Model Mapping과 오케스트레이션·모니터링 방향 심층 조사
- 다음: 팀 중간점검 후 계약과 최소 완료 기준 확정

## 하위 작업 기록

#### `AI06-001` · Agent 설정 메뉴 정리

- [x] 별도 `Agent 관리` 사이드바 메뉴 숨김
- [x] Provider·Model 통합 화면의 사이드바 메뉴명을 `Agent 설정`으로 변경
- [x] 기존 Route와 상세 화면 제목을 유지하고 Frontend 회귀 테스트 확인

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
| `AI06-001` | `axms-ai06-001-agent-settings-menu` | 담당 기능 MD 작업 등록 | Master | 변경 완료·PR 전 | `feature/tmdwns0531_axms-ai06-001-agent-settings-menu_v0.1` | - | - | - |
| `AI06-001` | `axms-ai06-001-agent-settings-menu` | Agent 설정 메뉴 정리 | Frontend | 구현 완료·PR 전 | `feature/tmdwns0531_axms-ai06-001-agent-settings-menu_v0.1` | - | - | - |
