# Teammate LLM work-start prompt v0.1

Use this only after the teammate reports `SETUP PASS`. The Integration/Contract owner must fill every required placeholder and assign one Slice only.

```text
나는 AX Module Studio 팀원이다.

이름: <본인 이름>
GitHub ID: <본인 GitHub ID>
Slice ID: <현재 할당된 Slice ID>
Slice 목표: <사용자에게 보이는 한 개의 완료 결과>
선행 PR/의존성: <PR URL 또는 N/A>
예상 변경 Repository: <Frontend/Backend/Orchestrator 중 해당 항목>

urizo-final-master의 최신 AGENTS, implementation/team handoff,
traceability, team roadmap, Flyway ledger와 변경할 sibling AGENTS를 완독하라.

전체 workstream이나 다음 Phase를 한꺼번에 구현하지 말고 현재 Slice 하나만 수행하라.
Slice ID나 선행 의존성이 비어 있거나 병합되지 않았다면 구현하지 말고 보고하라.

구현 전 읽기 전용 Preflight 후 다음을 보고하라.

1. 네 Repository branch/HEAD/dirty
2. 예상 Source path와 파일 소유권
3. Contract → Flyway → Spring → Frontend → E2E 순서
4. 공용 hot spot과 Integration/Contract owner 예약 필요 여부
5. Flyway UTC revision 예약 필요 여부
6. Repository별 PR 순서와 cross-link 계획
7. 성공, validation, 401/403, conflict/idempotency, retry 테스트 계획

공용 OpenAPI/JSON Schema, Flyway directory, App shell/router/navigation,
공통 Auth/Error/Approval/Audit, Backend Compose/bootstrap, Master manifest/handoff는
Integration/Contract owner의 직렬화 lane 없이 편집하지 마라.

승인 후 latest origin/dev 기반으로
feature/<내-github-id>_<동일-work-slug>_<version> 브랜치를 사용하라.
변경 Repository마다 검증·commit·push·dev 대상 PR을 분리하고 같은 Slice ID로 상호 링크하라.
직접 dev/main push, force push, auto merge를 금지한다.

완료 보고에는 변경 파일, 테스트 결과, Contract/Migration 영향,
Repository별 commit/PR, merge 순서, 남은 blocker를 포함하라.
```

Initial coding window:

- `AXMS-FND-01`: 민승준
- `AXMS-FND-02`: 이재욱, parallel with FND-01
- Other implementation waits until these preparation Slices are merged and the roadmap dependency opens the next Slice.
