# AX Module Studio Git·팀 운영 정책

> Owner: Min Seungjun (`tmdwns0531`)
> 원칙: Git이 구현 기준이며 문서와 절차는 최소한으로 유지한다.

## 권한

- Master 쓰기와 공통 기준 변경은 Min Seungjun만 수행한다.
- 팀원은 Master를 읽고, 배정받은 Source 저장소의 Feature Branch와 PR만 만든다.
- Notion은 팀장이 현재 요청에서 명시한 경우에만 쓴다.
- 코드 작업, PR, Merge, 상태 보고는 Notion 쓰기를 자동 승인하지 않는다.

## Git

네 저장소에 같은 규칙을 적용한다.

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

- Master를 먼저 확인하고 이어서 Source 세 저장소를 모두 확인한다.
- 깨끗한 `dev`만 `origin/dev`로 Fast-forward한다.
- Feature Branch는 Branch를 바꾸거나 `dev`를 자동 Merge/Rebase하지 않는다.
- Dirty, Diverged, Upstream 없음, Origin 불일치는 변경하지 않고 보고한다.
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
