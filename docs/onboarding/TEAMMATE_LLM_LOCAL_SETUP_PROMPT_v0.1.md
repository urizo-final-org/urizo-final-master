# Teammate LLM local setup prompt v0.1

Replace the placeholders and send the entire block to the teammate's coding LLM.

```text
나는 AX Module Studio 팀원이다.

이름: <본인 이름>
GitHub ID: <본인 GitHub ID>
희망 설치 상위 경로: <경로를 모르겠으면 안전한 경로를 먼저 제안>

Canonical Master Repository:
https://github.com/urizo-final-org/urizo-final-master.git

AX Module Studio 팀 개발환경을 안전하게 구성하라.

1. 최종 sibling 구조는 다음과 같아야 한다.

   AX-Module-Studio-Workspace/
     urizo-final-master/
     urizo-final-frontend/
     urizo-final-backend/
     urizo-final-orchestrator/

2. 상위 AX-Module-Studio-Workspace에는 .git을 만들지 마라.
3. Master가 없다면 canonical Master를 먼저 clone하라.
4. Master AGENTS.md와 그 문서가 지정한 최신 handoff, traceability,
   team roadmap, bootstrap spec을 완독하라.
5. Master의 모델별 지시 라우팅, 다중 OS 로컬 개발 명세, 현재 인프라
   기준을 읽어라. Codex-compatible agent는 AGENTS.md, Claude Code는
   CLAUDE.md import를 통해 동일한 공통 규칙을 사용하라.
6. 먼저 읽기 전용 Preflight를 수행하고 Host OS, PowerShell Version,
   Git, branch/HEAD/dirty, Docker/WSL, DB, Port, Health 상태를 보고하라.
   macOS/Linux에서는 pwsh, Windows에서는 지원되는 PowerShell을 사용하고
   Repository 경로를 OS 중립적으로 구성하라.
7. Routine PowerShell, Git, Docker, Maven, Node, Python 명령은 네가
   version-managed script로 실행하라. 내가 수동으로 복사하게 하지 마라.
8. Network, Git/Docker 로그인, MFA, 관리자 권한, 설치, 재부팅,
   Secret 등록, local-full 변경 경계는 정확히 설명하고 승인을 요청하라.
9. 승인 후 Master bootstrap wrapper로 누락된 Source dev branch를
   sibling에 구성하고 Backend local-full bootstrap을 위임 실행하라.
10. 기존 비어 있지 않은 폴더, 다른 origin, dirty worktree를 덮어쓰지 마라.
   reset, clean, stash, checkout, rebase, DB 초기화, Volume 삭제를 금지한다.
11. Secret 원문이나 전체 digest를 채팅, 명령, 로그에 출력하지 마라.
12. 마지막에 workspace health를 실행하고 다음 형식으로 보고하라.

   SETUP PASS 또는 SETUP BLOCKED
   - 네 canonical origin
   - 각 branch/HEAD/dirty
   - 상위 .git 부재
   - Docker/local-full 상태
   - Flyway 성공/pending
   - Service URL
   - 경고와 남은 사람 작업

13. 세팅 중 제품 구현, commit, push, PR은 하지 마라.
14. 완료 후 AX-Module-Studio.code-workspace를 개발 진입점으로 안내하라.
```

`SETUP PASS` 전에는 업무 시작 프롬프트를 전달하지 않는다.
