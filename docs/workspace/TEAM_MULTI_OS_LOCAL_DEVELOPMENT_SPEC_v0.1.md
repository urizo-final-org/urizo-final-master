# AX Module Studio team multi-OS local development specification v0.1

> Updated: 2026-08-14 (Asia/Seoul)
> Applies to: Windows, macOS, and the implemented Linux/WSL path
> Runtime owner: Backend; workspace coordination owner: Master

## 1. Verified source evidence

| Evidence | Result |
|---|---|
| [Backend PR #4](https://github.com/urizo-final-org/urizo-final-backend/pull/4), merge `6fcc0c726e19126a392efddedba03b7a013ee1f0` | macOS/PowerShell Core Docker discovery, path handling, certificate trust, Unix secret permissions, and executable-bit compatibility merged to `dev` |
| Backend commit `289291385577064510b7f4b0684bd87fddd93778` in [PR #7](https://github.com/urizo-final-org/urizo-final-backend/pull/7) | Windows PowerShell 5.1 no longer fails under StrictMode when `$IsWindows` is undefined; migration verification passed |
| Team-lead report | the team members' individual PCs completed the applicable local flow without an outstanding OS-specific blocker |

Backend PR #4 changed Backend-owned runtime scripts. This Master revision additionally removes
Windows-only path separators from Master-owned bootstrap/health/validation paths and makes the parent
Claude routing block updateable on already-configured PCs.

## 2. Support matrix

| Host | Required shell for Repository scripts | Support state | Notes |
|---|---|---|---|
| Windows 10/11 | Windows PowerShell 5.1 or PowerShell 7 | verified | Docker CLI is resolved from `PATH` first, then approved Docker Desktop paths; PR #7 preserves 5.1 StrictMode compatibility |
| macOS | PowerShell 7 (`pwsh`) | verified by PR #4/team PC | Docker CLI must be on `PATH`; certificate trust may use System/login keychains; Unix permission modes apply |
| Linux/WSL2 | PowerShell 7 (`pwsh`) | implemented path | Docker CLI must be on `PATH`; CA bundles use standard Linux locations; report a fresh full acceptance result before calling a new host verified |

The LLM detects the host and current PowerShell runtime. It must not ask a macOS/Linux teammate to run
`powershell.exe`, and it must not assume Windows paths, `icacls`, or Windows certificate stores outside
the Windows branch.

## 3. Container-first and host-native boundaries

The canonical full environment is Docker Compose owned by Backend. A teammate needs Git, PowerShell,
Docker Engine with Compose v2, and enough local resources. JDK, Maven, Node/pnpm, Python/uv are built
inside pinned images for the full stack.

Host-native development or verification uses the exact versions in
[`CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md`](../architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md).
Do not silently use a different major version because a teammate's OS package manager selected it.

## 4. Portable script rules

- Construct Repository paths with `Join-Path` or forward-slash Repository-relative paths; do not embed
  Windows separators in cross-platform paths.
- Resolve `docker` from `PATH` first. Windows-only Docker Desktop fallbacks run only on Windows.
- Use `[System.IO.Path]::PathSeparator` for `PATH` changes.
- Use Windows ACLs only on Windows and `chmod 700/600` for local secret directories/files on Unix.
- Never print or commit Secret contents, generated trust bundles, or host-specific absolute paths.
- Preserve executable bits for mounted `.sh` and `.pl` helpers.
- Do not introduce symlink-dependent project instructions. `CLAUDE.md` imports are portable and avoid
  the Windows administrator/developer-mode requirement for symlink creation.

## 5. Per-PC acceptance

Existing team verification proves the current reviewed PCs, not every future machine. On a new or
reinstalled PC, the local LLM must:

1. report host OS, architecture, PowerShell version, Git, Docker CLI/Engine, and Compose availability;
2. preserve dirty branches, Secrets, databases, and Volumes;
3. obtain approval before installation, login, network download, administrator elevation, or reboot;
4. run the Master preflight and Backend-owned full bootstrap/health through the versioned wrappers;
5. report `SETUP PASS` only after the services, Flyway, and HTTP health gates pass.

The teammate should not manually translate commands between operating systems; the local LLM selects
the correct executable and reports any unavoidable human boundary.

## 6. 작업별 Runtime·Flyway 판단

- `RUNTIME-CHANGE-SCOPE`: 실행 모드는 현재 Work ID의 활성 Source Worktree에 있는 staged·unstaged·untracked 파일과
  `origin/dev`에 아직 없는 현재 Work ID Commit을 함께 보고 정한다. 다른 Work ID의 보존 Worktree는 범위에 넣지 않는다.
  자연어 요청은 이 근거로 확정한 Profile·Service·SourceRoot만 Script에 전달하며, 안전한 실행 모드가 달라지는
  모호함이 남으면 추측하지 않고 한 번 질문한다.
- `RUNTIME-HMR-BAN`: Frontend `package.json`, Lockfile, Dockerfile, Vite·Nginx 설정이 바뀌었거나 Backend·Orchestrator·
  MCP Server 변경이 함께 있으면 HMR을 사용하지 않고 `full` 재빌드·재기동을 사용한다.
- `RUNTIME-FULL-REBUILD`: 직전 전체 동기화에서 Source가 하나라도 갱신됐거나 사용자가 전체·로컬 재기동을
  명시하면 `full -Rebuild -ApproveNetwork`와 네 활성 SourceRoot를 사용한다. Rebuild 없는 기존 Image 기동으로 약화하지 않는다.
  여러 Source 변경, 전체 재빌드 요청, DB·Flyway·Compose·Network·Secret 영향 또는 Frontend 비-Live 변경을
  Image에 반영할 때도 같은 옵션과 활성 `BackendSourceRoot`, `FrontendSourceRoot`, `OrchestratorSourceRoot`,
  `McpSourceRoot` 조합을 모두 전달한다.
- `RUNTIME-ISOLATED-HEALTH`: 건강한 Profile의 단일 Service만 격리 갱신할 수 있으며, 갱신 뒤에는 해당
  Service만이 아니라 선택한 Profile 전체 Health를 확인한다. `coding-runtime`과 `mcp-server` 격리 갱신은
  `full`에서만 허용하고 DB·Flyway·Volume Service는 대상에서 제외하며 DB·Volume을 변경하지 않는다.
- `RUNTIME-FAIL-CLOSEOUT`: 범위 밖 Service·선행 작업·공유 Volume·Secret이 원인이거나 같은 원인이 두 번 실패하면
  추가 보완·세 번째 재시도를 중단하고 `PARTIAL` 또는 `NOT VERIFIED`와 정확한 재현 명령을 보고한다.
- `RUNTIME-SERIAL-INTEGRATION`: 독립 Worktree의 Source 구현·단위 테스트는 병렬로 할 수 있지만 공유 DB·Volume을
  사용하는 `full`·Flyway 통합 검증은 한 번에 하나만 직렬 실행한다.
- `DATABASE-FLYWAY-LIMIT`: Flyway는 Migration·Schema 변경 검증 또는 공식 `full` 통합 흐름에 필요할 때만 실행한다.
  후보 SHA 조합을 고정하기 전에는 단위·계약·정적 검증을 우선하고 코드 수정마다 `full`·Flyway를 반복하지 않는다.
  후보 SHA 조합에서 기본 한 번, 현재 범위 Source 결함 수정 뒤 한 번만 재검증하며 세 번째 실행은 팀장 승인이 필요하다.
  관련 없는 변경의 중간 검증으로 단독 실행하거나 Repair/Clean, DB 초기화, History 수정, Volume 삭제로 통과시키지 않는다.

### 로컬 Wrapper 보존 조건

- `RUNTIME-LOCAL-WRAPPER`: 명시적인 로컬 실행 요청은 `scripts/start-local-cms.ps1`과
  `-ApproveLocalMutation`을 사용한다. CMS-only는 `spring-core`, 전체·로컬 재기동은 MCP Server를 포함한 `full`이다.
  요청 Profile이 이미 정상이고 반영할 Source 변경이 없으면 기존 Container를 재사용하고 즉시 종료한다.
  중지 상태는 기존 Image로 기동하되 최초 실행처럼 Image가 없으면 Network 승인 뒤 `-ApproveNetwork`를 추가한다.
  `spring-core`는 Coding Runtime과 MCP Server를 성공 조건에서 제외한다. 공통 Script의 정확한 차단 원인만
  수정하며 전체 실행 실패를 임의 Docker 명령으로 우회하지 않는다.

### Frontend Live 보존 조건

- `RUNTIME-FRONTEND-LIVE`: 사용자가 Frontend-only 반영을 명시하고 변경이 `src`, `public`, `index.html`에만
  있으며 CMS가 건강할 때만 `scripts/start-frontend-live.ps1`을 사용한다. 한 번에 하나의 활성 Work ID·
  Frontend Worktree만 Watch하고 Worktree 전환 전에 기존 Watch를 종료한다. Git·Secret·`node_modules`는
  동기화하지 않는다. Watch 종료 뒤 `-RestoreImageOnly`로 Image-only Frontend를 복원하며, PR 전에는 Watch를
  종료하고 실제 Image Build, Frontend 테스트·타입 검사와 전체 Health를 통과한다.
