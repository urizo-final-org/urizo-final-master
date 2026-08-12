# AX Module Studio 팀원 원클릭 시작 가이드 v0.1

> 대상: AX Module Studio 5인 개발팀  
> 1차 제품 목표: **수동으로 운영 가능한 전체관리자 CMS 제품을 다섯 명의 충돌 없는 vertical slice로 조립한다.**

## 1. 이번 1차 목표

현재 시스템은 Local Full 인프라와 기술 E2E 기반은 있으나 전체관리자 CMS 제품은 아직 완성되지 않았다. 1차 조립 완료 기준은 다음과 같다.

| 전체관리자 CMS 영역 | 완료 결과 |
|---|---|
| 로그인·권한·회원 | Production 로그인, 사용자/역할, Project RBAC, 회원 조회·초대·상태·역할 관리 |
| 메뉴 | MenuSpec Draft/Version, 경로 검증, Preview |
| 콘텐츠·페이지 | Content/PageSpec Draft/Version, 구성요소·데이터 연결, Preview |
| 게시판 | Board/Post 상태, 역할 검증, soft delete, Audit |
| 사이트 디자인 | SiteTemplateSpec Version, Header/Footer/Layout/Token, 반응형 Preview |
| 게시·복구 | Approval, immutable Site Release, Publish, Rollback, 통합 Audit |
| 실제 사용자 사이트 | 활성 Site Release만 읽는 Renderer; Draft 외부 노출 금지 |

자연어 CMS, 실제 공공데이터 Connector, RAG 튜닝, PathPolicy/Coding, LLM DevOps는 이 수동 CMS 제품 위에 후속으로 올린다. 1차 목표와 섞어서 동시에 구현하지 않는다.

## 2. 한 Workspace로 여는 방법

GitHub Desktop, Codex 또는 사용하는 IDE의 **Clone Repository**에서 아래 저장소 하나만 먼저 Clone한다.

```text
https://github.com/urizo-final-org/urizo-final-master.git
```

Clone 위치는 다음 형태로 만든다.

```text
AX-Module-Studio-Workspace/              # .git 없음
  urizo-final-master/                    # 최초 Clone 대상
```

처음에는 `urizo-final-master`를 LLM 프로젝트로 연다. 아래 설정 지시문을 LLM에 전달하면 Master wrapper가 읽기 전용 Preflight 후 승인을 받아 세 Source Repository를 sibling으로 구성한다.

- [LLM 최초 로컬 세팅 지시문](TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md)

설정이 끝나면 상위 폴더에 생성된 `AX-Module-Studio.code-workspace`를 연다. 이를 지원하지 않는 도구는 `AX-Module-Studio-Workspace` 상위 폴더를 연다.

```text
AX-Module-Studio-Workspace/              # 하나의 Vibe Coding 화면, Git 아님
  AGENTS.md
  AX-Module-Studio.code-workspace
  urizo-final-master/                    # 문서·업무분장·bootstrap
  urizo-final-frontend/                  # React 제품 UI
  urizo-final-backend/                   # Spring·Contract·Flyway·Compose
  urizo-final-orchestrator/              # Coding Runtime; 1차 CMS에서는 원칙적으로 변경 없음
```

네 Repository를 한 화면에서 읽고 수정하되 Commit·Push·PR은 각 Repository의 `.git`별로 분리한다. 상위 폴더에 `.git`을 만들거나 Source를 Master 안으로 복사하지 않는다.

## 3. LLM에 처음 전달할 문장

다음 문장만 전달한다.

```text
urizo-final-master/AGENTS.md와
docs/onboarding/TEAMMATE_ONE_CLICK_CMS_START_GUIDE_v0.1.md,
docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md를 전체 읽고
AX Module Studio 팀 개발환경을 구성해줘.
먼저 읽기 전용 Preflight를 수행하고, 반복 가능한 명령은 네가 실행해.
로그인·MFA·관리자 권한·설치·재부팅·Secret 입력 경계에서만 나에게 요청하고,
완료되면 반드시 SETUP PASS 또는 정확한 blocker를 보고해.
```

팀원은 LLM이 요청하는 로그인, MFA, 관리자 권한, Docker/WSL 설치·재부팅, CMS Secret 입력만 직접 처리한다. Secret 원문을 채팅이나 명령행에 붙여 넣지 않는다.

## 4. 1차 전체관리자 CMS 업무분장

| 팀원 | 1차 담당 Slice | 제품 결과 | 주 소유 경로 |
|---|---|---|---|
| 민승준 (`tmdwns0531`) | `AXMS-FND-01`, `AXMS-FND-04`, `AXMS-CMS-06` | Backend seam, 공통 Approval/Audit, Site Release/Publish/Rollback, 통합 게이트 | Backend contract/Flyway/common/release, Master |
| 정차윤 | `AXMS-FND-03`, `AXMS-CMS-01`, `AXMS-CMS-07` | 로그인/RBAC, 회원 관리, 실제 사용자 Renderer | Backend auth/member/runtime, Frontend auth/members/site-runtime |
| 이재욱 (`LEEJAEWOOK1`) | `AXMS-FND-02`, `AXMS-CMS-02`, `AXMS-CMS-05` | Frontend feature seam, 메뉴, 사이트 디자인/템플릿 | Frontend app/menus/site-design, 대응 Backend feature package |
| 민은지 | `AXMS-CMS-03` | 콘텐츠·페이지 수동 관리 | Backend cms/content, Frontend features/content |
| 윤서 | `AXMS-CMS-04` | 게시판·게시물 수동 관리 | Backend cms/board, Frontend features/boards |

업무분장은 Repository별 수평 분할이 아니다. 각 Slice 소유자가 **Contract → Flyway → Spring → Frontend → E2E**를 끝까지 주도한다. 단, 공용 Contract, Flyway revision, App shell/router, Auth/Error/Approval/Audit, Compose/bootstrap은 민승준의 Integration lane을 통해 직렬화한다.

## 5. 충돌 없는 실행 순서

| Wave | 병렬 가능 작업 | 시작 조건 |
|---|---|---|
| 0 | `AXMS-FND-01` 민승준 + `AXMS-FND-02` 이재욱 | `SETUP PASS` 후 즉시 |
| 1 | `AXMS-FND-03` 정차윤 | AXMS-FND-01/02 병합 후 |
| 2 | `AXMS-FND-04` 민승준 | AXMS-FND-03 병합 후; Contract/Flyway 공용 seam 직렬화 |
| 3 | `AXMS-CMS-01` 정차윤 + `AXMS-CMS-02` 이재욱 + `AXMS-CMS-03` 민은지 + `AXMS-CMS-04` 윤서 | 공용 contract와 migration 번호 예약 후 feature-local package에서 병렬 |
| 4 | `AXMS-CMS-05` 이재욱 | AXMS-CMS-02/03의 참조 contract 안정화 후 |
| 5 | `AXMS-CMS-06` 민승준 | AXMS-CMS-02/03/05의 immutable Version 준비 후 |
| 6 | `AXMS-CMS-07` 정차윤 + 전체 통합 E2E | AXMS-CMS-06 활성 Site Release 준비 후 |

자신의 Wave가 열리기 전에는 구현을 시작하지 않는다. 대신 LLM이 현재 Slice의 사용자 시나리오, 테스트, 계약 제안과 feature-local mock을 준비하게 할 수 있지만 공용 hot spot은 수정하지 않는다.

## 6. 업무 시작 시 LLM에 전달할 내용

`SETUP PASS` 후 팀 리더에게 **Slice ID 하나**를 받은 다음 아래 파일의 템플릿에 본인 이름, GitHub ID, Slice ID를 채워 LLM에 전달한다.

- [LLM 업무 시작 지시문](TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md)
- [상세 업무분장·의존성·DoD](../team/TEAM_VERTICAL_SLICE_OWNERSHIP_AND_ROADMAP_v0.1.md)

LLM은 편집 전에 다음을 보고해야 한다.

1. 현재 네 Repository의 branch/HEAD/dirty 상태
2. 배정된 Slice와 선행 의존성이 열렸는지 여부
3. 수정할 Repository와 예상 경로
4. 공용 hot spot 및 Contract/Flyway 예약 필요 여부
5. Repository별 검증·PR 순서

Slice ID가 없거나 의존성이 닫혀 있거나 공용 seam 예약이 없으면 구현하지 않는다.

## 7. Git 규칙

```text
origin/dev 최신화
→ feature/<github-id>_<동일-slice-slug>_<version>
→ Repository별 검증·Commit·Push
→ Repository별 dev PR
→ 같은 Slice ID와 상호 PR 링크
→ tmdwns0531 Master/Admin 승인·병합
```

- 팀원은 `main/dev`에 직접 Push하지 않는다.
- Force push, reset, clean, 자동 stash, 자동 merge를 금지한다.
- 한 Slice가 Frontend와 Backend를 바꾸면 하나의 PR로 합치지 않고 Repository별 PR을 만든다.
- Backend compatible contract/Flyway/Spring PR을 먼저 병합하고 Frontend consumer PR을 병합한다.
- Orchestrator는 명시적으로 필요한 Coding Slice에서만 변경한다. 1차 수동 CMS 기능을 Python graph로 우회 구현하지 않는다.

## 8. 1차 조립 완료 판정

다음 사용자 흐름이 하나의 Local Full 환경에서 통과해야 전체관리자 CMS 1차 조립 완료다.

```text
관리자 로그인
→ Project/Role 권한 확인
→ 회원·메뉴·페이지·게시판·사이트 디자인 수동 관리
→ Draft Version과 Diff/Preview 확인
→ Approval
→ 하나의 Site Release Publish
→ 실제 사용자 Renderer 확인
→ 이전 Release Rollback
→ Approval/Audit/Job history 확인
```

컨테이너가 healthy인 것, 기존 Local Full 콘솔이 보이는 것, fixture Connector/RAG/Coding E2E가 통과하는 것만으로는 전체관리자 CMS 제품 완료가 아니다.
