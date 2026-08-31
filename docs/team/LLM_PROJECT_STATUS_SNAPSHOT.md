# AX Module Studio 현재 상태

> Updated: 2026-09-01 (Asia/Seoul)
> Snapshot-Version: `v1.4-release-closeout`
> Owner: Min Seungjun (`tmdwns0531`)

## 현재 기준

- 제품 범위: [로컬 데모 CMS 최소 범위](../product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md)
- Git·팀 운영: [Master·Source 운영 정책](MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md)
- 현재 우선순위: 병합된 AI 핵심 기능을 제품 완료로 간주하지 않고 [AI Core Release Closeout](../product/ai-core/AI_CORE_RELEASE_CLOSEOUT.md)의 활성 29개 항목을 7개 Work로 닫는다.
- 이전 CMS Spec, Wave, 업무분장, 추적표, 인수인계 이력은 현재 권한이 아니다.
- AI 핵심 기능의 과거 Work·PR 병합 이력은 완료 판정이 아니다. 현재 상태와 완료 증거는 Release Closeout만 관리한다.

## 확인된 저장소 기준

| 저장소 | `origin/dev` |
|---|---|
| Master | `de67ea818786de79c56c0db61bd984db1c81ce25` |
| Frontend | `62ed93f3743d70e29c43a61ae2850ce08e093f7e` |
| Backend | `9189d27510e16c3c11c350205e6b53c14ebe2f2a` |
| Orchestrator | `85b36392481065e4b933e688ec66ebc3e2bee351` |
| MCP Server | `0885dbe64ae601d9790c05c600dbb585eff70800` |

개인별 local-only 변경은 canonical 완료 상태가 아니다. 이를 자동으로 삭제·Reset·Stash·Branch
전환하지 않으며, 새 작업은 승인된 범위와 깨끗한 최신 `dev` 기반 별도 Branch 또는 Worktree에서 시작한다.

## 구현 상태

- 축소 CMS 기준 구현과 AI 핵심 기능의 과거 Slice·PR은 `origin/dev`에 병합돼 있다.
- 병합 여부와 좁은 Slice 테스트 결과는 제품 완료 증거로 사용하지 않는다.
- 기존 21개 분류에서는 완료 4개·의도적 제외 2개를 작업 대상에서 빼고, 미완료 7개·부분완료 8개만 활성 범위로 유지한다.
- 구원장 14개는 PR 병합 상태가 아니라 현재 제품 흐름에서 다시 확인하고, 실패하는 경우에만 최소 수정한다.
- 현재 Work는 `AXMS-RC-001`~`AXMS-RC-007`이며 모두 `OPEN`이다. 최종 통합 전 개별 로컬 Commit은 완료로 기록하지 않는다.
- 최종 `DONE`은 모든 PR 병합 후 동일한 다섯 저장소 SHA에서 활성 29개·저장소 전체 테스트·기존 full 로컬 제품 흐름을 모두 통과한 경우에만 사용한다.

## 구현 시작 조건

일반 작업은 팀장이 작업 시작 전에 최소한 다음만 지정한다.

- 작업자와 GitHub ID
- Slice ID 또는 공통 work slug
- 변경 저장소
- 이번 작업에서 완료할 최소 영역

AI 핵심 기능 2~6번은 담당자 표를 우선한다. 현재 PC의 GitHub ID가 담당자와 일치하고 최소 완료 결과가
명확한데 Work ID가 없다면 LLM이 담당 기능의 다음 Work ID와 work slug를 작업 시작 전에 한 번 제안한다.

세부 구현 방법은 작업자가 결정한다. 현재 CMS 기준을 벗어나는 화면·기능·데이터·외부 연동이
필요해질 때만 구현을 멈추고 팀장 승인을 요청한다.

동기화한 Master 기준과 지시가 일치하면 `MASTER CONTEXT PASS`를 보고한다. 범위·작업자·저장소가
다르거나 범위 확장이 필요하면 `MASTER CONTEXT BLOCKED`를 보고하고 임의로 진행하지 않는다.

## MASTER UPDATE COMPLETE 최소 형식

```text
MASTER UPDATE COMPLETE
Snapshot-Version: v1.4-release-closeout
Slice/Work-Slug: <assigned value>
Task-Version: <assigned value or N/A>
Worker: <name / GitHub ID>
Repositories: <Frontend, Backend, Orchestrator 중 해당 항목>
Scope: <최소 CMS 완료 결과>
Master-Commit: <checked-in commit>
```

Notion 쓰기, Git push, PR, merge, Cloud 배포는 각각 명시적으로 요청된 경우에만 수행한다.
