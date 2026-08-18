# AX Module Studio Master·Source Git·Notion 운영정책 v0.1

> 확정자: 민승준 (`tmdwns0531`), 팀장·Integration/Contract owner
> 최초 확정일: 2026-08-14 (Asia/Seoul)
> Git branch policy update: 2026-08-18 (Asia/Seoul)
> 운영모델: Git 단일 작업 기준 + Master LLM 상태/WBS + Gate 단위 Notion 시각화

## 1. 권한 경계

| 대상 | 민승준 (`tmdwns0531`) | 팀원 |
|---|---|---|
| Master Repository | 문서·Manifest·상태/WBS 변경, Push, PR, Merge | Read·Clone·Fetch·Pull만 |
| Frontend·Backend·Orchestrator | 통합 검토·승인·Merge | 배정된 Slice의 Branch·Commit·PR |
| Notion MCP | 연결·조회·현행화 | 연결·자동화·쓰기 금지 |
| Notion 화면 | 관리·편집 | 필요한 경우 사람 기준 열람 |

- 팀원 LLM은 Master Branch, Commit, Push, PR을 만들지 않는다.
- 팀원은 변경이 실제로 발생한 Source Repository에만 PR을 만든다. 빈 PR은 만들지 않는다.
- 하나의 Slice가 여러 Source Repository를 변경하면 같은 Slice ID·Version으로 Repository별 PR을
  분리하고 서로 연결한다.
- Master와 Notion의 쓰기 권한은 팀장 전용이다. 팀장 지시 없는 코드 작업·PR·Merge·상태 보고는
  Notion 쓰기 권한을 의미하지 않는다.

## 2. `dev` 통합 브랜치와 `main` 수동 승격 정책

다음 규칙은 Master, Frontend, Backend, Orchestrator 네 Repository에 동일하게 적용한다.

```text
Agent-PR-Base: dev
Main-Promotion: manual-team-lead-only
```

1. `dev`는 유일한 일상 통합 브랜치다. 모든 Feature Branch와 모든 LLM·Agent 생성 PR의 Base는
   반드시 `dev`다.
2. `main`은 팀장 민승준이 주기적으로 수동 승격하는 Release Snapshot Branch다. 로컬 LLM과
   Coding Agent는 `main`에 Push하거나, `main` 대상 PR을 생성·병합하거나, `main`을 삭제·재생성하거나,
   그 밖의 방식으로 `main`을 전진시키지 않는다.
3. `PR 만들어줘`, `전체 Git 최신화`, `동기화해줘`, `배포 준비해줘` 같은 일반 요청은 `main`
   변경 권한을 포함하지 않는다. Agent는 항상 `dev`를 Base로 사용한다.
4. 팀원은 Feature Branch만 Push하고 `dev` 대상 PR을 만든다. 팀장 계정의 Ruleset bypass는
   `dev` 복구·통합과 `dev` 대상 PR 승인·병합에만 사용한다.
5. 팀장의 `dev` → `main` 승격은 사람 주도의 별도 수동 작업이다. 승격 시 Head Branch 자동 삭제로
   `dev`가 제거되지 않도록 확인하고, Agent가 그 작업을 대신 수행하지 않는다.

### 2026-08-18 Master `dev` 복구 기록

- Master PR #4의 `dev` → `main` 병합 뒤 원격 `dev`가 삭제된 상태를 확인했다.
- 로컬의 보존된 현재 통합 작업본 `9a5ae0f34db8eaeba2f2fe9b88dfcc168f7cfb8d`에서 원격 `dev`를
  non-force Push로 재생성했다.
- 기존 `main`은 `afa5244f2c9bb6e55bb45fcb556a356746d91a00` 상태로 보존했으며 되돌리거나
  추가 수정하지 않았다.
- 이후 모든 Agent PR은 `dev`만 대상으로 하며, `main` 승격은 팀장이 주기적으로 수동 수행한다.

## 3. Git 식별 규칙

작업자 식별은 중복 가능한 이름보다 확인된 GitHub ID를 기준으로 한다. 한글 이름은 PR 본문에
병기한다.

```text
Branch
feature/<github-id>_<slice-id-lower>-<work-slug>_<version>

Commit
<type>(<SLICE-ID>/<github-id>): <result>

PR title
[<SLICE-ID>][<github-id>] <result>
```

예시:

```text
feature/jcy644542_axms-fnd-03-auth-rbac_v0.1
feat(AXMS-FND-03/jcy644542): implement project-scoped RBAC
[AXMS-FND-03][jcy644542] Production Auth/RBAC MVP
```

PR 본문 필수 필드:

```text
Slice-ID:
Slice-Version:
Worker: <name> / <github-id>
Repository:
Depends-On:
Connected-PRs:
Contract-Version:
Migration-Revision / N/A:
Verification:
Blocker:
Next-Gate:
```

## 4. 상태 판정과 Master 현행화

| 상태 | 최소 증거 |
|---|---|
| `READY` | 팀장이 Slice·담당자·범위를 확정 |
| `IN_PROGRESS` | 원격 Feature Branch 또는 팀장 확인 작업 증거 |
| `REVIEW` | Source Repository PR URL·Head SHA |
| `DONE` | Source Repository `origin/dev` 병합 SHA와 필수 검증 결과 |
| `BLOCKED` | 구체적인 의존성·실패 증거·해제 조건 |

- Master 문서의 `DONE`은 반드시 Frontend·Backend·Orchestrator의 실제 `origin/dev`를 Fetch한 뒤
  판정한다. 로컬 커밋, 미Push Branch, 미병합 PR을 완료로 기록하지 않는다.
- Master의 [`LLM_PROJECT_STATUS_SNAPSHOT.md`](LLM_PROJECT_STATUS_SNAPSHOT.md)는 현재 Wave, 담당,
  상태, Blocker, 다음 Gate, Source `origin/dev` SHA를 담는 팀원 LLM용 경량 인덱스다.
- Master 갱신은 팀장이 수행하며, 상세 구현을 복제하지 않고 Source Spec·PR·Commit·검증으로
  연결한다.
- Master 상태/WBS는 Slice 배정·상태 전환·병합·Blocker·Milestone 변경 시 갱신한다. 개별 코드
  Commit마다 Master를 수정하지 않는다.

## 5. 팀장 갱신·인계 핸드셰이크

팀원별 작업 단위와 버전은 Master의
[`LLM_PROJECT_STATUS_SNAPSHOT.md`](LLM_PROJECT_STATUS_SNAPSHOT.md)에서 관리한다. 이 값은 구현
코드 버전이 아니라 `작업자 + Slice + 범위 + 대상 Repository + 의존성 + 다음 Gate`로 구성된
할당 패킷의 `Task-Version`이다.

고정 순서:

1. 팀장 민승준이 관련 Source Repository의 실제 `origin/dev`, 병합 PR, 검증 결과를 확인한다.
2. 팀장이 Master 상태표의 Snapshot version과 해당 작업자의 Slice/Task version, 상태, 다음 작업,
   다음 Gate를 갱신하고 Master에 반영한다.
3. 팀장이 팀원에게 `MASTER UPDATE COMPLETE` 패킷으로 갱신 완료, 다음 작업, Master Commit을
   간략히 통보한다.
4. 팀원이 `깃 pull 해줘`라고 요청하면 로컬 LLM은 Master를 먼저 안전 동기화한 다음 Frontend,
   Backend, Orchestrator 세 Source Repository를 모두 동기화한다.
5. 로컬 LLM은 최신 Master `AGENTS.md`, 운영정책, 상태표를 다시 읽고 통보받은 Snapshot/Slice/Task
   version과 작업자·대상 Repository가 일치하는지 확인한다.
6. 로컬 LLM은 구현 전에 `MASTER CONTEXT PASS` 또는 `MASTER CONTEXT BLOCKED`로 인지 결과와
   다음 작업을 보고한다. 불일치할 때는 추측해서 구현하지 않는다.

팀장 통보 형식과 로컬 LLM 인지 보고의 필수 필드는 상태표의 템플릿을 사용한다. Master 변경
권한은 계속 팀장에게만 있고, 팀원은 인지 결과나 진행 상태를 Master에 직접 쓰지 않는다.

## 6. `깃 pull 해줘`의 고정 의미

팀원이 공통 Workspace에서 LLM에 `깃 pull 해줘`, `전체 Git 최신화`, `워크스페이스 최신화`라고
요청하면 이를 네 Repository의 **안전 동기화 요청**으로 해석한다. 이 요청은 Canonical Git의
Fetch와 Fast-forward에 대한 해당 작업의 Network 승인이다. 로그인·MFA·Rebase·충돌 해결·Branch
전환·로컬 변경 삭제까지 승인한 것은 아니다.

기본 범위는 항상 Master, Frontend, Backend, Orchestrator 전체다. 현재 열려 있는 Repository나
작업자가 수정할 예정인 Repository 하나로 범위를 축소하지 않는다. 다만 안전 동기화는 모든
Working Tree를 무조건 `origin/dev`로 덮는 명령이 아니다. 깨끗한 `dev`만 `origin/dev`로
Fast-forward하고, Feature Branch와 로컬 변경은 아래 규칙대로 보존한다.

고정 순서:

1. 네 Repository의 Origin, Branch, HEAD, Dirty 상태를 읽기 전용으로 확인한다.
2. Master를 먼저 `fetch --prune`한다.
3. Master가 깨끗한 `dev`이고 `origin/dev`로 Fast-forward 가능할 때만 갱신한다.
4. 최신 Master `AGENTS.md`, 이 정책, LLM 상태/WBS 스냅샷을 다시 읽는다.
5. Frontend·Backend·Orchestrator를 모두 `fetch --prune`한다.
6. 깨끗한 `dev`는 `origin/dev`로 Fast-forward한다.
7. 깨끗한 Feature Branch는 자신의 추적 원격 Branch로만 Fast-forward한다. `dev`를 자동
   Merge·Rebase하지 않고 `origin/dev` 대비 차이를 보고한다.
8. Dirty, Diverged, Upstream 없음, Origin 불일치는 변경하지 않고 정확한 Repository만 보고한다.

이 절차는 `scripts/sync-workspace.ps1 -ApproveNetwork`가 소유한다. Master가 최신 정책을 제공하지
못하면 Source Working Tree 갱신 전에 중단한다.

새 작업의 표준 Branch 수명주기는 다음과 같다.

```text
깨끗한 로컬 dev Checkout
→ origin/dev Fast-forward
→ feature/<github-id>_<slice-id-lower>-<work-slug>_<version> 생성
→ 작업·검증·dev 대상 PR
```

Canonical Checkout을 계속 `dev`로 유지해야 하거나 병렬 작업이 필요하면 별도 Git Worktree에서
Feature Branch를 사용한다. Dirty, Diverged, local-only commit이 있는 Checkout은 자동으로
`dev` 전환하지 않으며, 로컬 상태를 보존하고 정확한 차단 원인을 보고한다.

## 7. Notion 운영모델 고정

Notion은 구현 원본이 아니라 팀장·팀원·멘토가 보는 시각적 관리면이다.

```text
Source 작업
→ Repository별 PR
→ dev 병합·검증
→ 팀장이 Master 상태/WBS 갱신
→ 팀장 명시 지시 시 변경된 Gate만 Notion 현행화
```

Notion 갱신 Gate:

- Slice 담당·우선순위·기간 변경;
- Slice 상태의 `READY → IN_PROGRESS → REVIEW → DONE/BLOCKED` 전환;
- 연관 Source PR 병합 완료;
- 중요한 Blocker 발생·해제;
- Mentor 점검·주간 점검·발표 준비.

팀원 LLM은 Notion MCP 없이 Master를 읽고 작업한다. Notion 현행화는 Git의 현재 Source
`origin/dev`, PR, 검증, Master 스냅샷을 확인한 뒤 변경된 행만 처리한다. Git과 Notion이 다르면
Git 증거와 팀장 확정 결정을 우선하고 차이를 보고한다.
