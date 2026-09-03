# AX Module Studio Git·팀 운영 정책

> Owner: Min Seungjun (`tmdwns0531`)
> 원칙: Git이 구현 기준이며 문서와 절차는 최소한으로 유지한다.

## 권한

- Master 공통 기준과 공통 문서는 Min Seungjun만 수정한다. 단, Flyway 예약표의 자기 작업 예약 행 추가와
  상태 갱신은 인증된 팀원별 LLM이 수행할 수 있다.
- AI 핵심 기능 담당자는 `docs/product/ai-core/`에서 자신에게 배정된 상세 문서만
  Feature Branch와 `dev` 대상 PR로 수정한다. 기능 내용의 최종 판단은 해당 담당자가 맡는다.
- 다른 담당자의 기능 문서와 Master 공통 파일은 수정하지 않는다. 기능 간 공통 경계 변경은
  관련 담당자와 Min Seungjun이 함께 확인한다.
- Notion은 팀장이 현재 요청에서 명시한 경우에만 쓴다.
- 코드 작업, PR, Merge, 상태 보고는 Notion 쓰기를 자동 승인하지 않는다.

## Git

Master와 네 Source 저장소에 같은 규칙을 적용한다.

```text
Agent-PR-Base: dev
Main-Promotion: manual-team-lead-only
```

- 모든 Agent/LLM PR은 `dev` 대상이다.
- 팀원은 `dev`와 `main`에 직접 Push하지 않는다.
- `main`은 Min Seungjun의 주기적 수동 승격 전용이다.
- `main` 대상 PR, Force Push, 자동 Merge를 금지한다.
- 여러 저장소를 변경하면 같은 Slice ID/work slug로 저장소별 Commit과 PR을 분리한다.
- 로컬 변경, local-only Commit, Dirty·Diverged Branch를 자동 삭제·Reset·Stash·전환하지 않는다.

Branch·Commit·PR 이름은 다음 형식을 사용한다.

```text
Branch: feature/<github-id>_<work-slug>_<version>
Commit: <type>(<slice-id-or-work-slug>/<github-id>): <한글 변경 결과>
PR: [<slice-id-or-work-slug>][<github-id>] <한글 완료 결과>
```

- 수동 Commit의 `type`은 `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `build`, `ci`, `style` 중 하나를 사용한다.
- Slice ID가 확정되지 않았으면 배정된 work slug를 사용한다.
- Commit·PR 제목과 본문은 한글로 작성한다. Type, ID, 코드 식별자, 경로, 명령, 제품·기술 고유명사는 영문을 허용한다.
- 자동 생성 Merge/Revert Commit은 제목 패턴의 예외다.
- 작은 오탈자·서식 변경을 제외한 수동 Commit은 아래 본문을 사용한다.

```text
변경:
- 핵심 변경 내용

검증:
- 실행한 테스트와 결과

관련:
- 관련 PR, Flyway Revision 또는 없음
```

PR 본문은 저장소의 `.github/PULL_REQUEST_TEMPLATE.md`를 사용하며 `결과 / 변경 / 검증 / 연결·영향 / 확인`만 남긴다.

## 작업 배정

현재 Snapshot에 고정 업무분장이 없으면 팀장은 다음 최소 범위를 지정한다.

- 변경 저장소
- 이번 최소 완료 결과
- 현재 PC 실행자와 다른 담당자가 맡는 경우 담당자와 GitHub ID
- 공통 Slice ID가 이미 정해진 경우 해당 ID

GitHub ID와 work slug는 명시값이 없을 때 다음처럼 가볍게 정한다.

- GitHub ID는 현재 PC의 `gh auth status` 설정 계정을 사용한다. 조직 멤버 전체 목록은 조회하지 않는다.
- work slug는 승인된 최소 완료 결과를 소문자 영문·숫자·하이픈으로 정리해
  `axms-<작업내용-kebab-case>` 형식으로 자동 생성한다.
- Branch 이름은 기존 형식인 `feature/<github-id>_<work-slug>_<version>`을 유지한다.
- 같은 저장소에서 같은 GitHub ID와 work slug가 이미 있으면 로컬·원격 Branch를 확인하고
  사용하지 않은 가장 작은 Version으로 `v0.1`, `v0.2` 순서로 올린다.
- 여러 저장소에 걸친 같은 작업은 동일한 work slug를 재사용하고 Commit과 PR만 저장소별로 분리한다.
- 팀장이 담당자·GitHub ID·Slice ID/work slug를 명시하면 자동 생성값보다 우선한다.
- 현재 PC의 GitHub ID를 확인할 수 없거나 최소 완료 결과가 모호하면 자동 생성하지 않고 확인을 요청한다.

## Flyway 자율 예약

- DB Schema 변경이 필요하다고 판단한 LLM은 SQL 작성 전에 최신 Master Flyway Ledger와 Backend Migration 파일명을 확인한다.
- 같은 작업에 유효한 예약이 없으면 현재 UTC의 `yyyyMMddHHmmssSSS` 17자리 Revision을 생성한다.
  이미 존재하는 값이면 새 시각으로 다시 생성하고, 기존 14자리 Revision은 변경하거나 재발급하지 않는다.
- 현재 GitHub ID를 Owner로 자기 작업 행을 `RESERVED` 상태로 즉시 추가한다. 예약 생성과 확정에는
  Min Seungjun 또는 Integration/Contract 담당자의 별도 승인이 필요하지 않다.
- 팀원별 LLM은 자기 예약 행의 `PR_OPEN`, `MERGED`, `ABANDONED` 상태만 갱신하며 다른 사람의 행과 Ledger 정책은 수정하지 않는다.
- 같은 작업은 기존 Revision을 재사용하고, 예약 번호를 Backend PR 본문에도 기록한다.
- 예약표 변경도 Master Feature Branch와 `dev` 대상 PR 원칙을 따르며 직접 Push·자동 Merge 권한을 의미하지 않는다.

### AI 기능 하위 작업 ID

- 2~6번 기능의 하위 작업 단위와 범위는 해당 기능 담당자가 정한다.
- Work ID는 기능별로 `AI02-001`, `AI03-001`, `AI04-001`, `AI05-001`, `AI06-001`처럼 독립 채번한다.
- work slug는 `axms-ai<기능번호>-<순번>-<작업내용-kebab-case>` 형식을 사용한다.
- Branch는 기존 형식에 따라 `feature/<github-id>_<work-slug>_<version>`으로 만든다.
- Work ID 하나는 `작업 시작 제안 → 작업 → PR 생성`까지의 한 작업 주기다.
- 같은 PR에 포함되는 구현·테스트·문서·리뷰 수정은 한 Work ID 아래 여러 작업으로 목록화한다.
  독립적으로 검토·병합할 다음 결과물이나 다음 PR부터 새 Work ID를 사용한다.
- 실제 새 작업 지시를 받았는데 사용할 Work ID가 없으면 LLM이 담당 기능 문서의 마지막 번호를 확인해
  다음 Work ID와 work slug를 한 번 제안한다. 담당자가 동의하면 작업 목록과 `진행 예정` 또는 `진행 중`으로 기록한다.
- 이미 지정됐거나 진행 중인 Work ID가 같은 작업을 포함하면 다시 묻지 않고 해당 ID를 재사용한다.
- 조사·분석과 기능 MD 수정만으로 끝나는 작업은 Worktree를 만들지 않는다. 실제 Source 구현은 Work ID 승인 후
  저장소별 최신 `origin/dev` 기반 독립 Worktree와 Feature Branch에서 시작하고 기존 Worktree를 보존한다.
- 같은 Work ID의 같은 PR 작업은 기존 Worktree를 재사용한다. 독립된 다음 결과물이나 다음 PR은
  새 Work ID와 새 Worktree를 사용한다.
- `_v0.1`은 Branch Version이다. 같은 Work ID를 계속하면 기존 Branch를 재사용하고, 같은 저장소에서
  Branch를 새로 만들어야 할 때만 충돌하지 않는 다음 Version을 사용한다.
- 여러 저장소에 걸친 같은 하위 작업은 동일한 Work ID와 work slug를 사용한다.
- Work ID 아래에는 담당자가 정한 세부 작업 목록을 두고, 추적표에는 work slug, 작업 요약, 저장소,
  상태, Branch, Push, PR과 `dev` 병합 정보를 저장소별 한 행으로 기록한다.
- PR 생성 시 LLM이 해당 Work ID에 PR 정보를 연결할지 한 번 제안한다. 동의하면 실제 PR 링크·상태·생성일과
  확인된 원격 Branch·최근 Push SHA·일자를 함께 기록하며, 이 PR 링크를 이후 자동 동기화 동의로 본다.
- PR 링크가 기록된 작업은 담당 LLM이 해당 작업을 재개하거나 PR을 처리하기 전에 실제 GitHub 상태를 확인한다. 병합됐다면 추가 질문 없이
  Merge SHA·일자와 완료 상태를 갱신한다. Context Hook은 GitHub·Ledger를 스캔하거나 문서를 직접 수정하지 않는다.
- PR 연결을 동의하지 않은 작업은 자동 추적하지 않는다. 기능 문서 기록 유무를 GitHub Action 병합 조건으로 강제하지 않는다.
- LLM은 로컬 추측값이 아니라 Git·GitHub에서 확인한 값만 반영하며 전체 Commit 이력을 문서에 복제하지 않는다.

필요할 때만 `Task-Version`을 사용한다. 구현 전에 Snapshot과 지시가 일치하면
`MASTER CONTEXT PASS`를 보고한다. 다르거나 범위 확장이 필요하면
`MASTER CONTEXT BLOCKED`를 보고하고 멈춘다.

현재 CMS 최소 범위 안의 세부 설계·검증·테스트는 팀원이 자율적으로 결정한다. 새로운 화면,
기능, 역할, 워크플로, 외부 연동, 대형 데이터 구조를 추가할 때만 팀장 승인을 요청한다.

## 전체 동기화

`깃 pull 해줘`, `전체 Git 최신화`, `워크스페이스 최신화`는 다음을 의미한다.

```text
urizo-final-master/scripts/sync-workspace.ps1 -ApproveNetwork
```

- Master를 먼저 확인하고 이어서 Source 네 저장소를 모두 확인한다. 한 저장소의 보존·차단 결과는 관계없는 깨끗한 Source 동기화를 중단하지 않는다.
- Dirty canonical은 원격 Ref만 fetch하고 `PRESERVED`로 보고한다. 해당 Working Tree는 갱신하지 않는다.
- 모든 canonical이 깨끗하고 차단되지 않았을 때만 Workspace AGENTS, Codex·Claude Context Hook, Git Pull Gate를 동기화한다. Dirty·차단 canonical이 있으면 공용 Hook과 현재 컨텍스트 갱신을 보류하고 다음 안전한 전체 동기화에서 재개한다.
- Hook 갱신 시 AGENTS 지문이 바뀌면 현재 턴에 전체 기준을 한 번 다시 읽고, 바뀌지 않았으면 짧은 Checkpoint만 갱신한다.
- 깨끗한 `dev`만 `origin/dev`로 Fast-forward한다.
- Feature Branch는 Branch를 바꾸거나 `dev`를 자동 Merge/Rebase하지 않는다.
- Dirty는 `PRESERVED`, Diverged·Origin 불일치는 `BLOCKED`, Upstream 없음은 `WARN`으로 해당 저장소에만 보고한다. 자동 Branch 전환·Merge/Rebase·Reset·Stash는 하지 않는다.
- 동기화 뒤 Master Spec과 Snapshot을 다시 읽는다.

## 완료 판단

- 로컬 변경이나 미병합 PR을 완료로 기록하지 않는다.
- 완료는 Source `origin/dev` 병합 SHA와 필요한 테스트 결과로 판단한다.
- Snapshot에는 현재 범위, 중요한 상태, Source SHA, Blocker만 짧게 기록한다.
- 세부 구현 이력과 추적표를 Master에 복제하지 않는다.

## Notion

- Notion은 선택적인 표시 화면이며 구현 원본이 아니다.
- 명시적 요청이 있을 때만 Git과 Snapshot에서 확인된 결과를 반영한다.
- Git과 Notion이 다르면 Git을 따르고 차이만 보고한다.
