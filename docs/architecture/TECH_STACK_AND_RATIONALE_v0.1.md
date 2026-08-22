# AX Module Studio 저장소별 기술스택과 사용 근거

> Updated: 2026-08-20 (Asia/Seoul)
> 기준: 각 저장소의 Manifest, Lockfile, Dockerfile, Compose
> 주의: 기술스택 목록은 기능 범위를 늘리는 근거가 아니다. 기능 범위는 현재 CMS Spec을 따른다.

## Master

| 기술 | 사용 목적 | 선택 근거 |
|---|---|---|
| Markdown·JSON | Spec, Snapshot, 저장소 Manifest | Git diff가 명확하고 별도 문서 서버 없이 모든 LLM과 팀원이 읽을 수 있다. |
| PowerShell 7 | Bootstrap, 동기화, Preflight, 검증 | Windows·macOS·Linux에서 같은 Workspace 절차를 사용한다. |
| Git | 공통 기준과 변경 이력 | 구현 상태의 단일 기준이며 Source PR과 연결하기 쉽다. |

## Frontend

| 기술 | 기준 버전 | 사용 목적과 근거 |
|---|---:|---|
| Node.js / pnpm | 24.14.0 / 11.9.0 | 재현 가능한 의존성 설치와 Frontend 빌드 실행 환경이다. |
| React / React DOM | 19.2.8 | 관리자·사용자 화면을 컴포넌트 단위로 단순하게 구성한다. |
| React Router DOM | 7.18.2 | `/` 사용자단과 `/admin` 관리자단 및 하위 화면을 분리한다. |
| TypeScript | 7.0.2 | API 응답과 화면 상태 오류를 빌드 전에 찾는다. |
| Vite | 8.2.1 | SPA 개발 서버와 빠른 정적 빌드를 담당한다. |
| Tailwind CSS | 4.3.3 | 기존 스타일 체계를 유지하며 공통 UI를 적은 코드로 구성한다. |
| Vitest / Testing Library | 4.1.10 / 16.3.2 | 사용자 동작 중심의 최소 회귀 테스트를 실행한다. |

## Backend

| 기술 | 기준 버전 | 사용 목적과 근거 |
|---|---:|---|
| eGovFrame Boot / Spring Boot | 5.0.0 / 3.5.6 | 공공 프로젝트 친화 기반 위에서 API와 운영 기능을 일관되게 제공한다. |
| Java / Maven | Release 17, JDK 21 / 3.9.9 | 안정적인 JVM 호환성과 재현 가능한 빌드를 제공한다. |
| Spring MVC·Validation·Actuator | Boot 관리 버전 | REST API, 입력 검증, 상태 확인을 표준 방식으로 처리한다. |
| Spring Data JPA·JDBC | Boot 관리 버전 | CMS 업무 데이터는 JPA로 다루고 마이그레이션·저수준 접근은 JDBC와 함께 사용한다. |
| Spring Security·JWT Resource Server | Boot 관리 버전 | 관리자/일반 사용자 접근 구분과 토큰 검증을 Backend에서 강제한다. |
| Spring Batch | Boot 관리 버전 | 향후 승인된 배치 작업을 Spring 실행 모델 안에서 관리한다. 현재 CMS 범위를 자동 확장하지 않는다. |
| Spring AI | Product 1.1.8 | AX Module Studio의 승인된 Model Gateway 기반이다. 수동 CMS에서는 신규 AI 기능을 만들지 않는다. |
| Flyway | 11.7.2 | DB 구조와 시연 초기 데이터를 순서가 있는 SQL로 재현한다. |
| PostgreSQL + pgvector | 16 + 0.8.5 | CMS 관계형 데이터와 승인된 벡터 저장 요구를 한 DB 계열로 운영한다. |
| Valkey | 8.1.3 | 세션·캐시성 상태를 DB와 분리해 처리한다. |

## Orchestrator

| 기술 | 기준 버전 | 사용 목적과 근거 |
|---|---:|---|
| Python | 3.12.13 | LangGraph 런타임과 라이브러리 호환 범위를 고정한다. |
| uv | 0.8.13 | `uv.lock` 기반으로 Python 의존성과 컨테이너 빌드를 재현한다. |
| LangGraph | 1.1.x | Coding Agent의 고정 그래프와 중단·재개 흐름을 구현한다. |
| PostgreSQL Checkpoint / psycopg | 3.1.x / 3.2.x | 그래프 체크포인트를 트랜잭션 가능한 저장소에 보관한다. |
| Redis client + Valkey | 6.4.x / 8.1.3 | 짧은 수명의 런타임 상태와 메시지 처리를 공유한다. |
| PyCryptodome | 3.23.x | 승인된 Coding Runtime 자격정보 처리에 필요한 암호 기능을 제공한다. |

## 로컬 통합 실행

| 기술 | 기준 버전 | 사용 목적과 근거 |
|---|---:|---|
| Docker Compose | Compose Spec | DB·Migration·Backend·Frontend·Nginx·Orchestrator를 같은 로컬 절차로 실행한다. |
| Nginx | 1.28.0 | 단일 localhost 진입점에서 Frontend와 API를 라우팅한다. |
| Docker 다단계 빌드 | 저장소 Dockerfile | 빌드 도구와 실행 이미지를 분리해 재현성과 이미지 크기를 관리한다. |

정확한 패치 버전은 각 저장소의 `package.json`·`pnpm-lock.yaml`, `pom.xml`,
`pyproject.toml`·`uv.lock`, Dockerfile, `compose.dev.yaml`을 최종 기준으로 한다.
