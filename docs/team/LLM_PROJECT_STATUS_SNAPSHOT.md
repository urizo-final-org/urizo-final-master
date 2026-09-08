# AX Module Studio 현재 상태

> Updated: 2026-09-07 (Asia/Seoul)
> Snapshot-Version: `v1.6-release-closeout-open`
> Owner: Min Seungjun (`tmdwns0531`)

## 현재 기준

- 제품 범위: [로컬 데모 CMS 최소 범위](../product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md)
- Git·팀 운영: [Master·Source 운영 정책](MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md)
- 현재 상태: [AI Core Release Closeout](../product/ai-core/AI_CORE_RELEASE_CLOSEOUT.md)은 `OPEN`이다.
  아래 SHA와 Snapshot-only 결과는 과거 범위 검증 증거이며 현재 제품 전체 완료 선언이 아니다.
- 이전 CMS Spec, Wave, 업무분장, 추적표, 인수인계 이력은 현재 권한이 아니다.
- AI 핵심 기능의 과거 Work·PR 병합 이력은 현재 완료 판정이 아니다. 현재 상태는 Git과 열린 Release Closeout에서 다시 확인한다.

## 최종 검증 저장소 기준

| 저장소 | 최종 검증 SHA |
|---|---|
| Master | `2743373fd133f7b7f19774d23e63937a44773b19` |
| Frontend | `a8a69e8e0c31ed2abbb8881f9da2fe249d55019f` |
| Backend | `6d5ad9bfab473c5548c0f3f1724e1f4f58ec152f` |
| Orchestrator | `1f0224dc1857ca2ad0198c426aa78f440b3382ad` |
| MCP Server | `0885dbe64ae601d9790c05c600dbb585eff70800` |

개인별 local-only 변경은 canonical 완료 상태가 아니다. 이를 자동으로 삭제·Reset·Stash·Branch
전환하지 않으며, 새 작업은 승인된 범위와 깨끗한 최신 `dev` 기반 별도 Branch 또는 Worktree에서 시작한다.

## 기록된 통합 증거

- 아래 항목은 표에 고정된 2026-09-01 SHA 조합의 기록이며 현재 Runtime·DB 상태를 뜻하지 않는다.
- Frontend [#21](https://github.com/urizo-final-org/urizo-final-frontend/pull/21), Backend [#40](https://github.com/urizo-final-org/urizo-final-backend/pull/40), Orchestrator [#16](https://github.com/urizo-final-org/urizo-final-orchestrator/pull/16)은 `dev`에 병합됐다.
- 당시 저장소 테스트, Spring↔MCP 13-tool 왕복, 공식 `full -Rebuild`와 Flyway pending 0 결과가 기록됐다.
  이 과거 결과를 새 Work, 현재 Image 또는 현재 DB에 자동 승계하지 않는다.

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
Snapshot-Version: v1.6-release-closeout-open
Slice/Work-Slug: <assigned value>
Task-Version: <assigned value or N/A>
Worker: <name / GitHub ID>
Repositories: <Master, Frontend, Backend, Orchestrator, MCP Server 중 해당 항목>
Scope: <최소 CMS 완료 결과>
Master-Commit: <checked-in commit>
```

Notion 쓰기, Git push, PR, merge, Cloud 배포는 각각 명시적으로 요청된 경우에만 수행한다.
