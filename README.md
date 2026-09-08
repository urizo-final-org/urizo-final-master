# AX Module Studio Master

다섯 개의 독립 Git 저장소를 연결하는 경량 공통 기준 저장소다. 제품 Source는 보관하지 않는다.

```text
AX-Module-Studio-Workspace/          # no .git
├── urizo-final-master/
├── urizo-final-frontend/
├── urizo-final-backend/
├── urizo-final-orchestrator/
└── urizo-final-mcp-server/
```

## 현재 기준

- [로컬 데모 CMS 최소 범위](docs/product/AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md)
- [현재 상태 Snapshot](docs/team/LLM_PROJECT_STATUS_SNAPSHOT.md)
- [Master·Source 운영 정책](docs/team/MASTER_SOURCE_NOTION_OPERATING_POLICY_v0.1.md)
- [저장소별 기술스택과 사용 근거](docs/architecture/TECH_STACK_AND_RATIONALE_v0.1.md)
- [문서 목록](docs/README.md)

이전 CMS Spec, 인수인계 이력, 추적표, Wave와 업무분장은 폐기했다. 현재 구현은 위 최소 범위를
벗어나지 않는다. 범위 안의 세부 설계는 자율적으로 진행하고, 새로운 사용자 기능이나 시스템
범위를 추가해야 할 때만 팀장 승인을 요청한다.

## 유지하는 공통 기준

- [다중 LLM 지침 Routing](docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md)
- [팀 Multi-OS 로컬 개발](docs/workspace/TEAM_MULTI_OS_LOCAL_DEVELOPMENT_SPEC_v0.1.md)
- [현재 로컬 인프라](docs/architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md)
- [Workspace Bootstrap](docs/workspace/MASTER_REPOSITORY_AND_BOOTSTRAP_SPEC_v0.2.md)
- [Flyway 예약표](docs/team/FLYWAY_RESERVATION_LEDGER.md)
- [팀원 로컬 설정 Prompt](docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md)
- [팀원 작업 시작 Prompt](docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md)

## Workspace 명령

작업별 필수 문서를 bounded Chunk로 불러오기:

```powershell
.\scripts\load-task-context.ps1 -Profile <Profile>[,<Profile>...]
.\scripts\load-task-context.ps1 -Profile Runtime,Database,Git -BackendSourceRoot <absolute-active-backend-worktree>
```

Profile은 `Product|Git|Runtime|Database|AiFeature|TeamLead|Master` 중에서 고른다. 여러 Profile은 한 호출에서
입력 순서대로 합치며 같은 문서 경로는 첫 등장 한 번만 출력한다. 단일 Profile 호출도 그대로 지원한다.
`AiFeature`는 `-FeatureNumber <2|3|4|5|6>`을 함께 사용한다. 두 번째 이후 Chunk에는 첫 Receipt의
`bundleSha256`과 직전 Receipt의 `chunkSha256`을 각각 `-ExpectedBundleSha256`,
`-PreviousChunkSha256`으로 전달해야 한다.
`Database`는 활성 Backend checkout·Worktree의 절대 경로를
`-BackendSourceRoot <absolute-active-backend-worktree>`로 함께 전달한다.

개인 기능 문서 본문을 읽지 않는 공용 Routing 검증:

```powershell
.\scripts\validate-master-scaffold.ps1 -PublicOnly -BackendSourceRoot <absolute-active-backend-worktree>
```

기존 기준과 변경본의 AGENTS 크기·Source별 Full Hook payload 비교:

```powershell
.\scripts\compare-context-routing.ps1 -BaselineRef origin/dev -WorkspaceRoot <non-Git-workspace-parent>
```

전체 동기화:

```powershell
.\scripts\sync-workspace.ps1 -ApproveNetwork
```

새 구현 시작과 Push·PR 전 Pull Gate:

```powershell
.\scripts\start-feature-work.ps1 -RepositoryName urizo-final-backend -BranchName feature/<github-id>_<work-slug>_<version> -ApproveNetwork
.\scripts\prepare-dev-pr.ps1 -RepositoryPath <feature-worktree> -ApproveNetwork
```

Bootstrap이 설치하는 managed `pre-push` Hook은 두 번째 Gate가 발급한 현재 Head용 Receipt를 읽기 전용으로 확인한다.
다른 세션 때문에 canonical `dev`가 Dirty면 Gate는 그 변경을 보존하고 임시 detached Pull Worktree를 사용한다.

읽기 전용 확인:

```powershell
.\scripts\preflight-workspace.ps1
.\scripts\health-workspace.ps1
.\scripts\validate-master-scaffold.ps1
```

동기화는 로컬 변경을 삭제하거나 Branch를 자동 전환하지 않는다.
