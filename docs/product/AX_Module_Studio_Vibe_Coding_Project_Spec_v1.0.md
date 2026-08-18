# AX Module Studio
## 멀티에이전트·도구 실행형 시스템 기반 AI-native CMS

> **Master 보존 안내 — 2026-08-18**
> 이 파일은 기존 인수인계 패키지의 전체 프로젝트·시스템 제품 기준선을 Master에 보존한
> 사본이다. 원본 SHA-256은
> `4126D4FA9E98AFC81F1FD3053A0362FCB71D1975E6D5F880E7BD9F36A487DBC4`이다. 아래 원문 본문은
> 추적성을 위해 보존하지만, 이 파일 하나만으로 현재 구현을 시작하거나 범위를 확정하지 않는다.
>
> 충돌 시 최신 Master의
> [`TEAM_CHECKLIST_DECISION_OVERLAY_v0.1`](AX_Module_Studio_TEAM_CHECKLIST_DECISION_OVERLAY_v0.1.md),
> [`FND03_COMPLETION_SCOPE_DECISION_v0.1`](AX_Module_Studio_FND03_COMPLETION_SCOPE_DECISION_v0.1.md),
> 현재 handoff·roadmap·traceability 및 Spring AI/LangGraph 아키텍처 결정이 우선한다. 특히 아래의
> FastAPI 중심 구조, 과거 역할명·승인 흐름, 두 Repository 가정, 30일 Phase/담당표는 현재 권위와
> 충돌하는 범위에서 역사적 기준선이다. 현재 실행 순서는 Wave 3 CMS-01~04 병렬 → CMS-05→06→07
> 및 통합 인수 → 팀 심층 논의 Gate이며, 이후 기능은 새 Master 결정 전까지 구현하지 않는다.

> **한 줄 정의**
> 웹 업체 또는 고객사 관리자가 도메인 API와 LLM을 연결하면, 해당 데이터를 RAG 지식으로 변환하고 사용자 챗봇·메뉴·콘텐츠 페이지·사이트 디자인 템플릿까지 구성·검증·승인·게시할 수 있는 도메인 비종속형 AX 플랫폼

> **제품 메시지**
> **“API를 연결하면 지식이 되고, 지식이 사용자 서비스가 된다.”**

---

## 0. 문서 상태

| 항목 | 내용 |
|---|---|
| 문서 버전 | v1.7-draft — 파일명은 기존 참조 호환을 위해 `v1.0`을 유지하며 본문 버전과 후반 날짜별 결정사항을 최신 기준으로 사용 |
| 상태 | **30일 팀프로젝트 범위 재조정 중 — 본 문서의 최신 반영 내용 우선** |
| 팀 구성 | 5명 |
| 개발 기간 | 30 Working Days |
| 주 발표 대상 | 웹 기반 SI 업체, CMS 업체, 웹 에이전시, 사내 웹 개발·운영 조직 |
| 핵심 가치 | 구매 가능성, 고객사 납품 가능성, 프로젝트 간 재사용성 |
| 구현 원칙 | 완전 자율이 아니라 **정책과 도구로 통제되는 자율성** |
| 단일 진실 공급원 | 본 문서를 기획·개발·테스트·발표 범위의 기준으로 사용 |
| 변경 규칙 | P0 범위 변경은 팀 전체 합의와 문서 버전 갱신 없이는 금지 |

---

# 1. 프로젝트 개요

## 1.1 문제 정의

웹 기반 업체는 고객사 프로젝트마다 다음 작업을 반복한다.

1. 고객사 도메인 데이터 API 분석
2. API 인증 방식과 요청·응답 JSON 연동
3. 데이터를 검색·추천·상담용 문서로 변환
4. RAG 파이프라인과 챗봇 구축
5. 사용자 페이지의 메뉴·콘텐츠 화면 개발
6. 고객 검토 후 수정·재배포
7. 데이터와 모델 변경 시 유지보수 재수행

이 과정은 기술적으로 유사하지만 고객사마다 데이터 구조와 도메인이 달라 반복 개발이 발생한다.
납품 이후에도 메뉴 변경, 콘텐츠 페이지 추가, 데이터 갱신, 챗봇 지식 교체를 위해 개발자의 지속적인 개입이 필요하다.

## 1.2 해결 방향

AX Module Studio는 반복 작업을 다음의 표준 수명주기로 전환한다.

```text
도메인 API 등록
→ 데이터 미리보기·필드 매핑
→ RAG 문서 생성
→ Knowledge Version 검증·활성화
→ 사용자 챗봇 연결
→ 자연어 기반 메뉴·페이지 구성
→ 정책 검증·미리보기
→ 관리자 승인
→ 사용자 서비스 게시
→ 버전 교체·복구
```

## 1.3 프로젝트의 본질

이 프로젝트는 특정 도메인의 챗봇을 만드는 프로젝트가 아니다.

> **고객사별 도메인 API와 LLM을 설정값으로 교체하면서, 동일한 플랫폼에서 지식·챗봇·사용자 페이지를 구성하는 AI-native CMS를 구현한다.**

---

# 2. 구매·납품·재사용 관점의 가치

## 2.1 예상 구매자

### 1차 고객

- 공공·기업 웹사이트를 구축하는 SI 업체
- CMS 솔루션 업체
- 웹 에이전시
- 다수 브랜드 사이트를 운영하는 기업
- 사내 포털·지식 서비스 운영 조직

### 2차 고객

- 관광·정책·교육·채용·상품 정보 포털 운영사
- AI 챗봇을 도입하려는 중소기업
- 데이터 API는 보유했으나 AI 서비스 개발 인력이 부족한 조직

## 2.2 고객이 구매할 이유

- 고객사마다 반복되던 API·RAG·챗봇·페이지 구축 공수를 표준화할 수 있다.
- 고객이 자신의 LLM API Key를 사용하므로 AI 비용을 고객사별로 분리할 수 있다.
- 납품 후 관리자 스스로 Knowledge Base와 페이지를 변경할 수 있다.
- 동일한 플랫폼을 관광·정책·교육·채용 등 다른 도메인에 재사용할 수 있다.
- AI가 생성한 결과를 바로 반영하지 않고 검증·승인·버전 관리할 수 있다.
- 플랫폼 코드 재배포 없이 메뉴·페이지·RAG 연결을 변경할 수 있다.

## 2.3 납품 형태

### 구축형

```text
AX Module Studio 설치
+ 고객사 API Connector 설정
+ 페이지 컴포넌트·테마 적용
+ 관리자 교육
+ 유지보수
```

### 구독형 확장 가능성

```text
프로젝트별 월 구독
+ 데이터 동기화 사용량
+ LLM BYOK 또는 사용량 과금
+ 추가 Connector·Component 유료 모듈
```

## 2.4 재사용 단위

- Domain Connector Template
- 공통 Document Schema
- RAG Pipeline
- Knowledge Version Manager
- Chatbot Widget
- Page Component Library
- MenuSpec·PageSpec·SiteTemplateSpec Schema
- Site Template Renderer·Design Token
- Approval Workflow
- Agent Tool Registry
- 보안·감사 정책

---

# 3. 이전 프로젝트 대비 포지셔닝

첨부된 이전 기수 프로젝트 목록을 기준으로 다음 요소들과 일부 유사성이 있다.

| 비교 프로젝트 | 유사 요소 | AX Module Studio의 차이 |
|---|---|---|
| CAESAR | RAG, Notion·SaaS 연동, LangGraph Agent, 관리자 기능 | 사내 업무 자동화가 아니라 고객사 사용자 웹서비스의 데이터·지식·페이지 구성 자동화 |
| WMAI | 관리자 중심 AI 운영 대시보드 | 고정 커뮤니티 운영이 아니라 도메인 API부터 사용자 서비스 구성까지 수행 |
| Easy Quality | 문서 버전·변경 이력 관리 | 문서 비교를 넘어 활성 RAG 버전 전환과 사용자 챗봇 반영 |
| BOSS | 자연어 지시 기반 멀티에이전트 실행 | 자영업 업무가 아니라 웹서비스 구성·운영 작업을 실행 |
| ClickMe | 생성·검증·실행·관리의 전 수명주기 | 광고 도메인이 아니라 도메인 비종속형 CMS 수명주기 |
| Land UP | LLM 생성 결과를 코드로 검증하고 재시도 | 물리 제약 대신 JSON Schema·권한·컴포넌트·게시 정책 검증 |

### 발표 시 사용할 차별화 문장

> “이전 프로젝트들이 특정 도메인의 AI 기능이나 사내 업무 Agent를 구현했다면, AX Module Studio는 웹 업체가 여러 고객사에 반복 납품할 수 있도록 데이터 연결부터 RAG 지식, 챗봇, 메뉴와 사용자 페이지 게시까지 하나의 관리 수명주기로 표준화합니다.”

---

# 4. 30일 프로젝트 범위

## 4.1 P0 — 반드시 완성할 범위

1. 관리자 인증·권한
2. 프로젝트 등록 및 기본 설정
3. 고객사 LLM Provider·API Key 등록
4. REST·JSON Domain Connector 등록
5. API 연결 테스트와 응답 미리보기
6. JSONPath 기반 필드 매핑
7. 공통 Document 변환
8. 문서 청킹·임베딩·Vector 저장
9. Knowledge Version 생성·검증·활성화
10. 사용자용 RAG 챗봇
11. 답변 근거·출처 표시
12. 자연어 기반 대메뉴·하위메뉴 생성
13. 자연어 기반 콘텐츠 페이지 생성
14. PageSpec 기반 동적 페이지 렌더링
15. 관리자 미리보기·승인·게시
16. 페이지 및 Knowledge Version 복구
17. Agent Tool 실행 이력·감사 로그
18. Cloud-agnostic Linux VM Docker 기반 스테이징 배포
19. 서로 다른 2개 도메인의 End-to-End 시연
20. Knowledge Build 단계·진행률·성공·실패 상태 UI
21. 활성 Knowledge Version 전용 검색 하네스
22. 시점·수집 완전성·검색 품질 기반 Knowledge 평가 대시보드
23. Knowledge Build·평가·활성화·복구 히스토리와 정규화 문서 다운로드
24. 메뉴·회원·콘텐츠·게시판의 Demo 범위 기본 관리 기능
25. `SiteTemplateSpec` 기반 Header·Footer·기본 Layout·Theme 교체, 버전 관리, 미리보기·승인·게시·복구
26. 자연어 기반 사이트 디자인 템플릿 Draft 생성·수정

## 4.2 P1 — P0 완료 후 구현

- OpenAPI 3.x 문서 Import
- LLM Provider 2종 연결
- 페이지 버전 간 Diff
- Connector 동기화 스케줄
- 토큰·비용·응답 시간 대시보드
- PageSpec 자동 수정·재생성
- 알림(Webhook 또는 이메일)
- 공공데이터포털 메타데이터 검색 기반 대체 API 후보 제안
- 제한된 확장 경로에서 코드 Patch·테스트·Preview·PR을 수행하는 Demo Extension

## 4.3 P2 — 후순위 확장

- Local LLM OpenAI-Compatible Provider
- PageSpec·Tool 선택용 Local LLM Fine-tuning
- 범용 패키지 경로 권한 기반 자율 코딩 Agent
- 다중 저장소·임의 기능 대상 Git 브랜치·PR 자동 생성
- 운영형 자율 배포와 복잡한 배포 오케스트레이션
- 복잡한 OAuth 2.0 Connector
- 다중 고객사 SaaS형 멀티테넌시
- 마켓플레이스형 Connector·Component 판매

## 4.4 이번 프로젝트에서 제외

- API Key만 입력하면 모든 API를 무설정 자동 해석하는 기능
- SOAP·WebSocket·GraphQL 범용 지원
- 임의 SQL 생성·실행
- AI의 DB DDL 권한
- AI의 자유로운 Shell 실행
- AI의 Cloud 계정·네트워크·OS 설정 변경
- 자동 PR 병합
- 운영 서버 무승인 배포
- LLM 또는 Coding Agent의 운영 소스 직접 수정·운영 프로세스 직접 재기동
- 임의 React·JavaScript 코드 실행
- 임의 HTML·CSS·JavaScript 또는 무제한 자유 배치 방식으로 모든 페이지 디자인을 생성하는 기능
- 사용자 개인정보를 LLM Prompt에 전달하는 기능

---

# 5. 제품 사용자와 권한

## 5.1 역할

### Super Admin — 솔루션 공급자 또는 최고관리자

- 프로젝트 생성
- 공공데이터 Domain Connector의 URL·Method·요청/응답 규격·Secret 연결과 교체
- 플랫폼 공용 LLM Provider·Model·Secret 등록
- Agent Tool 정책 설정
- Coding Agent 허용 경로·고정 Denylist·Repository 연동 상태 관리
- Knowledge Build 실행·취소·재시도·평가·활성화·복구
- Page Component 등록
- 사이트 템플릿 Variant·Design Token 허용 목록 관리
- 전체 감사 로그 열람
- 게시·복구 최종 승인

### Project Admin — 고객사 관리자

- 최고관리자가 활성화한 Domain Connector 선택
- Project 범위 LLM Key 등록과 작업별 Model Mapping
- 비밀값이 아닌 RAG 문서 필드 매핑·Chunking·평가 기준 관리
- Knowledge Build 단계·평가 Report 열람과 RAG 검색 테스트
- 챗봇 Knowledge 연결
- 메뉴·페이지 자연어 생성
- 사이트 Header·Footer·Theme·기본 Layout의 자연어 Draft 생성·수정
- 미리보기·수정·승인 요청
- 운영 중인 메뉴·페이지·사이트 템플릿 버전 전환 요청

### Reviewer — 검토자

- Connector 설정 검토
- RAG 검색 결과 검토
- PageSpec·SiteTemplateSpec·Desktop/Mobile 미리보기 검토
- 승인·반려 및 의견 등록

### End User — 사용자 페이지 방문자

- 콘텐츠 페이지 조회
- RAG 챗봇 사용
- 출처 확인

### Developer / PM

- CMS 외부에서 Git·CI/CD·Cloud·OS 서비스 계정과 Branch·PR 정책 사전 구성
- 새로운 Connector 유형과 Page Component 개발
- 플랫폼 장애 대응
- P2 자율 코딩 기능 운영

---

# 6. 핵심 사용자 시나리오

## 6.1 도메인 API 연결

```text
관리자
→ API 이름·Base URL·Endpoint·Method 입력
→ 인증 방식 선택
→ Secret 등록
→ 요청 Parameter·응답 JSON 예시 입력
→ 연결 테스트
→ 응답 데이터 미리보기
→ RAG 문서 필드 매핑
→ Connector 저장
```

## 6.2 RAG Knowledge 생성

```text
Connector 실행
→ 원본 JSON 수집
→ 공통 Document 변환
→ 정제·중복 제거
→ 청킹
→ 임베딩
→ Vector 저장
→ Knowledge v1 생성
→ 검색 테스트
→ 관리자 승인
→ 챗봇에 활성화
```

## 6.3 RAG 교체·복구

```text
신규 데이터 동기화
→ Knowledge v2 생성
→ 평가 질문 실행
→ 품질 리포트 확인
→ 관리자 승인
→ Active Pointer v1 → v2 전환

문제 발생
→ v2 비활성화
→ Active Pointer v2 → v1 복구
```

## 6.4 자연어 메뉴·페이지 생성

관리자 입력 예시:

> “대메뉴에 ‘지역 관광’을 만들고 하위메뉴로 ‘오늘의 추천’과 ‘축제 정보’를 추가해줘. 오늘의 추천 페이지에는 지역 필터, 콘텐츠 카드 6개, 관광 RAG 챗봇을 배치해줘.”

처리 흐름:

```text
자연어 요구
→ Page Composer Agent
→ MenuSpec·PageSpec 생성
→ JSON Schema 검증
→ 데이터 소스·Knowledge 연결 검증
→ 미리보기
→ 관리자 수정·승인
→ 게시
```

## 6.5 자연어 사이트 디자인 템플릿 생성

관리자 입력 예시:

> “헤더는 로고 왼쪽·메뉴 오른쪽 형태로 바꾸고, 네이비 테마와 3단 푸터를 적용해줘. 본문 최대 너비는 1200px로 해줘.”

```text
자연어 요구
→ Page Composer Agent
→ 허용된 Template Variant·Design Token 조회
→ SiteTemplateSpec Draft 생성
→ JSON Schema·접근성·Asset·정책 검증
→ Desktop·Mobile 미리보기
→ 관리자 수정·승인 요청
→ 최종 승인·게시
```

## 6.6 사용자 서비스 반영

```text
게시 승인
→ Site Release 생성
→ Menu Version·Page Version·SiteTemplate Version 참조를 하나의 Transaction으로 활성화
→ 사용자 페이지 캐시 무효화
→ 즉시 노출
```

등록된 Variant와 Token 안에서 메뉴·페이지·사이트 템플릿을 게시하는 데에는 애플리케이션 재배포가 필요하지 않는다. 새로운 React Component나 Template Variant를 추가할 때만 코드 PR·배포가 필요하다.

---

# 7. 멀티에이전트 설계

## 7.1 원칙

- Agent 수를 늘리는 것이 목표가 아니다.
- 각 Agent는 하나의 명확한 책임과 제한된 Tool만 가진다.
- Agent는 직접 DB·Shell·Secret에 접근하지 않는다.
- 모든 변경은 구조화된 Spec과 Tool 호출로 수행한다.
- 최종 게시와 활성 버전 변경에는 관리자 승인이 필요하다.

## 7.2 Agent 구성

| Agent | 책임 | 주요 출력 | 허용 Tool |
|---|---|---|---|
| Connector Agent | API 규격 분석, 매핑 초안, 연결 테스트 계획 | ConnectorSpec | `preview_api`, `suggest_mapping`, `validate_connector` |
| Knowledge Agent | 문서 변환·청킹·임베딩·검색 테스트 계획 | KnowledgeBuildSpec | `create_knowledge_version`, `run_retrieval_test` |
| Page Composer Agent | 자연어를 메뉴·페이지·사이트 템플릿 구조로 변환 | MenuSpec, PageSpec, SiteTemplateSpec | `list_components`, `list_template_variants`, `list_data_sources`, `save_page_draft`, `save_template_draft` |
| Validation Agent | Schema·정책·권한·연결 상태 검사 | ValidationReport | `validate_spec`, `scan_policy`, `check_binding` |
| Publish Orchestrator | 승인 상태 확인 후 Site Release·활성 Knowledge Version 변경 | PublishResult | `publish_site_release`, `activate_knowledge`, `rollback_version` |

## 7.3 Agent 상태 그래프

```mermaid
stateDiagram-v2
    [*] --> REQUESTED
    REQUESTED --> ANALYZING
    ANALYZING --> DRAFT_CREATED
    DRAFT_CREATED --> VALIDATING
    VALIDATING --> REVISION_REQUIRED: 검증 실패
    REVISION_REQUIRED --> ANALYZING
    VALIDATING --> APPROVAL_PENDING: 검증 통과
    APPROVAL_PENDING --> REJECTED: 관리자 반려
    REJECTED --> ANALYZING
    APPROVAL_PENDING --> APPROVED: 관리자 승인
    APPROVED --> PUBLISHED
    PUBLISHED --> ROLLED_BACK: 복구
    PUBLISHED --> [*]
```

## 7.4 Tool 호출 정책

Agent가 호출할 수 있는 Tool은 코드에 등록된 Allowlist로 제한한다.

```text
허용:
- Connector Draft 저장
- API Preview 실행
- Knowledge Version 생성 요청
- Retrieval Test 실행
- Page Draft 저장
- PageSpec 검증
- Site Template Draft 저장·검증·미리보기
- 게시 승인 요청
- 승인 완료 버전 게시
- 직전 버전 복구

금지:
- 임의 SQL
- 임의 URL 호출
- 자유 Shell 명령
- Secret 조회
- 사용자·권한 테이블 수정
- 운영 배포
```

---

# 8. 시스템 아키텍처

## 8.1 고정 기술 스택

| 영역 | 기술 |
|---|---|
| 관리자·사용자 Frontend | React + TypeScript 단일 애플리케이션, Route 분리 |
| API·Control Plane | Python 3.12, FastAPI |
| AI Worker | Python Worker + LangGraph, API Process와 분리 |
| LLM Adapter | LangChain Provider Adapter·Structured Output·제한 Tool Binding |
| DB·Vector | PostgreSQL 16 + pgvector |
| Queue·Cache | Redis 기반 Queue 권장, 작업 이력의 Source of Truth는 PostgreSQL |
| CI/CD | GitHub Actions |
| Container | Docker, Docker Compose |
| 배포 대상 | Provider 비종속 Linux VM 1대 + Docker Compose |
| Secret | Dev 로컬 암호화 저장 + Prod Secret Store Adapter |
| Observability | 내부 구조화 로그·Audit + LangSmith Trace·Evaluation + FastAPI Health API·기본 메트릭 |
| API 문서 | OpenAPI / Swagger |

## 8.2 논리 아키텍처

```mermaid
flowchart LR
    U[End User] --> WEB[User Web]
    A[Project Admin] --> CMS[Admin CMS]

    WEB --> API[Python FastAPI API]
    CMS --> API

    API --> DB[(PostgreSQL + pgvector)]
    API --> SEC[Secret Store Adapter]
    API --> Q[Redis Queue]
    Q --> AI[Python AI Worker / LangGraph]
    AI --> LS[LangSmith Trace / Evaluation]

    AI --> TG[Tool Gateway]
    TG --> EXT[Domain APIs]
    TG --> DB
    TG --> LLM[LLM Provider]

    GH[GitHub Actions] --> IMG[Docker Build]
    IMG --> CLOUD[Cloud Staging]
```

## 8.3 서비스 책임

### Python FastAPI API / Control Plane

- 인증·인가
- 프로젝트·Connector·Knowledge·Page 메타데이터 관리
- 승인 상태 머신
- Tool Gateway
- Secret Reference 관리
- 사용자 페이지 API
- 감사 로그
- AI Worker Job 생성·상태 조회
- 게시·복구 트랜잭션

### Python AI Worker

- LangGraph 고정 Workflow·Checkpoint·재시도·관리자 승인 Interrupt
- LangChain Provider Adapter·Structured Output·Node별 제한 Tool Binding
- LangSmith Trace·Evaluation 전송. LangSmith 장애·미설정은 업무 Job 실패 사유가 아님
- ConnectorSpec·KnowledgeBuildSpec·MenuSpec·PageSpec 생성
- RAG 문서 변환·청킹·임베딩
- 검색·답변 생성
- 구조화 출력
- 평가와 재시도
- 장시간 Build Job의 재시도·중단·진행률 갱신

### PostgreSQL + pgvector

- CMS 업무 데이터
- 문서·청크·메타데이터
- Vector Embedding
- Knowledge Version
- Menu·Page Version
- Agent Job·Trace·Audit
- LangGraph Checkpoint. 업무 승인·권한의 Source of Truth는 Agent Job Table이며 Checkpoint는 재개용 실행 상태로만 사용

---

# 9. 도메인 Connector 설계

## 9.1 지원 범위

### P0 지원

- 공공데이터포털의 사전 선정된 REST·GET·JSON API 2종
- 최고관리자가 API 인증키를 직접 등록하고 DB에는 Secret Reference만 저장
- URL·Method·인증키 Parameter 이름·위치를 최고관리자가 설정
- 필수·선택 요청 Parameter의 이름·타입·기본값·설명을 UI에서 직접 설정
- Page Number·Page Size Parameter와 시작 Page를 직접 설정
- 성공 Code Path·Items Path·Total Count Path를 JSONPath로 직접 설정
- 공공데이터포털 자동변환형과 Gateway형은 입력 편의를 위한 Template으로만 제공
- JSONPath 필드 추출
- 수동 동기화
- 사전 허용된 외부 Host

### P1 지원

- OpenAPI 3.x Import
- API Key Header·Bearer Token과 Offset Pagination 확장
- 정기 동기화
- 다단계 상세 조회
- Rate Limit 대응
- OAuth Client Credentials

## 9.2 ConnectorSpec 예시

```json
{
  "name": "TOUR_CONTENT_API",
  "baseUrl": "https://api.odcloud.kr/api",
  "endpoint": "/{datasetId}/v1/{resourceId}",
  "method": "GET",
  "authentication": {
    "type": "API_KEY",
    "location": "QUERY",
    "name": "serviceKey",
    "secretRef": "aws-secret://tour-api"
  },
  "request": {
    "query": {
      "page": "{{page}}",
      "perPage": 100,
      "returnType": "JSON"
    }
  },
  "response": {
    "itemsPath": "$.data",
    "totalCountPath": "$.totalCount"
  },
  "pagination": {
    "type": "PAGE",
    "pageParameter": "page",
    "pageSizeParameter": "perPage",
    "startPage": 1
  },
  "documentMapping": {
    "documentId": "$.contentId",
    "title": "$.title",
    "content": "$.description",
    "category": "$.category",
    "updatedAt": "$.updatedAt"
  }
}
```

## 9.3 공통 Document 모델

```json
{
  "documentId": "TOUR-1001",
  "projectId": "PROJECT-A",
  "sourceId": "TOUR_CONTENT_API",
  "title": "한강 야간 축제",
  "content": "축제 상세 설명...",
  "category": ["관광", "축제"],
  "sourceUrl": "https://example.com/1001",
  "metadata": {
    "region": "서울",
    "startDate": "2026-08-01"
  },
  "sourceUpdatedAt": "2026-08-01T10:00:00Z",
  "ingestedAt": "2026-08-05T02:00:00Z"
}
```

---

# 10. RAG 설계

## 10.1 파이프라인

```text
Raw API Response
→ JSONPath 추출
→ 공통 Document 변환
→ HTML·불필요 문자 정제
→ 중복 제거
→ 문서 타입별 청킹
→ 임베딩
→ Knowledge Version 단위 저장
→ Retrieval Test
→ 승인
→ Active Version 전환
```

## 10.2 Knowledge Version 상태

```text
DRAFT
→ BUILD_REQUESTED
→ API_CONNECTING
→ FETCHING
→ NORMALIZING
→ STORING_DOCUMENTS
→ CHUNKING
→ EMBEDDING
→ INDEXING
→ READY
→ EVALUATING
→ APPROVAL_PENDING
→ ACTIVE
→ ARCHIVED
→ FAILED
```

## 10.3 검색 정책

- 사용자 Query API는 `version_id`를 입력받지 않는다.
- 서버가 `knowledge_base.active_version_id`를 조회하여 활성 버전을 결정한다.
- Project·Knowledge Base·Active Knowledge Version을 모든 일반·Vector 검색에 강제한다.
- 사용자 검색용 DB Role은 활성 버전 전용 View 또는 제한된 Query Function만 조회한다.
- 이전 Knowledge 문서의 조회·다운로드는 관리자 이력 API에서만 허용한다.
- 활성 버전 전환 시 캐시 키에 Version을 반영하고 이전 버전 캐시를 폐기한다.
- Metadata Filter 지원
- Top-K 검색
- P0: Dense Vector Search
- P1: Keyword + Dense Hybrid Search
- 답변에 출처 문서 제목과 Source URL 표시
- 근거가 부족하면 추측하지 않고 답변 불가 처리

## 10.4 평가 질문셋과 품질 경고

각 도메인별 15~30개의 Golden Question을 관리한다.

| 평가 항목 | 설명 |
|---|---|
| Retrieval Hit Rate | 정답 근거 문서가 Top-K에 포함되는 비율 |
| Groundedness | 답변이 검색 근거 안에서 생성되었는지 |
| Citation Accuracy | 표시한 출처가 답변 내용을 실제로 지원하는지 |
| Refusal Accuracy | 근거가 없을 때 답변을 거부하는지 |
| Latency | 검색부터 최종 응답까지 걸린 시간 |
| Cost | 질문 1건당 LLM·Embedding 비용 |

평가는 시점·수집 완전성·검색 품질의 세 축으로 구성한다.

| 평가 축 | 기본 지표 | P0 기본 경고 기준 |
|---|---|---|
| 시점 | 데이터 최신일, 경과일, API 갱신주기 | 경과일이 설정된 갱신주기의 1.5배 초과 시 경고 |
| 수집 완전성 | `stored_count / totalCount`, 변환 실패율 | 완전성 98% 미만 또는 변환 실패율 2% 초과 시 경고 |
| 필드 품질 | 필수 필드 누락률, 중복률 | 필수 필드 누락률 5% 초과 또는 중복률 10% 초과 시 경고 |
| 검색 품질 | Golden Question Hit@5, MRR | Hit@5 80% 미만 시 경고 |

위 기준은 30일 Demo의 초기값이며 Connector별 갱신주기와 데이터 특성에 따라 설정값으로 관리한다. 단일 종합점수만 표시하지 않고 원시 수치·산식·이전 Active Version 대비 증감을 함께 표시한다. 평가 경고는 자동으로 API가 낡았다고 단정하지 않으며, 수집·매핑·청킹·임베딩·질문셋 문제를 구분하여 원인을 제시한다.

---

# 11. 메뉴·페이지·사이트 템플릿 Composition 설계

## 11.1 핵심 원칙

AI가 임의 HTML·JavaScript를 생성해 실행하지 않는다.

> AI는 CMS가 이해할 수 있는 `MenuSpec`, `PageSpec`, `SiteTemplateSpec`을 생성하고, 기존 Renderer가 안전한 컴포넌트·템플릿 Variant·Design Token으로 화면을 조립한다.

## 11.2 P0 컴포넌트

- `HERO`
- `HEADING`
- `TEXT`
- `CONTENT_CARD_GRID`
- `CATEGORY_FILTER`
- `SEARCH_BOX`
- `RAG_CHATBOT`

P0에서는 페이지 Layout 3종(`ONE_COLUMN`, `CONTENT_WIDE`, `SIDEBAR`)과 위 컴포넌트만 지원한다. DB Schema는 저장 구조이고 PageSpec은 Renderer 입력 계약이므로 별도로 정의한다. 각 Component는 허용되는 `props`, 필수값, 타입, 범위와 Data Binding 규칙을 JSON Schema로 고정한다.

## 11.3 MenuSpec 예시

```json
{
  "version": 1,
  "items": [
    {
      "name": "지역 관광",
      "path": "/tour",
      "order": 10,
      "children": [
        {
          "name": "오늘의 추천",
          "path": "/tour/today",
          "pageRef": "page-tour-today"
        },
        {
          "name": "축제 정보",
          "path": "/tour/festival",
          "pageRef": "page-tour-festival"
        }
      ]
    }
  ]
}
```

## 11.4 PageSpec 예시

```json
{
  "pageId": "page-tour-today",
  "title": "오늘의 추천",
  "siteTemplateRef": "site-template-v1",
  "layout": "CONTENT_WIDE",
  "components": [
    {
      "type": "HERO",
      "props": {
        "title": "오늘 떠나기 좋은 여행지",
        "description": "관광 데이터와 AI가 추천합니다."
      }
    },
    {
      "type": "CATEGORY_FILTER",
      "props": {
        "dataSourceRef": "TOUR_CONTENT_API",
        "field": "region"
      }
    },
    {
      "type": "CONTENT_CARD_GRID",
      "props": {
        "dataSourceRef": "TOUR_CONTENT_API",
        "limit": 6,
        "titleField": "title",
        "descriptionField": "content",
        "imageField": "imageUrl"
      }
    },
    {
      "type": "RAG_CHATBOT",
      "props": {
        "knowledgeBaseRef": "TOUR_KB",
        "welcomeMessage": "여행지를 추천해 드릴까요?"
      }
    }
  ]
}
```

## 11.5 SiteTemplateSpec 예시

```json
{
  "templateId": "site-template-v1",
  "version": 1,
  "theme": {
    "colorPreset": "NAVY",
    "fontPreset": "SYSTEM_SANS",
    "contentMaxWidth": 1200,
    "radius": "MEDIUM",
    "spacing": "COMFORTABLE"
  },
  "header": {
    "variant": "LOGO_LEFT_NAV_RIGHT",
    "logoAssetRef": "asset-main-logo",
    "menuRef": "menu-main",
    "sticky": true
  },
  "footer": {
    "variant": "THREE_COLUMN_DARK",
    "sections": [
      {"title": "서비스", "menuRef": "menu-service"},
      {"title": "고객지원", "menuRef": "menu-support"},
      {"title": "회사", "menuRef": "menu-company"}
    ],
    "copyright": "© AX Module Studio"
  },
  "pageDefaults": {
    "layout": "CONTENT_WIDE",
    "cardVariant": "BORDERED"
  }
}
```

P0 Template Registry는 Header 3종, Footer 2종, Page Layout 3종과 제한된 Design Token을 제공한다. Header·Footer의 반응형 동작은 각 Variant의 React 구현에 내장하고, 관리자는 코드가 아닌 Variant·Token·Asset Reference만 교체한다.

## 11.6 검증 규칙

- URL Path 중복 금지
- 허용되지 않은 Component 금지
- 존재하지 않는 DataSource·Knowledge 참조 금지
- 사용자 입력을 Script로 렌더링하지 않음
- 필수 Property 누락 금지
- 페이지당 Component 개수 제한
- 외부 Image URL Allowlist 적용
- 허용되지 않은 Header·Footer·Layout Variant와 Design Token 금지
- Raw HTML·CSS·JavaScript, 인라인 Script, 임의 외부 Font·Asset URL 금지
- Logo·Image는 승인된 `assetRef`만 허용
- 기본 색상 대비와 Mobile Breakpoint 미리보기 검증
- 관리자 미리보기 통과 후 게시

## 11.7 자연어 변경·게시 원칙

- 자연어는 운영 화면을 직접 수정하지 않고 `SiteTemplateSpec` Draft를 생성한다.
- LLM은 Template Registry의 허용 Variant와 Token 목록 안에서만 값을 선택한다.
- Schema·정책 검증을 통과한 Draft만 Desktop·Mobile Preview로 이동한다.
- Reviewer 검토와 Super Admin 최종 승인 후 `Site Release`의 활성 참조를 교체한다.
- 이전 `SiteTemplate Version`은 이력으로 보존하여 동일한 게시 절차로 복구한다.
- 하나의 `Site Release`에는 Menu Version, SiteTemplate Version, 게시 대상 Page Version Map을 결합하여 Header·Menu·Page가 서로 다른 버전으로 노출되는 부분 게시를 방지한다.

---

# 12. DB 권한과 AI 계정 설계

## 12.1 중요한 원칙

“AI에게 DB 계정을 준다”는 것은 LLM이 사용자명·비밀번호를 받아 자유롭게 SQL을 실행한다는 뜻이 아니다.

> Python AI Server와 Tool Gateway가 제한된 DB Role을 사용하고, LLM은 구조화된 Tool만 호출한다.

## 12.2 권장 DB Role

| DB Role | 접근 범위 | 권한 |
|---|---|---|
| `cms_app` | 사용자·프로젝트·메뉴·페이지·승인 | 서비스 CRUD |
| `ai_workspace` | Agent Job, Draft Spec, Validation 결과 | SELECT, INSERT, UPDATE |
| `rag_worker` | 신규 Document, Chunk, Embedding, Knowledge Version | SELECT, INSERT, 제한 UPDATE |
| `rag_query` | 활성 Knowledge 전용 View | SELECT |
| `member_reader` | 마스킹된 회원 조회 View | SELECT |
| `audit_writer` | 감사 로그 | INSERT |
| `audit_reader` | 감사 로그 | SELECT |
| `langgraph_worker` | LangGraph Checkpoint Schema | SELECT, INSERT, UPDATE, DELETE는 자신의 Thread 범위로 제한 |
| `dbeaver_reader` | 마스킹 View·개발 진단용 조회 | SELECT, Local Dev 기본 접속 계정 |
| `dev_operator` | Local Dev의 시스템 관리 Tool·Test Seed 전용, DBeaver Profile 제공 금지 | SELECT, INSERT, UPDATE, 제한 DELETE, DDL 금지 |
| `migration_owner` | Schema Migration | CI/CD에서만 사용 |

## 12.3 AI 계정 금지 권한

- 사용자 비밀번호·세션 조회
- 관리자 Role 수정
- Secret 원문 조회
- `CREATE`, `ALTER`, `DROP`
- 임의 `DELETE`
- 다른 프로젝트 데이터 조회
- SQL Function 임의 실행
- DB Extension 설치

## 12.3.1 DBeaver·외부 DB Client 접속

PostgreSQL+pgvector Container는 각 팀원 Local Dev에서 DBeaver 같은 DB Client로 접속할 수 있어야 한다. 기본 Host Binding은 LAN 전체가 아니라 `127.0.0.1`로 제한하고, 설치된 PostgreSQL과의 충돌을 피하기 위해 Host Port는 환경변수로 변경 가능하게 한다.

```text
Host: 127.0.0.1
Host Port 기본값: 15432
Container Port: 5432
Database: ax_module_studio
SSL: Local Dev에서는 disable 허용
```

- DBeaver 기본 계정은 `dbeaver_reader`이며 마스킹 View와 진단용 조회만 허용한다.
- DBeaver에는 `dbeaver_reader` Credential만 제공하며 모든 DML·DDL을 DB 권한으로 차단한다. `dev_operator`는 승인된 시스템 관리 Tool·Test Seed에서만 사용하고 DBeaver Profile에 등록하지 않는다.
- FastAPI, Worker, Migration, DBeaver는 같은 Credential을 공유하지 않는다.
- Schema 변경은 DBeaver 수동 DDL이 아니라 Alembic Migration으로만 수행한다. Model·Schema 변경에는 새 Revision, 빈 DB와 직전 Revision Upgrade, 단일 Head 검증이 필수다.
- Credential은 팀 공용 MD·Git·채팅에 기록하지 않고 PC별 Local Secret에서 생성·보관한다.
- Prod PostgreSQL Port는 인터넷에 직접 공개하지 않는다. 필요 시 허용 IP 기반 SSH Tunnel·VPN·Bastion으로 접속하고 같은 조회·운영 Role 분리를 적용한다.

## 12.4 프로젝트 격리

모든 주요 테이블은 `project_id`를 포함한다.

- FastAPI에서 Project 권한 검사
- DB Query에서 Project 조건 강제
- Vector 검색에도 Project Filter 필수
- Agent Tool 호출 시 Project Context 서명

## 12.5 Tool 실행 권한 Context

LLM에는 OS·DB·GitHub Credential이나 최고권한 코드를 전달하지 않는다. FastAPI Orchestrator가 사용자 인증 결과로 `actor_id`, `project_id`, `job_id`, `allowed_tools`, `allowed_paths`, `approval_id`, `expires_at`을 포함한 서버 측 실행 Context를 생성한다. Tool Gateway는 매 호출마다 이 Context와 현재 승인 상태를 재검증한다.

- LLM이 임의 문자열로 권한을 주장해도 권한 상승이 되지 않아야 한다.
- 서버 간 권한 전달이 필요한 경우 짧은 만료시간의 서명된 Job Token을 사용하고 Prompt와 Tool Argument에는 포함하지 않는다.
- Secret은 전용 서비스가 실제 호출 시 주입하고 LLM 입력·출력·로그에 포함하지 않는다.
- 자연어 변경은 구조화된 ActionPlan, Preview, 승인, Tool Transaction, Audit 순서로만 실행한다.
- 삭제는 기본적으로 Soft Delete를 사용하며 실제 삭제는 별도 최고관리자 작업으로 분리한다.

---

# 13. 보안·거버넌스

## 13.1 Secret

- Domain API Key와 LLM API Key는 Dev에서는 로컬 Master Key로 암호화하고 Prod에서는 Secret Store Adapter를 통해 저장
- DB에는 암호문 또는 Secret Reference만 저장하고 원문은 재표시하지 않음
- Prompt, 로그, 응답, Trace에 Key 포함 금지
- 등록 후 원문 재표시 금지
- Key 교체·폐기 이력 기록

## 13.2 SSRF 방어

Connector URL 입력 기능은 SSRF 위험이 있으므로 다음을 적용한다.

- HTTPS만 허용
- 등록된 Host Allowlist
- `localhost`, 사설 IP, 링크 로컬, Cloud Metadata Endpoint IP 차단
- Redirect 횟수 제한
- 응답 크기·Timeout 제한
- DNS Rebinding 방어
- 관리자 연결 테스트 이력 기록

## 13.3 Prompt Injection 방어

외부 API 데이터는 명령이 아니라 **신뢰하지 않는 데이터**로 취급한다.

- System Instruction과 외부 문서 분리
- 문서 안의 Tool 실행 지시 무시
- Tool 호출 전 정책 검사
- 검색 문서가 Secret·권한·시스템 Prompt를 요구해도 차단
- 답변 생성과 관리 Tool 실행 Agent 분리

## 13.4 게시 승인

- Agent가 게시를 결정하지 않음
- Validation 통과 후 `APPROVAL_PENDING`
- Project Admin 또는 Super Admin 승인 필요
- 게시자·승인자·시간·대상 Version 기록
- 이전 Version 즉시 복구 가능

## 13.5 감사 로그

다음 이벤트를 반드시 기록한다.

- Connector 생성·수정·연결 테스트
- Secret Reference 연결·교체
- Knowledge Build·평가·활성화·복구
- Agent Tool 호출
- PageSpec 생성·수정·검증
- 승인·반려
- 게시·복구
- 권한 실패·정책 차단
- 외부 API 오류

---

# 14. CI/CD와 Cloud 배포

## 14.1 고정 인프라

```text
Provider 비종속 Linux VM 1대
├── reverse-proxy
├── React Static Web
├── Python FastAPI API Container
├── Python AI Worker Container
├── Redis Queue Container
└── PostgreSQL + pgvector Container
```

운영형 설계에서는 DB를 RDS로 분리할 수 있으나, 30일 MVP에서는 단일 EC2 Docker Compose를 기본으로 한다.

## 14.2 애플리케이션 배포

```text
feature branch
→ PR
→ Unit Test
→ Build
→ Docker Image Build
→ Security Scan
→ 개발자 승인 후 dev merge
→ GitHub Environment 수동 승인
→ Cloud Staging 배포
→ Health Check
→ 실패 시 직전 이미지 복구
```

## 14.3 콘텐츠 게시와 애플리케이션 배포 구분

### 콘텐츠 게시

- 메뉴 변경
- 페이지 구성 변경
- RAG Knowledge 교체
- 챗봇 연결 변경

```text
관리자 승인
→ DB Active Version 변경
→ 캐시 갱신
→ 즉시 반영
```

### 애플리케이션 배포

- 새로운 Connector 유형 개발
- 새로운 Page Component 개발
- Agent Tool 추가
- React·Python 코드 변경

```text
Git PR
→ 리뷰
→ Docker Build
→ Cloud 배포
```

---

# 15. 핵심 데이터 모델

```mermaid
erDiagram
    PROJECT ||--o{ CONNECTOR : owns
    PROJECT ||--o{ KNOWLEDGE_BASE : owns
    PROJECT ||--o{ PAGE : owns
    PROJECT ||--o{ SITE_TEMPLATE : owns
    PROJECT ||--o{ SITE_RELEASE : publishes
    PROJECT ||--o{ AGENT_JOB : runs

    CONNECTOR ||--o{ CONNECTOR_VERSION : has
    CONNECTOR_VERSION ||--o{ SOURCE_DOCUMENT : creates

    KNOWLEDGE_BASE ||--o{ KNOWLEDGE_VERSION : has
    KNOWLEDGE_VERSION ||--o{ DOCUMENT_CHUNK : contains

    PAGE ||--o{ PAGE_VERSION : has
    MENU ||--o{ MENU_VERSION : has
    SITE_TEMPLATE ||--o{ SITE_TEMPLATE_VERSION : has
    SITE_RELEASE ||--o{ SITE_RELEASE_ITEM : binds

    AGENT_JOB ||--o{ AGENT_STEP : contains
    AGENT_JOB ||--o{ TOOL_EXECUTION : invokes

    APPROVAL ||--|| KNOWLEDGE_VERSION : approves
    APPROVAL ||--|| PAGE_VERSION : approves
    APPROVAL ||--|| MENU_VERSION : approves
    APPROVAL ||--|| SITE_TEMPLATE_VERSION : approves
```

## 주요 엔티티

- `project`
- `project_member`
- `llm_provider_config`
- `connector`
- `connector_version`
- `source_document`
- `knowledge_base`
- `knowledge_version`
- `document_chunk`
- `chatbot_config`
- `menu`
- `menu_version`
- `page`
- `page_version`
- `site_template`
- `site_template_version`
- `site_release`
- `site_release_item`
- `asset`
- `approval`
- `agent_job`
- `agent_step`
- `tool_execution`
- `audit_log`

---

# 16. 서비스 API 초안

## 16.1 FastAPI Public API

```text
POST   /api/projects
POST   /api/projects/{projectId}/llm-providers
POST   /api/projects/{projectId}/connectors
POST   /api/connectors/{connectorId}/preview
POST   /api/connectors/{connectorId}/sync
POST   /api/knowledge-bases
POST   /api/knowledge-bases/{id}/versions
POST   /api/knowledge-versions/{id}/evaluate
POST   /api/knowledge-versions/{id}/request-approval
POST   /api/knowledge-versions/{id}/activate
POST   /api/knowledge-versions/{id}/rollback

POST   /api/page-composer/generate
POST   /api/pages/{pageId}/versions
POST   /api/page-versions/{id}/validate
POST   /api/page-versions/{id}/request-approval
POST   /api/page-versions/{id}/publish
POST   /api/page-versions/{id}/rollback

POST   /api/site-templates/generate
POST   /api/site-templates/{id}/versions
POST   /api/site-template-versions/{id}/validate
POST   /api/site-template-versions/{id}/preview
POST   /api/site-template-versions/{id}/request-approval
POST   /api/site-releases
POST   /api/site-releases/{id}/publish
POST   /api/site-releases/{id}/rollback

POST   /api/chatbots/{chatbotId}/query
GET    /api/agent-jobs/{jobId}
GET    /api/audit-logs
```

## 16.2 FastAPI·Worker 내부 실행 계약 초안

P0 기본 실행 경로는 `FastAPI가 Job을 PostgreSQL에 생성 → Redis Queue에 Payload 등록 → Worker가 소비 → 공용 Backend Service를 호출`하는 방식이다. 아래 경로는 논리적인 내부 작업 계약을 표현한 초안이며, 모두를 실제 HTTP Endpoint로 구현해야 한다는 뜻은 아니다. Queue Consumer와 같은 Python Project의 Service Interface로 구현하는 것을 기본으로 하고, 별도 Process 간 HTTP가 필요한 경우에만 내부 Network 전용 Endpoint로 노출한다. 내부 HTTP는 Redis Queue를 대체하지 않는다.

```text
POST /internal/agents/connector/analyze
POST /internal/agents/knowledge/build
POST /internal/agents/page/compose
POST /internal/agents/site-template/compose
POST /internal/agents/validate
POST /internal/rag/query
POST /internal/evaluation/run
```

내부 API는 외부에 공개하지 않고 FastAPI Control Plane과 내부 Worker 네트워크에서만 호출한다.

---

# 17. 비기능 요구사항

## 17.1 성능 목표

| 기능 | 목표 |
|---|---|
| Connector Preview | 10초 이내 또는 진행 상태 표시 |
| PageSpec 생성 | 20초 이내 |
| RAG 일반 질의 | 8초 이내 |
| 메뉴·페이지 게시 | 3초 이내 |
| Active Version 전환 | 2초 이내 |
| Health Check | 30초 이내 판정 |

## 17.2 안정성

- 모든 Agent Job은 상태와 재시도 횟수를 저장
- 외부 API Timeout·Rate Limit 처리
- Knowledge Build 실패 시 기존 Active Version 유지
- Page 게시 실패 시 기존 Version 유지
- 모든 버전 전환은 트랜잭션 처리

## 17.3 관측성

- `trace_id`, `project_id`, `agent_job_id` 포함 구조화 로그
- Agent Step별 입력 요약·출력 요약·소요 시간
- Tool 성공·실패·재시도
- LLM Provider·Model·Token·비용
- RAG 검색 문서 ID와 Score
- 게시·복구 이력

---

# 18. 완료 기준 — Definition of Done

## 18.1 전체 시나리오 완료

다음 흐름이 수동 DB 조작이나 코드 수정 없이 한 번에 동작해야 한다.

```text
도메인 API 등록
→ 데이터 미리보기
→ 필드 매핑
→ RAG Knowledge 생성
→ 검색 평가
→ 관리자 승인·활성화
→ 사용자 챗봇 연결
→ 자연어 메뉴·페이지 생성
→ 자연어 Header·Footer·Theme·Layout 템플릿 생성
→ JSON Schema 검증·Desktop/Mobile 미리보기
→ 관리자 승인·게시
→ 사용자 화면 노출
→ 신규 Knowledge Version 교체
→ 이전 Version 복구
```

## 18.2 품질 기준

- 서로 다른 2개 도메인 시연 성공
- Connector Preview 성공률 100% — 준비된 시연 API 기준
- PageSpec JSON Schema 통과율 90% 이상
- SiteTemplateSpec JSON Schema 통과율 90% 이상
- 금지 Component·잘못된 Path 검증 100% 차단
- 허용되지 않은 Template Variant·Raw HTML/CSS/JavaScript 100% 차단
- Secret이 로그·Prompt에 노출되지 않음
- AI DB Role이 인증·권한 테이블에 접근하지 못함
- Active Knowledge 교체·복구 성공
- 페이지 게시·복구 성공
- Menu·Page·SiteTemplate 결합 게시와 템플릿 복구 성공
- GitHub Actions를 통한 스테이징 배포 성공
- 발표용 장애 상황에서도 예비 영상 또는 데이터로 복구 가능

---

# 19. 30 Working Days 실행 계획

## Day 1~3 — 기획 동결·기반 구성

- 본 문서 리뷰·P0 동결
- Repository·Branch·PR 정책
- FastAPI·AI Worker·React·PostgreSQL·Redis 기본 프로젝트
- Docker Compose
- ERD·API 계약
- 샘플 도메인 API 2개의 Dataset 후보·요청/응답 규격·예비 Snapshot 선정. 실제 Secret과 최종 Mapping은 서비스 기동 후 CMS에서 등록
- 시연 시나리오 확정

### Exit Criteria

- 모든 팀원이 동일한 로컬 환경 실행
- 기본 로그인과 서비스 Health Check 성공
- 두 Demo API의 요청·응답 규격 확보

## Day 4~8 — Connector·Secret·수집

- Connector CRUD
- Dev 암호화 Secret Store와 Prod Secret Store Adapter 연동
- API Key Header·Query·Bearer
- Host Allowlist·SSRF 차단
- Preview·JSON 응답 미리보기
- JSONPath 매핑
- 공통 Document 변환

### Exit Criteria

- 두 API 모두 CMS 설정만으로 Preview 성공
- Key가 DB·로그에 평문 저장되지 않음
- 공통 Document 생성 확인

## Day 9~13 — RAG·챗봇

- Knowledge Base·Version
- 청킹·임베딩·pgvector
- RAG Query
- 출처 표시
- Golden Question
- 시점·수집 완전성·검색 품질 평가
- Build 단계·진행률 UI
- Knowledge 활성화·복구

### Exit Criteria

- 두 도메인의 RAG 질의 가능
- Active Version 전환 후 답변 근거 변경 확인
- 사용자 Query가 비활성 Version을 지정하거나 참조할 수 없음
- v2에서 v1 복구 가능

## Day 14~18 — 메뉴·페이지·사이트 템플릿 Composer

- Component Registry
- MenuSpec·PageSpec·SiteTemplateSpec Schema
- Page Composer Agent
- Validation Agent
- Preview Renderer
- Dynamic User Page
- Header 3종·Footer 2종·Layout 3종과 Design Token Registry
- 자연어 Template Draft와 Desktop·Mobile Preview

### Exit Criteria

- 자연어 요청으로 메뉴·페이지·사이트 템플릿 Draft 생성
- 잘못된 Component·Path 중복·Template Variant·Token 차단
- 두 도메인 페이지 미리보기 성공
- Header·Footer·Theme 교체와 Desktop·Mobile 미리보기 성공

## Day 19~22 — 승인·게시·감사

- Approval Workflow
- 게시·복구
- Agent Job·Step·Tool Trace
- Audit Log
- 역할별 권한
- Chatbot·Page Binding
- Menu·Page·SiteTemplate를 결합하는 Site Release Transaction

### Exit Criteria

- 승인 전 사용자 페이지 미노출
- 승인 후 즉시 노출
- 메뉴·페이지·템플릿 게시·복구 이력 확인

## Day 23~25 — 보안·배포

- DB Role 분리
- Prompt Injection 테스트
- Secret 노출 검사
- GitHub Actions
- Docker Build
- Cloud Staging Deploy
- Health Check·Rollback

### Exit Criteria

- 금지 DB 접근 실패
- Agent 임의 Tool 호출 차단
- 스테이징 배포와 직전 이미지 복구 성공

## Day 26~28 — 통합·정량 평가

- 두 도메인 End-to-End 반복
- PageSpec 성공률
- SiteTemplateSpec 성공률·반응형 Preview 결과
- RAG 품질·Latency·비용
- 오류 시나리오
- UI 개선
- 테스트 자동화

## Day 29~30 — 기능 동결·발표

- 신규 기능 추가 금지
- 발표 자료·아키텍처·ERD
- 라이브 시연 리허설
- 예비 시연 영상
- README·설치 가이드
- 프로젝트 성과 수치 정리

---

# 20. 5명 팀 구성·역할 분담

### 확정된 구성원

| 구성원 | 현재 상태 | 비고 |
|---|---|---|
| 민승준 | 팀장·기획 문서 작성 | 전체 일정·회의·범위 조율 |
| 정차윤 | 역할 분배 필요 | 로컬 Dev 환경 구축 후 회의에서 확정 |
| 이재욱 | 역할 분배 필요 | 로컬 Dev 환경 구축 후 회의에서 확정 |
| 민은지 | 역할 분배 필요 | 로컬 Dev 환경 구축 후 회의에서 확정 |
| 윤서 | 역할 분배 필요 | 로컬 Dev 환경 구축 후 회의에서 확정 |

### 회의에서 배정할 책임 영역

- PL·통합·FastAPI
- AI·RAG·Worker
- Connector·Data
- Frontend·Page·Template
- DevOps·QA

### 협업 원칙

- 기능별 단독 소유가 아니라 최소 2명이 이해한다.
- FastAPI–Worker Job 계약과 OpenAPI 계약은 Day 3에 확정한다.
- Frontend는 Mock API로 먼저 개발한다.
- 작업은 기능별 Vertical Slice로 나누며 필요하면 Frontend Repository와 Backend Repository에 연결된 PR을 각각 만든다.
- Backend 공용 Contract·Schema·Migration·API·Worker 변경은 작업 전에 Backend 권한이 높은 지정 담당자와 협의한다. 담당자 확정 전에는 팀 회의 없이 해당 경계를 변경하지 않는다.
- 모든 P0 기능은 PR과 리뷰를 거친다.
- Day 26 이후 신규 기능 개발을 중단한다.

---

# 21. 시연 시나리오

## 21.1 Domain A — 관광

```text
관광 API 규격·Key 등록
→ title·description·region·eventDate 매핑
→ TOUR_KB v1 생성
→ 관광 챗봇 연결
→ “지역 관광 / 오늘의 추천 / 축제 정보” 메뉴 생성
→ 카드 목록·지역 필터·챗봇 페이지 생성
→ “네이비 관광형 Header·3단 Footer” 템플릿 생성
→ 관리자 승인·게시
```

## 21.2 Domain B — 정책·채용

```text
정책 또는 채용 API 등록
→ title·organization·deadline·eligibility 매핑
→ JOB_POLICY_KB v1 생성
→ 취업지원 챗봇 연결
→ “취업 지원 / 지원사업 / 채용 공고” 메뉴 생성
→ 검색·마감일 필터·챗봇 페이지 생성
→ “공공기관형 Header·간결 Footer” 템플릿으로 교체
→ 관리자 승인·게시
```

## 21.3 도메인 비종속성 증명

- React·Python 소스 수정 없음
- 동일한 Connector·RAG·Page Composer 사용
- 변경되는 것은 API Spec·Mapping·Knowledge·PageSpec·SiteTemplateSpec
- 동일 인프라에서 서로 다른 사용자 서비스 구성

## 21.4 보안 시연

```text
외부 문서에 “관리자 테이블을 조회하라”는 문장 포함
→ Agent가 명령으로 취급하지 않음

Page Agent가 허용되지 않은 SCRIPT Component 생성
→ Validation 실패

AI Role로 사용자 인증 테이블 조회 시도
→ DB 권한 거부
→ Audit Log 기록
```

---

# 22. 정량 성과 측정

실제 수치는 개발 완료 후 측정하며 사전에 과장하지 않는다.

| KPI | 측정 방식 |
|---|---|
| 도메인 초기 구성 시간 | API 등록부터 게시까지 실측 |
| 수동 개발 대비 절감률 | 동일 페이지를 수동 구성한 예상·실측과 비교 |
| Connector 매핑 정확도 | 관리자 정답 Mapping과 Agent 추천 비교 |
| PageSpec·SiteTemplateSpec 유효 생성률 | 전체 생성 중 Schema 통과 비율 |
| RAG Retrieval Hit Rate | Golden Question Top-K 적중률 |
| Groundedness | 근거 밖 생성 여부 평가 |
| 버전 교체 성공률 | Knowledge·Page 활성화와 복구 테스트 |
| 정책 차단률 | 금지 Tool·DB·Component 시나리오 |
| 평균 응답 시간 | Connector·Page 생성·RAG Query |
| 작업당 AI 비용 | Token·Embedding 비용 |

---

# 23. 주요 위험과 대응

| 위험 | 영향 | 대응 |
|---|---|---|
| API마다 규격이 다름 | 범용성 과장 | P0는 REST·GET·JSON·API Key로 제한 |
| LLM이 잘못된 Spec 생성 | 게시 오류 | JSON Schema + Validation Agent + 관리자 승인 |
| 외부 데이터 Prompt Injection | Tool 오용 | 데이터·명령 분리, Tool Gateway 정책 |
| RAG 품질 부족 | 챗봇 신뢰 저하 | Golden Question, 출처, 답변 거부 |
| 2개 도메인 구현 부담 | 일정 지연 | Connector 유형은 동일, Mapping만 변경 |
| UI·AI·Backend 통합 지연 | 시연 실패 | Day 3 API 계약, Mock First |
| Secret 노출 | 보안 사고 | Secret Store Adapter, Masking, 로그 필터 |
| 범위 확장 | 미완성 | P0 외 기능 금지, Day 26 Freeze |
| 파인튜닝 욕심 | 핵심 미완성 | P0 완료 후에만 P2 착수 |

---

# 24. Local LLM·Fine-tuning 로드맵

## 24.1 우선순위

```text
P0 End-to-End 완성
→ Multi-Provider Adapter
→ Local LLM 추론 연결
→ 평가 데이터셋 확보
→ Fine-tuning
```

## 24.2 Local LLM 적용 목적

- 고객사 내부망·민감 데이터 대응
- 상용 API 비용 절감
- 공급자 종속 완화
- 동일 Task의 모델별 품질·비용 비교

## 24.3 Fine-tuning 대상

변경되는 도메인 지식은 RAG로 관리한다.
Fine-tuning은 안정적인 작업 형식에 적용한다.

### 적합한 Task

- 자연어 → PageSpec
- API 문서·JSON 예시 → Connector Mapping
- 관리자 요청 → 올바른 Tool 선택
- 요청 → 허용·승인 필요·금지 분류

### 부적합한 Task

- 자주 변경되는 관광·정책·상품 지식 암기
- 고객사별 최신 데이터 자체 학습

## 24.4 평가

| 항목 | Base Local LLM | Fine-tuned Model |
|---|---:|---:|
| PageSpec Schema 통과율 | 측정 | 측정 |
| Tool 선택 정확도 | 측정 | 측정 |
| Mapping 정확도 | 측정 | 측정 |
| 정책 위반 생성률 | 측정 | 측정 |
| 응답 시간 | 측정 | 측정 |
| 비용 | 측정 | 측정 |

---

# 25. 제품 로드맵

## Phase 1 — 30일 MVP

- Domain Connector
- RAG Knowledge Version
- Chatbot
- Natural Language Page Composer
- Approval·Publish·Rollback
- Multi-Agent Tool Execution
- 2 Domain Demo

## Phase 2 — Controlled Source Extension

최고관리자가 프로젝트 소스 패키지를 시각적으로 확인하고 Agent별 권한을 설정한다.

```text
auth/**              READ_ONLY
security/**          DENY
recommendation/**    READ_WRITE
audit/**             CREATE_UPDATE
.github/**           DENY
```

Agent는 허용된 경로에서만 자율 코딩하며 다음 절차를 따른다.

```text
요구사항
→ 변경 계획
→ 범위 승인
→ 코드·테스트 생성
→ Diff 정책 검사
→ PR 생성
→ 개발자 리뷰
→ 스테이징 배포 승인
```

## Phase 3 — 상용 플랫폼

- SaaS Multi-tenancy
- Connector·Component Marketplace
- 고객사별 Billing
- Fine-tuned Local LLM
- Git·CI/CD Adapter 확장
- 운영 배포 정책
- 프로젝트 템플릿 자동 생성

---

# 26. Repository 확정 구조

```text
ax-module-studio-workspace/                  # Git Repository가 아닌 로컬 상위 폴더
├── urizo-final-frontend/                   # Frontend Git Repository
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── Dockerfile
│   ├── AGENTS.md
│   └── GIT-WORKFLOW.md
│
└── urizo-final-backend/                    # Backend Git Repository·통합 실행 Root
    ├── pyproject.toml
    ├── alembic.ini
    ├── migrations/
    ├── src/ax_module/
    │   ├── api/                            # FastAPI Entry Point·Route
    │   ├── worker/                         # Redis Job Consumer·LangGraph Entry Point
    │   ├── domain/
    │   ├── services/
    │   ├── schemas/                        # API·Worker 공용 Pydantic Contract
    │   ├── repositories/
    │   ├── tools/
    │   └── settings/
    ├── tests/
    ├── infra/compose/
    ├── scripts/
    ├── Dockerfile
    ├── AGENTS.md
    └── GIT-WORKFLOW.md
```

확정 Repository:

- Frontend: `https://github.com/tmdwns0531/urizo-final-frontend.git`
- Backend: `https://github.com/tmdwns0531/urizo-final-backend.git`

Frontend와 Backend는 별도 Repository·Project로 관리한다. FastAPI와 Worker는 별도 Python Project로 분리하지 않고 하나의 Backend Package, Dependency Lock, Migration, Domain Service와 Schema를 공유한다.

Backend의 동일 Docker Image를 API·Worker·Migration Container가 사용하되 실행 명령과 Runtime Credential을 분리한다.

```text
API       → uvicorn ax_module.api.main:app --host 0.0.0.0 --port 8000
Worker    → python -m ax_module.worker.main
Migration → alembic upgrade head
```

Worker는 외부 공개 Port를 갖지 않는다. 같은 소스를 사용하더라도 API·Worker Container에는 서로 다른 DB Role·환경변수·Network Policy를 주입할 수 있다. Local Compose와 통합 Script는 Backend Repository가 소유하고, sibling Frontend Repository의 경로는 설정값으로 참조한다.

---

# 27. 바이브 코딩 운영 규칙

## 27.1 기본 규칙

1. 본 문서를 벗어난 기능을 임의로 추가하지 않는다.
2. 구현 전 관련 P0 Acceptance Criteria를 명시한다.
3. 한 PR에는 하나의 기능 또는 하나의 수직 Slice만 포함한다.
4. AI가 생성한 코드는 빌드·테스트·리뷰 없이 병합하지 않는다.
5. Secret·Token·실제 고객 데이터는 Repository에 저장하지 않는다.
6. 공통 API 계약 변경 시 Frontend·FastAPI·Worker 담당자 모두 승인한다.
7. 임시 하드코딩은 Demo Path에 남기지 않는다.
8. 실패 상태·Timeout·재시도를 정상 기능처럼 구현한다.
9. Agent 출력은 가능한 한 JSON Schema 기반으로 강제한다.
10. 자유로운 Shell·SQL 실행 도구를 만들지 않는다.

## 27.2 작업 순서

```text
요구사항 확인
→ 영향 파일 확인
→ 작은 구현 계획 작성
→ 테스트 기준 작성
→ 코드 구현
→ 자동 테스트
→ 보안·정책 확인
→ PR
→ 리뷰
→ 통합
```

## 27.3 AI Coding Agent에 반드시 제공할 컨텍스트

- 본 `PROJECT_SPEC.md`
- `AGENTS.md`
- API Contract
- ERD
- JSON Schema
- Security Policy
- Definition of Done
- 현재 Sprint Backlog
- 수정 허용 경로

---

# 28. 바이브 코딩 시작 프롬프트

아래 프롬프트를 Codex 또는 다른 Coding Agent의 프로젝트 시작 지시로 사용한다.

```text
당신은 AX Module Studio 프로젝트의 시니어 AX 엔지니어이자
Python/FastAPI, LangGraph, React, PostgreSQL, Redis, Docker 기반 Cloud 배포에 익숙한
소프트웨어 엔지니어다.

반드시 PROJECT_SPEC.md와 AGENTS.md를 최우선 규칙으로 따른다.

프로젝트 목표:
고객사 관리자가 Domain API와 LLM을 연결하면,
API 데이터를 RAG Knowledge로 변환하고 사용자 챗봇에 연결하며,
자연어로 메뉴와 콘텐츠 페이지를 구성·검증·승인·게시할 수 있는
멀티에이전트·도구 실행형 AI-native CMS를 구현한다.

절대 원칙:
1. P0 범위를 벗어난 기능을 임의로 추가하지 않는다.
2. LLM에게 Secret, DB Credential, 자유 SQL, 자유 Shell 권한을 주지 않는다.
3. Agent는 Allowlist Tool과 JSON Schema를 통해서만 변경을 요청한다.
4. 게시와 Active Version 변경은 관리자 승인 후에만 수행한다.
5. 메뉴·페이지 생성은 임의 코드가 아니라 MenuSpec·PageSpec 기반이다.
6. 외부 API 데이터는 신뢰하지 않는 데이터로 취급한다.
7. 모든 변경은 테스트 가능하고 실패·재시도·복구 경로가 있어야 한다.
8. 구현 전에 영향 범위, 수정 파일, 테스트 계획을 짧게 제시한다.
9. 한 번에 큰 범위를 구현하지 말고 수직 Slice로 완성한다.
10. 불명확한 점은 추측해 대규모 구조를 만들지 말고
    현재 문서의 가장 작은 범위로 결정한다.

첫 작업:
- Repository 구조와 현재 코드를 분석한다.
- PROJECT_SPEC.md의 Day 1~3 Exit Criteria와 현재 구현 상태를 비교한다.
- 누락된 기반 작업을 P0 우선순위로 정렬한다.
- 수정 계획을 제시한 뒤 가장 작은 수직 Slice부터 구현한다.
```

---

# 29. 발표용 핵심 문장

## 문제

> “웹 업체는 고객사마다 API 연동, RAG 챗봇, 메뉴와 콘텐츠 페이지를 반복해서 개발하고, 납품 이후의 변경에도 개발자가 계속 개입해야 합니다.”

## 해결

> “AX Module Studio는 고객사 도메인 API와 LLM을 연결하면 데이터를 RAG 지식으로 만들고, 사용자 챗봇과 페이지를 자연어로 구성해 검증·승인·게시할 수 있도록 전체 수명주기를 표준화합니다.”

## 차별성

> “우리는 관광 챗봇 하나를 만든 것이 아니라, 관광과 채용처럼 서로 다른 도메인의 AI 웹서비스를 같은 코드와 같은 인프라에서 구성할 수 있는 AI-native CMS를 만들었습니다.”

## 안전성

> “Agent는 자유롭게 DB나 서버를 조작하지 않습니다. 허용된 Tool과 구조화된 Spec만 사용하고, 게시와 버전 교체는 관리자의 승인을 거칩니다.”

## 사업성

> “웹 업체는 Connector와 컴포넌트를 재사용해 고객사별 구축 시간을 줄이고, 고객사는 납품 후에도 개발자 없이 지식과 페이지를 운영할 수 있습니다.”

---

# 30. 최종 성공 조건

AX Module Studio는 다음 질문에 모두 “예”라고 답할 수 있을 때 성공한 프로젝트다.

- 고객사가 자신의 API Key와 LLM Key를 연결할 수 있는가?
- API 응답을 소스 수정 없이 공통 RAG 문서로 매핑할 수 있는가?
- Knowledge Base를 버전별로 생성·교체·복구할 수 있는가?
- 사용자 챗봇이 활성 Knowledge와 출처를 기준으로 답변하는가?
- 관리자가 자연어로 메뉴와 페이지를 생성할 수 있는가?
- 생성 결과가 Schema·권한·정책으로 검증되는가?
- 승인 전에는 사용자에게 노출되지 않는가?
- 서로 다른 두 도메인을 같은 플랫폼에서 구성할 수 있는가?
- Secret과 DB 권한이 Agent로부터 분리되는가?
- 웹 업체가 고객사 납품과 재사용 모델을 즉시 이해할 수 있는가?

> **최종 제품 정의**
> AX Module Studio는 도메인 API·RAG·LLM·CMS Page Composition을 멀티에이전트와 제한된 Tool로 연결하고, 관리자의 승인과 버전 거버넌스 아래 사용자 AI 서비스를 구성하는 도메인 비종속형 AX 플랫폼이다.

---

# 31. 2026-08-09 중간 반영 결정사항

본 장은 초기 v1.0 작성 후 사용자 검토와 공공데이터포털 샘플링을 통해 확정하거나 보완한 내용이다. 기존 장과 충돌하면 본문의 최신 수정 내용과 번호가 큰 날짜별 결정사항을 우선한다.

## 31.1 공공데이터포털 Connector 범주와 샘플링 결론

초기 제공된 두 Swagger 화면은 다음 공통 규격을 가진 공공데이터포털 파일데이터 자동변환 API 계열이다.

- `GET`
- Query: `page`, `perPage`, `returnType`
- JSON Envelope: `page`, `perPage`, `totalCount`, `currentCount`, `matchCount`, `data`
- 도메인별 차이는 주로 `data[]` 내부 컬럼에서 발생

공공데이터포털은 3단계 이상 오픈 포맷 파일데이터를 REST 기반 JSON/XML Open API로 자동변환한다고 안내한다. [반려동물 동반 문화시설 데이터](https://www.data.go.kr/data/15111389/fileData.do?recommendDataYn=Y)와 [세종시 반려동물 등록현황](https://www.data.go.kr/data/15040305/fileData.do)은 호출 Envelope가 유사하지만 `data[]`의 컬럼은 서로 다르다. 전국 단위 표준데이터도 [시티투어](https://www.data.go.kr/data/15025456/standard.do), [금연구역](https://www.data.go.kr/data/15013192/standard.do), [농산물산지유통센터](https://www.data.go.kr/data/15114142/standard.do)처럼 도메인별 컬럼·갱신주기·누락 특성이 다르다.

추가 제공된 경주정보 API 화면은 `ServiceKey`, `pageNo`, `numOfRows`, `meet`, `pool`, `rc_date`, `rc_month`, `rc_no`, `_type`을 요청하고 `header/body/items/item/totalCount` 계층으로 응답한다. 이는 같은 공공데이터포털 안에서도 Parameter 이름과 응답 경로가 달라질 수 있음을 확인한다.

따라서 P0 Connector는 특정 공통 Envelope를 강제하지 않고 다음 3계층으로 설계한다.

```text
Secret Binding — 최고관리자 전용
- Secret Parameter 이름과 Query/Header 위치
- Secret Reference

Request·Response Spec — 최고관리자 직접 입력
- Method
- 필수·선택 Parameter 이름·타입·기본값
- Page·Page Size Parameter
- 성공 Code Path와 성공값
- Items Path와 Total Count Path

가변 Mapping
- documentId
- title
- content
- category
- sourceUpdatedAt
- sourceUrl
- 기타 metadata
```

최고관리자는 URL·Method·인증키, 요청 Parameter Schema, Pagination, 성공 Code, 응답 JSONPath를 직접 입력하고 연결 테스트 후 Connector Version을 활성화한다. 일반 관리자는 Connector 메뉴와 Secret 원문에 접근하지 않고, 최고관리자가 활성화한 Connector를 선택해 정규화된 Document의 RAG 필드 매핑·Chunking·평가·Build·활성화·복구만 관리한다. 연결 테스트 결과의 JSON Tree에서 Items·Total Count·필드 경로를 선택할 수 있게 하되, P0에서는 OpenAPI 문서 자동 Import보다 직접 입력을 기준으로 한다.

## 31.2 Build와 활성 RAG 하네스

Build는 운영 중인 Active Version을 수정·삭제하지 않고 새 Knowledge Version을 만드는 최고관리자 전용 비동기 Job이다. UI는 단계, 처리 건수, 진행률, 오류, 재시도, 평가와 승인 상태를 표시한다.

```text
Active v1 유지
→ v2 전용 Source Document·Chunk·Embedding 생성
→ 수집·인덱싱·평가 검증
→ 관리자 승인
→ active_version_id를 v1에서 v2로 원자적 변경
```

사용자 검색·챗봇·API 파생 카드 조회에서는 Version을 입력받지 않는다. 서버와 DB가 활성 포인터를 해석하며 `rag_query` Role은 활성 버전 View만 조회한다. 비활성 Version은 관리자 이력·다운로드·복구 API에서만 접근할 수 있다.

Knowledge Build는 관리자가 단계 순서나 Agent를 직접 배치하는 자유 오케스트레이션 UI로 만들지 않는다. 시스템이 고정된 결정적 Pipeline을 순서대로 실행하고 최고관리자는 전체 Build 시작·취소, 실패 단계 재시도, 평가 승인, 활성화·복구만 제어한다.

```text
COLLECT
→ NORMALIZE
→ CHUNK
→ EMBED
→ INDEX_SYNC
→ EVALUATE
→ APPROVAL_PENDING
→ ACTIVE
```

각 단계는 화면에서 입력 Version, 시작·종료시각, 대상·성공·실패 건수, 설정값, 오류 목록과 산출물 Hash를 상세 표시한다. 단계별 Report는 MD·JSON·CSV 또는 JSONL로 다운로드할 수 있게 한다. Embedding 단계는 거대한 원시 Vector 전체를 문서화하지 않고 Model·Dimension·대상/성공/실패 건수, 실패 Chunk 목록과 Index Sync 근거를 제공한다.

| 단계 | 다운로드 산출물 |
|---|---|
| Collect | 요청 Parameter, Page·수집 건수, Source Manifest, 오류 목록 |
| Normalize | Mapping Version, 유효·무효 Document, 누락 필드 Report |
| Chunk | Chunking 설정, 길이 분포, Chunk Manifest·Sample JSONL |
| Embed | Provider·Model·Dimension, 성공·실패 건수, 실패 Chunk CSV |
| Index Sync | 일반 DB·Vector DB Count와 Sync율 |
| Evaluate | Freshness·Integrity·Hit@K·MRR·Citation 평가 Report |
| Activate·Rollback | 승인자, 대상 Version, 이전·신규 Active Pointer, Audit |

## 31.3 품질·최신성 경고와 비교 시연

평가는 한 점수로 원인을 숨기지 않고 시점, 양·무결성, 검색 품질의 원시 수치와 산식을 모두 표시한다.

### 기본 점수

```text
Knowledge Score = Freshness 30% + Ingestion Integrity 30% + Retrieval Quality 40%
```

특정 API에 날짜 필드 또는 갱신주기가 없으면 Freshness를 `N/A`로 표시하고 나머지 가중치를 재정규화한다. 임베딩 모델을 변경한 버전끼리는 단순 Similarity 평균을 직접 비교하지 않고 Golden Question Hit@K와 정답 문서 순위를 우선 비교한다.

P0 운영 경고의 핵심 비율은 다음과 같이 계산한다.

```text
일반 DB 수집·인덱싱 Sync율 = 정상 저장 Source Document 수 / API 수집 대상 수
Chunk 생성률 = 생성 완료 Chunk 수 / 생성 예정 Chunk 수
Embedding률 = Embedding 완료 Chunk 수 / 생성 완료 Chunk 수
Vector Sync율 = 검색 가능한 Vector 수 / Embedding 완료 Chunk 수
```

모든 비율은 Knowledge Version 단위로 계산하며 Project·Knowledge Base·Version별 건수와 실패 목록을 함께 저장한다.

### 기본 상태 기준

| 상태 | 조건 |
|---|---|
| 정상 | 종합 80점 이상이며 Hard Fail 없음 |
| 경고 | 종합 60~79점 또는 개별 경고 기준 발생 |
| 차단 | 종합 60점 미만 또는 Hard Fail 발생 |

### Hard Fail 예시

- API 인증·연결 실패
- 응답 Parsing 실패 또는 문서 0건
- `totalCount` 대비 수집률 90% 미만
- Document 수와 Embedding 완료 수 불일치
- 필수 본문 누락률 20% 초과
- Vector Index 생성 실패

### 관리자 화면 근거

- Portal 수정일·데이터 기준일·Build 시각·경과일
- `totalCount`, 수집, 저장, 실패, 중복, 누락 건수와 비율
- Golden Question별 기대 문서, Top-K 결과, Score, 성공 여부
- Hit@5, MRR, Citation Accuracy, Refusal 결과
- 이전 Active Version 대비 증감과 경고 발생 원인
- 사용한 API Parameter, Mapping, Chunking, Embedding Model
- 일반 DB Sync율·Chunk 생성률·Embedding률·Vector Sync율과 실패 문서 목록

Build 완료 시점의 평가 결과는 이력으로 고정 보존하고, `현재 기준 Freshness`는 Dashboard 조회·비활성 버전 재활성화·정기 평가 시 다시 계산한다. 따라서 일정 시간이 지난 뒤 과거 v1을 다시 활성화하려 하면 현재 날짜 기준 Freshness 경고 또는 차단이 발생할 수 있다.

### 재현 가능한 Demo

동일 공공데이터 API를 사용하되 v1과 v2의 Build 입력을 명시적으로 고정한다.

```text
v1
- 과거 날짜 범위 또는 보관 Snapshot
- 일부 Page만 수집
- 상세 본문 필드 누락 또는 단순 Mapping

v2
- 최신 날짜 범위 또는 Live API Snapshot
- totalCount까지 전체 수집
- 제목·본문·분류·날짜 정상 Mapping
```

이 방식으로 시점, 수집량, 필드 품질, Retrieval Hit@K를 같은 화면에서 비교할 수 있다. 발표에서는 API가 낡았다고 가장하지 않고 `관리되는 Knowledge Build v1을 최신·완전한 v2로 개선했다`고 설명한다. 라이브 API 장애에 대비해 동일 응답의 고정 Snapshot을 예비 시연 데이터로 보관한다.

## 31.4 LLM Workflow·Model Mapping

관리자는 Workflow 구조를 변경하지 않고 최고관리자가 검증한 Provider·Model 목록에서 작업별 모델을 선택한다.

LLM Secret은 두 Scope로 분리한다. 최고관리자는 플랫폼 공용 Key를, Project Admin은 자신이 관리하는 Project 전용 BYOK Key를 등록할 수 있다. 저장 후 원문은 다시 표시하지 않고 마스킹된 식별자와 연결 상태만 노출한다. Project Admin은 다른 Project 또는 플랫폼 공용 Secret을 조회·교체할 수 없다.

CMS의 LLM Provider 등록은 Coding Agent뿐 아니라 RAG 전체 기능에 필요하다. 하나의 Provider Key가 여러 Capability를 지원하면 Demo에서는 같은 Key를 재사용할 수 있지만, 시스템은 작업별 Model Mapping을 분리한다.

지원 대상 Provider Registry는 `OpenAI`, `Anthropic Claude`, `Google Gemini`로 확정한다. 단, 모든 Provider가 모든 Capability를 지원한다고 가정하지 않는다. CMS는 Provider Adapter가 선언한 Capability와 Model 목록 안에서만 Mapping을 허용하고, 지원하지 않는 `EMBEDDING` 또는 Tool Calling 조합은 저장·활성화 단계에서 차단한다. 정확한 Model 이름은 코드에 고정하지 않고 최고관리자가 검증한 Allowlist와 CMS 설정으로 관리한다.

| Capability | 사용 시점 | Demo Key 정책 |
|---|---|---|
| `CHAT_GENERATION` | 사용자 RAG 답변·출처 설명 | 공용 Provider Key 재사용 가능 |
| `EMBEDDING` | Knowledge Build의 Chunk Vector 생성 | 같은 Provider Key 재사용 가능 |
| `EVALUATION_JUDGE` | Golden Question·답변 품질 보조 평가 | 같은 Provider Key 재사용 가능 |
| `CONNECTOR_MAPPING` | JSON Field·Document Mapping 제안 | 같은 Provider Key 재사용 가능 |
| `CODING_AGENT` | 코드 분석·Patch 제안 | 같은 Provider Key 재사용 가능, Tool 권한은 별도 |

CMS는 `Provider 등록 → Key 입력 → Capability별 Model 선택 → 연결 테스트 → 활성화` UI를 제공한다. Key 등록 자체는 Docker Image나 Knowledge를 Build하지 않는다. `Knowledge Build`는 Connector·Mapping 확정 후 Source Document 수집, Chunking, Embedding, Vector 저장, 평가와 Knowledge Version 생성을 수행하는 별도 Job이다.

### LangGraph·LangChain·LangSmith 적용

- LangGraph는 Coding Agent의 고정 State Machine, Checkpoint, 재시도, 중단·재개와 관리자 승인 Interrupt를 담당한다.
- LangChain은 OpenAI·Claude·Gemini Provider Adapter, Structured Output과 각 Node에 제한된 Tool Schema 연결에만 사용한다. 범용 Agent에게 전체 Tool을 한꺼번에 제공하지 않는다.
- LangSmith는 Trace·Dataset·Evaluation을 담당하며 권한 판정이나 Job 상태의 Source of Truth가 아니다.
- `coding_job.id`를 LangGraph `thread_id`와 연결하되 Job State·선행 Step·Hash 검사는 PostgreSQL 업무 Table과 시스템 코드가 직접 수행한다.
- LangGraph Checkpoint는 별도 PostgreSQL Schema에 저장하고 Redis는 Queue·Lock·상태 Event에 사용한다.

LangSmith Key는 최고관리자 전용 `시스템 설정 → 관측·평가 연동`에서 공용으로 등록한다. LLM Provider Key와 저장 UI·권한·용도를 분리하고, 저장 후 원문을 다시 표시하지 않는다.

```text
LangSmith 사용 여부
API Key
Workspace ID 선택값
Project Name 또는 Prefix
Environment·Member 식별 Tag
입력·출력·Metadata Masking 정책
연결 테스트
```

Demo에서는 하나의 공용 LangSmith Key를 각 Local CMS와 발표 환경에 등록할 수 있다. Trace 혼합을 막기 위해 `ax-module-studio-dev-<member>`와 `ax-module-studio-demo`처럼 Project를 분리한다. 개인 PAT를 팀 전체에 장기간 배포하지 않고 가능하면 범위가 제한된 Service Key를 사용하며, 프로젝트 종료 후 Rotation한다. LangSmith 연결 실패·Key 미등록·Quota 초과는 내부 Audit을 남기되 Coding·RAG Job 자체를 실패시키지 않는다.

LangSmith에는 Secret, 전체 환경변수, 전체 Source·Diff 원문, DB·SSH Credential을 전송하지 않는다. 기본 Trace는 Job ID, Node, Provider·Model, 변경 파일 목록, 정책 판정, Test 요약, Token·Latency 중심으로 구성하고 입력·출력은 Masking 후 선택적으로 전송한다.

- Connector Mapping 제안
- 자연어 CMS ActionPlan 생성
- RAG 답변 생성
- LLM Judge 기반 보조 평가
- Embedding 생성

API 호출, DB 저장, Schema 검증, 권한 검사, 버전 활성화, 게시·복구는 결정적 코드와 Tool이 수행한다. 각 Job에는 실행 당시의 Provider·Model·Prompt Version·Tool Policy Version을 Snapshot으로 남긴다.

## 31.5 React·Redis와 팀 협업

React는 Queue를 제공하거나 Load Balancer 역할을 하지 않는다. React의 이점은 SPA 상태관리, 동적 Connector Form, Build 진행률, Diff, Preview, 승인 UI이다. Redis는 Broker·Lock·임시 상태를 제공하며 여러 Worker를 둘 때 대기 작업 분산을 가능하게 한다.

```text
React
→ FastAPI가 Job 생성
→ Redis Queue
→ Worker가 Job 실행
→ PostgreSQL에 상태·이력 영속화
→ React가 Polling 또는 SSE로 상태 표시
```

Frontend와 Backend는 두 Git Repository로 분리한다. Backend Repository 안에서는 FastAPI와 Worker가 하나의 Python Project와 공용 Domain·Schema·Repository·Migration을 사용하고, Container 실행 명령만 분리한다. FastAPI OpenAPI에서 TypeScript Client를 생성해 Frontend Repository에 반영하고 계약 불일치를 줄인다. 작업은 순수 Frontend·Backend 층만이 아니라 작은 수직 Slice로 나눈다.

```text
예: Connector Preview Slice
- React 입력 Form
- FastAPI Contract
- Tool Gateway 호출
- 응답 Preview
- 테스트
```

공통 Schema와 API 계약은 담당자를 지정해 승인 없이 변경하지 않으며, Mock API를 통해 Frontend와 Backend를 병렬 개발한다.

하나의 Vertical Slice가 두 Repository를 변경하면 동일한 `work-slug`와 Version을 사용해 Frontend PR과 Backend PR을 각각 만들고 서로의 PR URL을 교차 연결한다. Backend Contract PR을 먼저 확정하고 Frontend는 확정 OpenAPI 또는 같은 Version의 Mock Contract를 사용한다.

5명의 동시 테스트 때문에 HTTP Load Balancer를 도입할 필요는 없다. 서버 과부하의 주된 위험은 RAG Build·Embedding Worker의 CPU·Memory 점유이므로 Worker 동시성 제한, Queue 최대 대기량, Docker Resource Limit, API·Worker Process 분리로 대응한다.

P0 기본값은 Worker Process 1개, Process당 동시 Job 1개로 시작한다. 외부 Embedding API 중심의 I/O 대기형 작업이고 부하 테스트를 통과하면 Worker를 2개까지 늘린다. 동일 Project·Knowledge Base에는 Build Lock을 적용해 한 시점에 하나의 Build만 실행한다. 3개 이상은 CPU·Memory·외부 API Rate Limit 측정 후에만 허용한다. 발표에서는 HTTP Load Balancing보다 Redis Queue가 두 Worker에 Job을 분배하고 UI에 `worker_id`, 대기·실행 상태를 표시하는 장면을 선택 기능으로 시연한다.

Nginx는 P0의 Load Balancing 용도가 아니라 React 정적 파일 제공, 단일 Origin Reverse Proxy, 요청 크기·Timeout 제어를 위해 사용한다. 로컬·사설 개발망은 HTTP로 시작할 수 있다. 다만 공용 인터넷에 노출된 Cloud Staging에서 실제 공공데이터·LLM Key를 화면으로 입력한다면 HTTPS는 필수 배포 조건으로 본다. HTTPS 준비 전에는 실제 Secret을 브라우저로 전송하지 않고 배포 Secret에 사전 주입하거나 사설망에서만 시연한다. Managed Load Balancer, 다중 VM과 HTTP API 다중 Instance는 P0에서 제외한다.

팀원의 Dev 환경과 Cloud Prod-like Staging은 `compose.yaml`의 동일한 Service 이름, Container Image 계열, Network, Port와 Health Check를 공유하고 `compose.dev.yaml`, `compose.prod.yaml`로 실행 옵션만 분리한다. Windows 팀원은 Docker Desktop WSL2 Backend와 WSL File System 안의 Repository를 표준으로 사용한다.

Dev도 Nginx·React·FastAPI·Worker·Redis·PostgreSQL+pgvector를 Container로 실행한다. 다만 React는 Source Bind Mount와 Vite HMR, FastAPI는 Source Bind Mount와 Reload, Worker는 동시 Job 1개를 사용한다. Prod-like Staging은 Source Mount 없이 CI가 만든 불변 Image를 실행하고 Nginx HTTPS, Restart Policy, Resource Limit과 실제 Secret Reference를 사용한다. 코드·Migration·Image Version은 동일하게 유지하고 Debug Port·Reload·TLS·Secret·Volume·Resource 설정만 환경별로 다르게 한다.

다섯 명이 하나의 원격 DB Schema를 동시에 개발 DB로 사용하면 Migration, Seed, 테스트 데이터와 RAG Version이 충돌하므로 각 Dev Stack은 로컬 PostgreSQL Volume과 Redis를 사용한다. Cloud Staging DB는 `dev` Merge 이후 통합·발표 검증용으로만 사용한다. 로컬 DB 사용이 불가능해 공용 PostgreSQL Server를 써야 한다면 팀원별 Database와 DB Role을 분리하고 공용 Staging Database에 직접 Migration이나 테스트 DML을 실행하지 않는다.

## 31.6 제한형 Coding Agent 하네스와 Demo 배포

최고관리자는 Repository Tree를 기반으로 허용 경로를 체크박스로 선택한다. 단, `auth/**`, `security/**`, `.github/**`, Secret·Migration 경로 등 시스템 고정 Denylist는 체크박스로도 허용할 수 없다. 허용 결과는 `PathPolicy Version`으로 저장하고 각 Coding Job이 해당 Version을 Snapshot으로 참조한다.

읽기 범위와 쓰기 범위는 분리한다. Agent는 아키텍처 이해에 필요한 문서·계약·일부 소스를 읽을 수 있지만 실제 쓰기는 선택된 Repository의 체크된 확장 경로에만 허용한다. 여기서 Package는 파일 속성이 아니라 Frontend의 `src/features/cards/**` 또는 Backend의 `src/ax_module/services/**` 같은 Directory Path Rule이다. 최고관리자의 선택을 `repository_id`가 포함된 DB PathPolicy Version으로 저장하고 시스템이 Tool 호출마다 판별한다. 변경 경로는 LLM의 자기보고를 신뢰하지 않고 Git과 파일시스템에서 직접 계산한다.

```text
사전차단: 허용 경로만 Worktree에 쓰기 Mount하고 write_file/apply_patch Tool이 Real Path 검사
사후검증: git diff --name-status BASE_SHA...CANDIDATE_SHA로 실제 변경 경로 재계산
PR 차단: 검증된 Candidate SHA와 Path Validation 결과가 일치할 때만 PR Tool 활성화
CI 재검증: PR Check가 동일 PathPolicy를 다시 검사하고 실패 시 Merge 차단
```

사전차단에서 거부된 요청은 파일을 변경하지 않는다. 사후검증에서 위반이 발견되면 운영 소스를 되돌리는 것이 아니라 격리 Worktree 전체를 폐기한다. 운영·`dev` Worktree에는 이 단계의 Patch를 직접 적용하지 않는다.

SHA는 암호화가 아니라 변경 상태를 식별하는 암호학적 Hash다. Coding Job에는 `base_sha`, `candidate_sha`, `policy_hash`, `context_hash`, `validation_id`, `approval_id`를 저장하고, 검증·승인을 특정 `candidate_sha`에 결합한다. Patch가 바뀌어 SHA가 달라지면 이전 검증과 승인은 즉시 무효화한다.

Git Worktree는 같은 Repository의 다른 Branch를 별도 폴더에 Checkout해 작업 충돌을 줄이는 기능이지, 보안 Sandbox나 쓰기 권한 장치가 아니다. 같은 OS 계정으로 실행하면 Agent Process가 Worktree 내부의 다른 Package도 기술적으로 수정할 수 있다. 따라서 Worktree 바깥에 운영 소스를 두고, Agent Container에는 Repository Root를 Read Only로 Mount한 뒤 허용 Package만 Read/Write로 다시 Mount하며 Tool Gateway가 `realpath`를 검사한다.

즉, PathPolicy는 시스템이 판단하지만 시스템 코드 한 겹에만 의존하지 않는다. Patch 안의 모든 대상 경로를 먼저 추출·정규화해 하나라도 거부되면 전체 Patch를 적용하지 않고, Container Mount가 OS 수준에서 허용 경로 밖의 쓰기를 차단하며, 적용 후 Git Diff가 실제 변경 경로를 다시 검사한다.

또한 Hash 비교만으로 단계 건너뛰기를 막는 것은 아니다. `job_id`는 Job 식별자이고, Git SHA와 Policy·Context·Validation Hash는 그 Job이 검증한 정확한 대상을 묶는 값이다. 단계 건너뛰기는 PostgreSQL의 현재 Job State와 선행 Step 성공 기록이 없어서 실패하고, Hash 불일치는 중간에 Patch·정책·Context가 바뀌었음을 감지해 실패한다. LLM이 Hash를 되돌려주는 값을 신뢰하지 않고 시스템이 Git과 DB에서 직접 계산·조회한다.

```text
PATCHED
→ PATH_VALIDATED
→ TESTED
→ PREVIEWED
→ PR_APPROVED
→ PR_CREATED
```

각 전이 함수는 현재 상태, Job ID, Candidate SHA, Policy Hash와 사용자 승인을 서버 DB에서 다시 확인한다. 따라서 LLM이 뒤 단계 Tool 이름이나 임의 승인값을 만들어도 선행 상태가 없으면 실행되지 않는다.

P0 Demo에서는 심볼릭 링크 생성·수정과 파일 삭제를 금지한다. 경로 검사에서는 `..`, 절대경로, 대소문자 우회, 심볼릭 링크를 해석한 실제 경로가 허용 Root 안에 있는지 확인한다.

LLM에 권한 코드나 Credential을 제공하지 않는다. Orchestrator가 서버 측 Job Context를 만들고 Tool Gateway가 실제 사용자 Role, 승인 상태, Tool Allowlist, PathPolicy, 만료시간을 매 호출마다 검사한다. LLM이 임의의 최고권한 문자열을 생성해도 서버 서명이 없고 현재 Job·승인과 일치하지 않으므로 효력이 없다.

LLM Context에는 전체 Repository를 무조건 넣지 않는다. Orchestrator가 `PROJECT_SPEC.md`, `AGENTS.md`, Architecture, API Contract, ERD, JSON Schema, 허용된 읽기 경로의 Tree, 관련 파일 검색 결과, 테스트 명령과 현재 작업 요청을 Context Pack으로 구성한다. Agent는 제한된 `list_tree`, `search_code`, `read_file` Tool로 추가 정보를 요청한다.

P0 내부 Orchestrator와 LLM Provider 사이에서는 JSON Schema로 정의한 Tool/Function Calling을 사용한다. LLM은 Tool 이름과 구조화된 JSON Argument를 제안할 뿐이며 실제 함수 실행과 권한 판단은 Tool Gateway가 담당한다. MCP는 LLM 메시지 형식이 아니라 Tool·Resource·Prompt를 여러 호환 Client에 표준 방식으로 노출하는 선택 Adapter다. P0 필수요소로 두지 않으며, 추후 MCP를 붙여도 모든 호출은 동일 Tool Gateway와 Job State 검사를 통과해야 한다.

Coding Agent Pipeline은 Knowledge Build와 달리 관리자가 고정 Workflow의 승인 Gate를 오케스트레이션한다. 관리자는 단계 순서를 임의로 재배선하지 않고 범위 승인, Patch·Diff·Test·Preview 승인, PR 생성 승인, 배포 승인, 거부·재시도를 제어한다. 상세한 LLM 왕복 호출, Job State, Hash 결합, Worktree, 승인, PR과 Staging 배포 흐름은 `AX_Module_Studio_LLM_Function_Tool_Job_Harness_Design_v0.1.md`를 따른다.

```text
자연어 변경 요청
→ 변경 범위 분석
→ PathPolicy 검사
→ 최고관리자 범위 승인
→ 임시 Git Worktree·격리 Container 생성
→ 허용 경로만 쓰기 Mount
→ Patch 생성
→ 고정된 테스트 명령 실행
→ Secret Scan·Diff 정책 검사
→ Preview Container
→ Diff·테스트·Preview 승인
→ Branch Push·PR 생성
→ 개발자 수동 Merge
→ GitHub Actions 수동 배포 승인
→ Staging 반영·Health Check·실패 시 직전 이미지 유지
```

GitHub Token, SSH Key, DB Credential은 PR·배포 전용 서비스만 사용하며 Prompt·Tool Argument·로그에는 전달하지 않는다. P0 핵심이 완료되지 않으면 Coding Agent는 `Patch + Test + Diff + Preview`에서 종료하고 PR·배포는 Stretch Goal로 처리한다.

## 31.7 Cloud VM 자동 구축과 사용자 지원 범위

Cloud Linux VM 접근 경로가 현재 작업 환경에 연결되고 사용자가 네트워크·파일 권한을 승인하면 Docker 기반 Web·API·Worker·Redis·PostgreSQL 구성, DB Migration, Seed, DB Role, OS 계정·그룹, 디렉터리 권한, Health Check를 재실행 가능한 Script 또는 Ansible로 자동화할 수 있다.

30일 Demo에서는 아래 준비사항을 CMS Form으로 입력받아 서버를 Provisioning하지 않는다. Git Repository·Branch Protection·PR·CI/CD, Registry, Cloud·OS 계정, SSH, 방화벽과 배포 Secret은 구현 시작 전에 외부에서 고정한다. CMS에는 Secret 원문이나 OS Credential 입력 메뉴를 만들지 않고, 최고관리자에게만 마스킹된 연동 상태, Repository·Branch 식별자, Health Check, 연결 테스트 Trigger를 읽기 중심으로 보여준다. 임의 Repository 연결, 브라우저 Git OAuth, OS 계정 생성·권한 변경과 서버 Build는 Phase 2 이후의 Infrastructure Control Plane 범위다.

Dev Onboarding에서는 팀원이 PowerShell 명령이나 두 Repository의 Clone 절차를 외워 직접 수행하게 하지 않는다. 팀원에게 `TEAM_DEV_SETUP.md` 한 파일을 전달하고 Codex 또는 Claude Code에 `AX Module Studio 팀 개발환경을 구성해줘.`라고 요청하게 한다. 에이전트는 읽기 전용 Preflight와 사용자 승인 후 비-Git 상위 Workspace, 두 sibling Repository, Codex용 `AGENTS.md`, Claude Code용 `CLAUDE.md`, `AX-Module-Studio.code-workspace`를 구성하고 Backend의 Version 관리 Script를 실행한다. OS 관리자 권한, 재부팅, GUI·Browser 로그인과 Secret 입력은 자동 우회하지 않고 사용자 작업을 요청한다.

프로젝트 구현 단계에서 사용자는 다음 정보를 준비한다. 실제 Secret 값은 문서나 채팅에 기록하지 않고 승인된 Secret 입력 경로에 등록한다.

| 분류 | 사용자 준비 항목 | 비고 |
|---|---|---|
| Cloud VM | Public IP 또는 Hostname, OS 종류·버전, CPU·Memory·Disk | VM은 사용자가 생성 |
| 접속 | SSH 연결용 임시 sudo 계정, 등록할 SSH Public Key, 허용 Source IP | root 비밀번호·Private Key 공유 금지 |
| Git | Frontend·Backend Repository URL, GitHub Owner, 기본 Branch, 각 Repository의 `dev` Branch | Agent·CI 권한은 Repository별 Service Credential 사용 |
| Branch 정책 | Feature → PR → dev, 리뷰어, Merge 방식 | dev Merge 후 Staging 배포 |
| Image Registry | Prod 전용 Docker Hub 사용자·Organization·Namespace·Repository 이름 | CI 전용 Access Token은 Secret으로 등록 |
| CI/CD | GitHub Actions 사용 여부, Staging Environment 승인자 | 수동 승인 Gate 포함 |
| Domain | Staging Domain 또는 임시 Hostname, DNS 수정 권한 | IP·HTTP 시연은 사설망 또는 실제 Secret을 쓰지 않는 경우로 제한 |
| Product Secret | 공공데이터 API Key, LLM Key, LangSmith API Key | HTTPS 적용 후 CMS Secret Form에서 등록하고 원문 재표시 금지. LangSmith는 최고관리자 전용 관측·평가 메뉴로 분리 |
| Infra Secret | DB 초기 관리자 Secret, GitHub·Registry Credential | CMS 외부의 Provider Secret Store 또는 배포 Secret에 사용자가 직접 입력 |
| 네트워크 | 공개 Port, SSH/SSM 정책, 허용 관리자 IP | DB·Redis Port는 외부 비공개 |
| 운영 기준 | Health Check URL, Backup 주기, Log 보존기간 | Demo 기본값을 제안 후 사용자 승인 |

자동화 작업 전에는 위 항목을 `DEPLOYMENT_INPUT_CHECKLIST.md`로 확정하고, 누락된 값이 있으면 실제 서버 변경을 시작하지 않는다. GitHub·Registry·Cloud Credential은 최소권한·만료 가능한 Service Credential을 우선 사용한다.

root 비밀번호나 SSH Private Key를 채팅에 입력하지 않는다. 사용자는 Cloud VM·Network Firewall·IAM·DNS·비용 계정을 소유하고, 만료 가능한 임시 sudo 계정과 공개키 방식의 SSH 접근을 제공한다. 설치 후 임시 접근은 회수하고 실제 애플리케이션은 저권한 계정으로 실행한다.

구성 완료 후 다음 산출물을 인수인계한다.

- 인프라 구성도와 Container·Port 목록
- Docker Compose·환경변수 Template·Secret Reference 목록
- OS 계정·그룹·디렉터리 권한표
- DB ERD·테이블/컬럼 명세서
- DB Role·Grant Matrix
- Alembic Migration과 Seed 이력
- 방화벽·Security Group 설정표
- 배포·복구·백업 Runbook
- Health Check·권한 차단·복구 검증 결과
- 알려진 제한과 운영 전 보완사항

## 31.8 확정·보류 요약

### 확정

- 공공데이터포털의 사전 선정 JSON API 2종을 수동 Parameter·Response Mapping으로 P0 시연
- Build 진행상태 UI와 불변 Knowledge Version
- 사용자 RAG는 Active Version만 코드·DB 권한으로 강제
- 시점·수집 완전성·검색 품질 평가 및 근거 노출
- 작업별 LLM Model Mapping과 고정 Workflow
- 축소된 PageSpec과 DB 기반 즉시 게시
- React SPA + FastAPI + Worker + PostgreSQL/pgvector + Redis
- 메뉴·게시판·콘텐츠 변경은 구조화 Tool·Preview·승인·Audit 사용
- Git·OS·CI/CD·Registry는 CMS 외부에서 사전 구성하고 CMS는 최고관리자 전용 상태 확인만 제공
- Connector 규격·Secret 교체와 Knowledge Build·평가·활성화·복구는 최고관리자 담당
- P0 Worker 동시 Job 1개로 시작하고 검증 후 Worker 2개까지 확장, HTTP Load Balancer는 제외
- 공개 Cloud Staging에서 실제 Secret 입력 시 HTTPS 필수
- Coding Agent Job은 SHA·Policy Hash에 검증과 승인을 결합하고 내부 Tool Calling은 JSON Schema 기준
- 사이트 디자인·템플릿 관리를 다섯 번째 CMS 기본 기능으로 포함하고 `SiteTemplateSpec`·Preview·승인·Site Release·복구로 통제
- Frontend·Backend는 별도 Git Repository로 관리하고, FastAPI·Worker·Migration은 하나의 Backend Python Project·Image를 공유하되 Container 명령과 Runtime 권한을 분리
- Git 작업은 두 Repository 모두 `feature branch → dev PR → Review·Required Check → Merge`를 사용하고 자연어 Push·PR 요청도 `GIT-WORKFLOW.md` 정책을 강제
- 일반 팀원 PR은 민승준 Code Owner 승인을 요구하고, 민승준 본인 PR은 Required Check 후 Owner/Admin Merge한다. 민승준만 `dev`·`main` 직접 Push 권한을 보유하되 최초 Bootstrap·기록된 긴급복구에만 사용
- 팀원 Onboarding은 단일 `TEAM_DEV_SETUP.md`와 한 문장 요청으로 비-Git 상위 Workspace·두 Repository·Codex/Claude 규칙·Workspace 파일을 자동 구성

### Stretch 또는 후순위

- 공공데이터포털 대체 API 후보 검색
- 제한 경로 Coding Agent의 PR·Staging 배포
- 범용 OpenAPI Import와 범용 API 자동 해석
- 자동 PR 병합과 운영형 자율 배포

---

# 32. 2026-08-09 사이트 디자인·템플릿 관리 추가 결정사항

## 32.1 판정

사이트 Header·Footer·기본 Layout·Style Template 교체는 CMS의 기본 기능으로 포함한다. 다만 30일 Demo에서는 Webflow처럼 자유롭게 HTML·CSS·JavaScript를 생성하는 편집기가 아니라, 사전에 구현된 Template Variant와 Design Token을 선택·조합하는 구조로 제한한다.

CMS 기본 기능은 다음 다섯 영역으로 정의한다.

1. 메뉴 관리
2. 회원 관리
3. 콘텐츠 관리
4. 게시판 관리
5. 사이트 디자인·템플릿 관리

## 32.2 P0 경계

| 영역 | P0 제공 범위 | P0 제외 범위 |
|---|---|---|
| Header | 3개 고정 Variant, Logo·Menu·Sticky 설정 | 임의 HTML·Script·복잡한 Mega Menu 생성 |
| Footer | 2개 고정 Variant, Menu Section·Copyright | 자유 Form·외부 Script 삽입 |
| Layout | `ONE_COLUMN`, `CONTENT_WIDE`, `SIDEBAR` | Drag-and-drop 자유 Grid |
| Theme | Color·Font·Width·Radius·Spacing Token | Raw CSS·임의 Font URL |
| 자연어 | 허용 Registry 안의 `SiteTemplateSpec` Draft 생성·수정 | 운영 DOM·소스코드 직접 수정 |
| 배포 | DB Version Pointer 교체와 Cache 무효화 | Template 변경을 위한 App Rebuild |

## 32.3 핵심 원칙

- 자연어 요청은 구조화된 Draft만 생성하고 운영 화면을 직접 변경하지 않는다.
- Template Registry, JSON Schema, Asset Reference, 접근성 규칙과 권한 검사를 모두 통과해야 Preview가 가능하다.
- Desktop·Mobile Preview와 Reviewer 검토 뒤 Super Admin 승인으로 게시한다.
- Menu Version, Page Version Map, SiteTemplate Version을 `Site Release`에 묶어 원자적으로 게시·복구한다.
- 기존 Variant의 설정 변경은 DB 기반 실시간 반영이며, 새 Variant·Component 추가는 코드 PR과 애플리케이션 배포 대상이다.
- 상세 계약·상태·API·수용 기준은 `AX_Module_Studio_SITE_TEMPLATE_SPEC_v0.1.md`를 따른다.

---

# 33. 2026-08-09 관리자 CMS UI 목업 참고 기준

## 33.1 참고 목업

- URL: [AX Module Studio 관리자 CMS 목업](https://ax-module-studio.emilyjjang.chatgpt.site/index.html)
- 확인일: 2026-08-09
- 용도: 관리자 CMS의 디자인 분위기, 화면 밀도, 레이아웃과 상태 표현 방식에 대한 **시각적 참고자료**
- 우선순위: 기능·권한·메뉴·Workflow는 본 기획 문서가 우선하며, 목업은 요구사항의 단일 진실 공급원이 아니다.

## 33.2 유지할 시각·레이아웃 방향

- Dark Tone의 고정 Left Sidebar와 밝은 Main Work Area
- 상단에 현재 Workspace·Project Context, 설명, 정책·환경 상태와 사용자 정보를 표시하는 Header
- 각 화면을 `Section Label → 큰 제목 → 짧은 도움말 → Card형 작업영역` 순서로 구성
- 흰색 Card, 얇은 Border, 충분한 여백을 사용한 운영 Dashboard 형태
- Purple 계열 Primary Action, Mint·Green 계열 정상·연결·통과 상태, Red 계열 위험·거절·Rollback 상태
- `Policy Active`, `Connected`, `PASS`, `LOW`, `Current Version`처럼 짧고 명확한 Badge·Chip
- 설정 Form, 진행상태, Diff, 검증 근거, Health, Version History를 각각 독립 Card로 구분
- 중요한 승인·게시·복구 Action은 화면 하단 또는 Card 우측에 일관되게 배치
- 기술 상세를 모두 노출하기보다 상태 요약을 먼저 보여주고 필요한 경우 세부 정보를 펼치는 구조

## 33.3 현재 기획에 맞게 교체할 부분

기존 목업은 `demo-spring-api`, Java·Spring, AWS Staging, Coding Agent 작업을 중심으로 만든 초기 초안이다. 따라서 아래 항목은 최종 요구사항으로 고정하지 않는다.

- 기존 Left Menu의 명칭·개수·순서
- Spring Boot·Java·Gradle 예시
- AWS 전용 Region·Private Subnet 문구
- `main` Branch와 예시 PR·Commit·Version
- 기존 Task·회원 탈퇴·Audit Log 샘플 데이터
- 자율 코딩 기능이 전체 CMS의 중심인 것처럼 보이는 정보 구조

최신 관리자 정보 구조는 Dashboard, Project, Domain Connector, Knowledge/RAG, Chatbot, 메뉴, 회원, 콘텐츠, 게시판, 사이트 디자인·템플릿, 승인·게시, Agent Job, 감사 로그와 설정을 기준으로 다시 구성한다. P0 구현 시 실제 Sidebar 항목은 권한별 노출과 작업 빈도를 고려해 그룹화하며, 이 목록을 그대로 1단 메뉴로 모두 노출할 필요는 없다.

## 33.4 화면 패턴 재사용 기준

| 목업 화면 패턴 | 최신 기획에서의 재사용 대상 |
|---|---|
| 정책 설정 Card·Allow/Deny 표현 | Connector 정책, Coding Agent PathPolicy, Secret·Network 상태 |
| 자연어 Task 입력 + 기술·정책 Chip | 메뉴·페이지·사이트 템플릿 Draft 생성, 제한 경로 Coding Job |
| Diff·정책검사·테스트 결과 + 승인 Action | PageSpec·SiteTemplateSpec Diff, RAG 평가, Coding Patch 승인 |
| 연결 상태·Health·Version History | Connector, Knowledge Version, Site Release, Staging 배포 상태 |
| 좌측 하단 환경 연결 상태 | Dev·Prod-like 연결, Worker·DB·Redis Health 요약 |

## 33.5 사이트 디자인·템플릿 관리 화면 방향

사이트 디자인·템플릿 관리도 같은 관리자 Shell을 사용한다.

```text
Left Sidebar
→ 사이트 디자인·템플릿 선택
→ 자연어 변경 요청 Card
→ Header·Footer·Layout Variant와 Theme Token 설정 Card
→ Desktop·Mobile Preview
→ Schema·접근성·Asset·Binding 검증 결과
→ 변경 전·후 Diff
→ 승인 요청·게시·복구 Action
```

구체적인 화면 구조와 현재 기획으로의 치환 기준은 `AX_Module_Studio_ADMIN_UI_MOCKUP_REFERENCE_v0.1.md`에서 관리한다.

---

# 34. 2026-08-09 단일 MD 기반 팀 Workspace Bootstrap 결정

## 34.1 팀원 인수인계 방식

팀원에게는 `TEAM_DEV_SETUP.md` 한 파일과 다음 한 문장만 전달한다.

```text
AX Module Studio 팀 개발환경을 구성해줘.
```

Codex 또는 Claude Code가 파일을 읽고 설치 경로·변경·Network·관리자 권한 가능성을 먼저 제안한다. 사용자가 승인하면 다음 구조를 자동 구성한다.

```text
AX-Module-Studio-Workspace/          # Git Repository 아님
├── AGENTS.md                        # Codex용 Local Generated Rule
├── CLAUDE.md                        # Claude Code용 Local Generated Rule
├── AX-Module-Studio.code-workspace  # 두 Repository Workspace
├── urizo-final-frontend/            # Frontend Git Repository
└── urizo-final-backend/             # Backend Git Repository·Script Root
```

## 34.2 자동화 책임

- 상위 비-Git Folder 생성
- 두 Repository sibling Clone·Origin 확인
- Codex·Claude용 공통 Repository Routing 규칙 생성
- 두 Repository를 포함하는 Workspace 파일 생성
- Git 사용자·Read·Feature Push·PR 권한 검사
- WSL2·Docker Desktop·Compose 검사
- Local Image Build·Compose Up·Alembic Migration·Health Check
- 서비스 URL과 상태 보고

## 34.3 자동화하지 않는 사용자 책임

- Codex 또는 Claude Code를 최초 실행하고 MD를 제공
- 설치 경로·File Write·Network·관리자 권한·재부팅 승인
- GitHub·Docker Desktop Browser·Device 로그인
- Repository Collaborator·Branch Protection을 Owner 권한으로 설정
- LLM·공공데이터 Secret을 서비스 기동 후 CMS에 직접 입력

## 34.4 Git·세션 원칙

기능 개발 세션은 상위 Workspace를 열어 Frontend·Backend를 함께 이해하고 필요하면 동시에 수정한다. 상위 Folder에는 `.git`이 없으므로 하나의 Commit으로 묶지 않는다.

```text
urizo-final-frontend/** → Frontend Branch·Commit·Push·PR
urizo-final-backend/**  → Backend Branch·Commit·Push·PR
```

자연어 `Push 후 PR 요청`은 두 Repository의 실제 변경 여부를 검사해 변경된 Repository에만 PR을 만든다. 양쪽이 변경되면 같은 `work-slug`의 PR 두 개를 만들고 상호 링크한다. 자동 Merge는 하지 않는다.
