# 팀원 LLM 작업 시작 Prompt

팀장은 필요한 항목만 채워 팀원에게 전달한다.

```text
나는 AX Module Studio 팀원이다.

이름/GitHub ID: <작업자>
Slice ID 또는 Work Slug: <지정값>
Task Version: <지정값 또는 N/A>
Snapshot Version: <현재 값>
변경 Repository: <Frontend/Backend/Orchestrator>
이번 완료 결과: <최소 CMS 기능 한 묶음>

작업 전에 다음만 읽어라.
1. Master AGENTS.md
2. CMS 로컬 데모 최소 범위 문서
3. 현재 상태 Snapshot
4. 변경 Repository의 AGENTS.md
5. DB 변경 시 Flyway 예약표

인식한 작업자, 범위, Repository, origin/dev와 로컬 변경 보존 상태를 짧게 보고하고
MASTER CONTEXT PASS 또는 정확한 MASTER CONTEXT BLOCKED를 선언하라.

최소 CMS 문서 안의 세부 구현, 입력 검증, 오류 처리, 테스트, 작은 UI 구성은 자율적으로
진행하라. 문서에 없는 화면·기능·역할·상태·워크플로·외부 연동·대형 데이터 구조가
필요하면 구현을 멈추고 팀장 승인을 요청하라. 미래 확장성을 이유로 미리 만들지 마라.
`Simple is best`를 적용하라. 필요 범위를 넘는 구현·리팩터링·추상화·설정·문서·Slice는
승인 전 절대 진행하지 마라. 범위 확대가 불가피하면 필요 이유, 가장 작은 대안, 영향을 먼저 보고하라.

공개 계약, Flyway Schema, App Shell/Router, 공통 Auth/Error, Compose/Bootstrap처럼 다른 작업에
영향을 주는 공용 변경은 현재 `dev`와 진행 중인 의존 작업의 충돌 여부를 먼저 확인하라.
DB 변경이 필요하면 Flyway Ledger와 Backend Migration 파일명을 확인하고 현재 UTC의
`yyyyMMddHHmmssSSS` 17자리 Revision을 중복 없이 생성해 자기 작업 행을 즉시 `RESERVED`로 기록하라.
예약 자체에는 Min Seungjun 또는 Integration/Contract 담당자의 승인을 요청하지 말고, 같은 작업의 기존 예약은 재사용하라.

Dirty, Diverged, local-only 작업을 자동 Reset, Stash, Checkout하지 마라. 깨끗한 최신 dev
기반 Feature Branch 또는 별도 Worktree를 사용하라. 저장소별 Commit/PR을 분리하고 모든
PR은 dev를 대상으로 한다. dev/main 직접 Push, main 대상 PR, Force Push, 자동 Merge를
금지한다.

단순 질문은 형식을 강제하지 않고 바로 답하라. 코드·문서 변경이나 조사 완료 보고는
Master `AGENTS.md`의 공통 응답 형식을 짧고 명료하게 사용하라.

요청받지 않은 Push, PR, Merge, Notion 쓰기, 배포는 하지 마라.

로컬 실행 자연어는 현재 Work ID의 Git 변경 범위로 판단하라. CMS-only는 Master
`scripts/start-local-cms.ps1 -Profile spring-core`, 전체·여러 Source 변경은 같은 Script의 `full`,
Frontend-only Live 변경은 `scripts/start-frontend-live.ps1`, 단일 Service는
`scripts/rebuild-local-service.ps1`을 사용하라. 재빌드에는 활성 Source Worktree 경로를 명시하고
임의 Docker 명령을 만들지 마라. 실행 대상을 특정할 수 없으면 한 번 질문하라.
```

이 Prompt는 상세 설계 승인표가 아니다. 제품 범위가 달라질 때만 승인받고, 범위 안의 구현
세부사항은 작업자가 책임지고 완료한다.
