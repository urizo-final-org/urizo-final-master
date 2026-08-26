# AX Module Studio 현재 상태

> Updated: 2026-08-26 (Asia/Seoul)
> Snapshot-Version: `v1.3-light`
> Owner: Min Seungjun (`tmdwns0531`)

## 현재 기준

- 제품 범위: [로컬 데모 CMS 최소 범위](../product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md)
- Git·팀 운영: [Master·Source 운영 정책](MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md)
- 현재 우선순위: AI 핵심 기능 2~6번 담당자 배정을 마쳤으며 각 담당자가 심층 조사와 방향 수립을 진행한다.
- 이전 CMS Spec, Wave, 업무분장, 추적표, 인수인계 이력은 현재 권한이 아니다.
- 업무분장과 Slice 체계는 CMS 기본 기능 확인 후 굵직한 기능 단위로 다시 정한다.

## 확인된 저장소 기준

| 저장소 | `origin/dev` |
|---|---|
| Master | `b85736e1d738c9027fa0ebf217e32829962b67dc` |
| Frontend | `7123b362cfd0231fdfe8bad3606096c5aa244bd0` |
| Backend | `a3d30d544334a7f2e3824fd2f890dffaab6f7216` |
| Orchestrator | `0720bd2df5f639c997a645f3c7a7d01c34ddbd01` |

개인별 local-only 변경은 canonical 완료 상태가 아니다. 이를 자동으로 삭제·Reset·Stash·Branch
전환하지 않으며, 새 작업은 승인된 범위와 깨끗한 최신 `dev` 기반 별도 Branch 또는 Worktree에서 시작한다.

## 구현 상태

- Master·Frontend·Backend의 축소 CMS 변경은 `origin/dev`에 Merge됐다.
- Frontend에는 템플릿 적용·미리보기와 페이지 범위 전용 자연어 관리 사이드 패널 목업을 반영했다.
- Backend에는 CMS를 Controller·Service·Repository·DTO 계층으로 분리하고 업무 데이터 Repository를 Spring Data JPA로 전환했다.
- 사용자 화면은 `/`, 관리자 화면은 `/admin`으로 분리했다.
- 관리자 화면은 회원·메뉴·콘텐츠·게시판·템플릿 관리로 구성했다.
- 메뉴는 정적 콘텐츠 또는 게시판과 연결하고, 템플릿은 Header/Footer·스타일·메인 대표 이미지·문구를 관리한다.
- 회원·세션과 메뉴·콘텐츠·게시판·게시글·템플릿은 JPA를 사용하며, CMS 업무 데이터의 `JdbcTemplate` 의존은 제거했다.
- Frontend 테스트 15개·타입 검사·빌드와 Backend 전체 테스트 103개·Docker 이미지 패키징을 통과했다.
- 최신 이미지로 Backend·Frontend·Nginx를 재기동하고 공개 화면·CMS 공개 API·관리자 로그인과 주요 조회 API를 확인했다.
- AI 핵심 기능 2~6번 담당자와 공통 경계는 [향후 고려사항](../product/AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md)에 정리했다.
  현재는 기능별 조사 단계이며 실제 구현은 중간점검과 최소 완료 범위 확정 후 시작한다.
- 담당자 배정은 완료됐지만 기능별 첫 Work ID와 상세 작업 목록은 아직 정하지 않았다. 실제 새 작업 지시 시
  담당 LLM이 다음 Work ID와 work slug를 제안한다.

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
Snapshot-Version: v1.3-light
Slice/Work-Slug: <assigned value>
Task-Version: <assigned value or N/A>
Worker: <name / GitHub ID>
Repositories: <Frontend, Backend, Orchestrator 중 해당 항목>
Scope: <최소 CMS 완료 결과>
Master-Commit: <checked-in commit>
```

Notion 쓰기, Git push, PR, merge, Cloud 배포는 각각 명시적으로 요청된 경우에만 수행한다.
