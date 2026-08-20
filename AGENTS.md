# AX Module Studio Master Repository Rules

## 저장소 경계

- Master는 공통 기준·상태·Workspace 도구만 소유하며 제품 Source를 보관하지 않는다.
- 상위 `AX-Module-Studio-Workspace`는 Git 저장소가 아니다.
- Frontend, Backend, Orchestrator는 각각 독립 저장소다.
- 여러 저장소를 변경하면 같은 Slice ID/work slug를 사용하되 Commit과 PR은 저장소별로 분리한다.

## 필수 읽기

작업 전 필요한 문서만 읽는다.

1. `docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md`
2. `docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md`
3. `docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md`
4. 작업 저장소의 `AGENTS.md`
5. DB 변경 시 `docs/team/FLYWAY_RESERVATION_LEDGER.md`
6. 로컬 환경 작업 시 해당 Workspace·Infrastructure 문서

삭제된 과거 CMS Spec, Wave, 추적표, 업무분장, 인수인계 내용을 추측하거나 복원하지 않는다.

## 현재 제품 범위

현재 목표는 학원 발표용 로컬 CMS MVP다. 구현 범위는
`AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md`만 따른다.

- 문서에 포함된 기능의 일반적인 설계·검증·테스트는 별도 승인 없이 진행한다.
- 문서에 없는 화면·기능·역할·상태·워크플로·외부 연동을 추가하지 않는다.
- 실운영 대비, 미래 확장성, 감사·승인·버전 관리 등을 이유로 범위를 선행 확장하지 않는다.
- 범위를 벗어날 필요가 생기면 작업을 멈추고 팀장에게 승인 요청한다.
- 세부 구현 하나하나는 승인 대상이 아니다. 사용자 기능 범위가 달라질 때만 승인받는다.

## 단순성·범위·응답 원칙

- `Simple is best`를 기본 원칙으로 삼는다. 현재 Spec과 할당된 최소 완료 결과에 필요한 것만 만든다.
- 필요 범위를 넘는 구현·리팩터링·추상화·설정·워크플로·문서·Slice 세분화는 승인 전 절대 진행하지 않는다.
- Master 문서는 현재 결정·범위·검증에 필요한 내용만 남기고 반복 설명·개인별 이력·미확정 계획을 덜어낸다.
- 테스트와 문서는 변경 위험과 시연 범위에 비례해 최소 충분 수준으로 작성한다.
- 불가피하게 범위를 늘려야 하면 변경 전에 멈추고 `필요 이유 / 가장 작은 대안 / 영향`을 짧게 적어 팀장 승인을 요청한다.
- Codex와 Claude는 같은 기준을 사용한다. 결과를 먼저 말하고 사람이 이해하기 쉬운 짧은 문장으로 답한다.
- 단순 질문은 바로 답하고, 작업 상태·완료 보고는 아래 형식을 사용한다.

```text
결과: 완료 | 진행 중 | 차단
핵심: <변경 또는 판단 1~3줄>
검증: <확인 결과 또는 미실행 이유>
다음: <다음 행동 1줄>
승인: 없음 | <필요한 승인과 이유>
```

## 작업 시작

- 최신 Master Spec과 Snapshot, 적용 저장소 규칙을 확인한다.
- 팀장이 지정한 작업자, Slice ID/work slug, 저장소, 최소 완료 결과를 확인한다.
- 일치하면 `MASTER CONTEXT PASS`와 인식한 범위를 짧게 보고한다.
- 지정이 없거나 범위가 충돌하면 `MASTER CONTEXT BLOCKED`를 보고하고 구현하지 않는다.
- Source의 dirty·diverged·local-only 작업은 보존한다. 새 작업은 깨끗한 최신 `dev` 기반 Branch나 별도 Worktree에서 시작한다.

## 전체 Git 동기화

`깃 pull 해줘`, `전체 Git 최신화`, `워크스페이스 최신화`는
`scripts/sync-workspace.ps1 -ApproveNetwork`를 의미한다.

- Master 먼저, 이어서 Frontend·Backend·Orchestrator를 확인한다.
- 자동 Branch 전환, Rebase, 충돌 해결, Reset, Stash Pop, 로컬 변경 삭제를 하지 않는다.
- 동기화 후 Master Spec과 Snapshot을 다시 읽는다.

## 소유권

- Frontend: React UI와 브라우저 동작
- Backend: Spring API, 공개 계약, Flyway, Compose, 로컬 실행·검증
- Orchestrator: Python LangGraph Coding Runtime
- Master: 현재 제품 범위, 공통 Git/팀 정책, 상태 Snapshot, Workspace 도구

Master 쓰기는 Min Seungjun(`tmdwns0531`)만 담당한다. 팀원은 Master를 읽기 전용으로 사용한다.

## Git 정책

- 개발은 최신 `dev`에서 Feature Branch를 만들어 시작한다.
- Team Branch, Commit, PR에는 지정된 Slice ID와 GitHub ID를 사용한다.
- Every agent-created pull request in Master, Frontend, Backend, and Orchestrator targets `dev`.
- `dev`와 `main`에 직접 Push하지 않는다.
- `main` is the team lead's periodic manual promotion branch.
- `main` 대상 PR, Force Push, 자동 Merge를 금지한다.
- 여러 저장소 변경은 같은 work slug로 저장소별 별도 Commit/PR을 만든다.
- 문서 변경은 Commit, Push, PR, Merge를 자동으로 승인하지 않는다.

## 공통 변경

공개 계약, Flyway, Frontend Router/App Shell, 공통 Auth/Error, Backend Compose·Bootstrap처럼
여러 작업에 영향을 주는 파일은 Integration/Contract 담당과 충돌 여부를 먼저 확인한다.

DB 변경은 SQL 작성 전에 Master Flyway Ledger에 UTC 14자리 Revision을 예약하고,
빈 DB·기존 DB·반복 실행·Runtime DDL 거부를 확인한다.

## Notion

- Notion은 현재 Git 작업의 자동 대상이 아니다.
- Min Seungjun이 현재 요청에서 명시적으로 지시한 경우에만 쓴다.
- Git이 구현 상태의 기준이며 Notion과 다르면 Git을 따른다.
- 팀원은 Notion 연결을 요구받지 않는다.

## 안전

- Branch, HEAD, 로컬 변경, DB, Docker Volume, Secret, 실행 중인 Container를 보존한다.
- 자동 Reset, Clean, Stash, Checkout, Rebase, DB 초기화, Flyway Repair/Clean, Volume 삭제를 금지한다.
- Secret 값을 Prompt, Chat, 명령, Log, Commit, PR에 넣지 않는다.
- Network, 로그인/MFA, 관리자 권한, 설치, 재부팅, Cloud/Prod/SSH는 명시적 승인 후 수행한다.
- Notion 쓰기, Git Push, PR 생성·Merge, 배포는 각각 별도 요청이 있을 때만 수행한다.
