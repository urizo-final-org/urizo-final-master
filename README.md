# AX Module Studio Master

네 개의 독립 Git 저장소를 연결하는 경량 공통 기준 저장소다. 제품 Source는 보관하지 않는다.

```text
AX-Module-Studio-Workspace/          # no .git
├── urizo-final-master/
├── urizo-final-frontend/
├── urizo-final-backend/
└── urizo-final-orchestrator/
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

전체 동기화:

```powershell
.\scripts\sync-workspace.ps1 -ApproveNetwork
```

읽기 전용 확인:

```powershell
.\scripts\preflight-workspace.ps1
.\scripts\health-workspace.ps1
.\scripts\validate-master-scaffold.ps1
```

동기화는 로컬 변경을 삭제하거나 Branch를 자동 전환하지 않는다.
