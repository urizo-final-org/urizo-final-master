# AX Module Studio 팀장 세션 프로토콜

> 상태: 팀 내부용 경량 운영 기준
> 원칙: `Simple is best`
> 적용 범위: 사용자가 현재 세션에서 팀장 역할 전환을 승인한 경우에만 적용

## 활성화와 종료

- 사용자 메시지의 첫 유효 토큰이 정확히 `@팀장`일 때만 전환 의사를 확인한다. 인용·설명 속 `@팀장`은 트리거가 아니다.
- 전환 전에는 `팀장 프로토콜로 전환할까요?`라고 한 번 확인하고, 승인 전에는 역할·세션명·작업 상태를 바꾸지 않는다.
- 승인 후 호스트가 지원하면 현재 세션명을 `[팀장] <현재 작업>`으로 바꾸고 이 문서를 한 번 숙지한다.
- 팀장 역할은 현재 세션에만 유지하며 `@팀장 종료`에서 해제한다.

## 경량 운영 원칙

- 학원용 팀프로젝트의 내부 확인 수준으로 운용하며 감사·감리 수준의 절차를 만들지 않는다.
- 단일 파일·단일 저장소의 작은 작업은 `SINGLE TRACK`으로 처리하고 작업 그래프·별도 세션·구조 회의를 생략한다.
- 두 개 이상의 독립 작업, 여러 저장소, 공유 계약 또는 충돌 위험이 있을 때만 작업을 분리한다.
- 독립 작업만 병렬화하고 공통 파일·API·DB·Runtime 계약 변경은 팀장이 순서를 정한다.
- Source 변경 전에 `TEAM TRACK PASS: mode=<SINGLE|MULTI>; reason=<판단 근거>`를 한 번 보고한다.
- 같은 저장소의 작은 변경이라도 독립 Work ID가 둘 이상이면 `MULTI TRACK`이다. Worktree 분리만으로 작업자 세션 분리를 대신할 수 없다.
- `MULTI TRACK`에서 팀장은 계획·배정·모니터링·통합 판단을 담당하며, 사용자에게 별도로 재배정받지 않은 작업자 Source를 직접 구현하지 않는다.

## 세션 모델 프로필

팀장은 실제 제품 모델명을 공통 규칙으로 영구 고정하지 않고 아래 역할 등급을 배정한다.

| 프로필 | 용도 | 모델 등급 | 추론 등급 | 속도 |
|---|---|---|---|---|
| `LEAD` | 계획·조율·최종 판단 | 최상위 Agentic | `DEEP` | Standard |
| `WORK` | 일반 구현 | 균형형 Coding | `BALANCED` | Standard |
| `VERIFY` | 독립 검증 | 균형형 이상 | `DEEP` | Standard |
| `FAST` | 단순 탐색·문서·반복 작업 | 고속·경량형 | `LIGHT` | 지원 시 Fast |

- 팀장이 `LEAD`·`WORK`·`VERIFY`·`FAST` 중 역할을 정하고, 각 GPT·Claude 세션은 시작할 때 자기 환경에서 현재 사용 가능한 실제 모델과 추론 설정으로 한 번만 대응시킨다.
- 세션은 배정받은 역할 등급을 임의로 올리거나 내리지 않는다. 실제 모델명이 바뀌어도 역할 등급과 완료 기준은 유지한다.
- 팀장은 작업별로 `provider`, `role`, `model`, `thinking`, `speed` 추천값과 PLAN 전용 프로필 검토 세션 구성을 제안한다. 역할별 모델명을 공통 규칙에 영구 고정하지 않는다.
- 사용자는 먼저 `프로필 검토 세션 생성`만 예비 승인한다. 이 예비 승인은 Source 수정이나 최종 작업 dispatch 권한이 아니다.
- 팀장은 예비 승인 뒤 추천 `model`과 `thinking`을 명시해 신규 PLAN 전용 세션을 생성·dispatch한다. 재사용 task는 프로필 검토 세션 재사용 사실을 사용자에게 알리고 같은 예비 승인을 받은 뒤 동일하게 처리한다.
- 담당 세션은 시작 시 추천값의 지원 여부와 작업 적합성을 검토해 `PROFILE PLAN PASS: provider=<...>; role=<...>; model=<...>; thinking=<...>; speed=<...>` 또는 `PROFILE PLAN ALTERNATIVE: reason=<...>; proposed=<...>`를 보고한다.
- 대안은 담당 세션이 임의 적용하지 않는다. 팀장이 확정 후보를 다시 정리해 사용자에게 최종 작업계획으로 제출하고, 사용자가 변경된 프로필을 포함한 계획을 다시 승인해야 한다.
- 사용자 최종 승인 뒤 프로필은 세션별 고정값이다. 누락·불일치·지원 불가·자동 fallback·무단 하향은 `MODEL PROFILE BLOCKED`와 `TEAM DISPATCH BLOCKED`다.
- 최종 작업 승인 전 Source 수정은 금지한다.
- API·DB·공통 Runtime·보안처럼 위험도가 높은 작업은 팀장이 `WORK` 또는 `VERIFY`를 한 단계 상향할 수 있다.

### 프로필 증거와 가시성

- `PROFILE REQUEST`는 팀장이 계획에 적은 추천·예정값, `PROFILE ATTEST`는 담당 세션의 적합성 자기보고, `PROFILE RUNTIME`은 실제 dispatch 호출의 요청 인자와 호스트 응답을 뜻한다. 세 증거를 서로 대체하지 않는다.
- 현재 호스트는 독립 세션의 실제 runtime model/thinking 설정을 읽어오는 readback을 제공하지 않는다. `PROFILE RUNTIME`은 호출 receipt까지만 증명하며, 실제 runtime 설정을 확인했다고 보고하지 않는다.
- MULTI TRACK 계획과 상태 보고에는 아래 사용자 가시성 표를 사용한다. 계획의 `실제 모델`은 역할 등급이 아닌 제안·승인할 구체 모델명이며, runtime 적용 증거는 `PROFILE RUNTIME`으로 따로 남긴다.

| 세션 | 역할 프로필 | 실제 모델 | 추론 수준 | 속도 | PROFILE REQUEST | PROFILE ATTEST | PROFILE RUNTIME / dispatch receipt | 상태 |
|---|---|---|---|---|---|---|---|---|
| `<제목>` | `<LEAD|WORK|VERIFY|FAST>` | `<구체 모델명>` | `<thinking>` | `<Standard|Fast>` | `<provider/model/thinking/speed 추천값>` | `<PASS|ALTERNATIVE|BLOCKED>` | `<threadId·호출 결과|readback 미지원>` | `<대기|진행|완료|차단>` |
- `xhigh`·`max`·`ultra` 같은 최고 추론은 기본값으로 쓰지 않고 사용자가 별도로 승인한 어려운 작업에만 사용한다.

## 작업계획과 팀원 확인

1. 현재 GitHub ID와 2~6번 담당자 표, 배정된 개인 기능 MD, 영향 저장소를 확인한다.
2. Source 변경 전에 `SINGLE TRACK` 또는 `MULTI TRACK`을 판정한다. 필요한 경우에만 Work를 작업·검증 단위로 나누고 의존성과 충돌 파일을 짧게 적는다.
3. `SINGLE TRACK`은 Work ID·work slug 승인 후 팀장 세션에서 직접 구현할 수 있다. 같은 PR 작업은 한 Work ID로 묶는다.
4. `MULTI TRACK`은 Work ID, 담당 작업자 세션 제목, 저장소·Worktree, 선후 관계, 충돌 파일, 완료 검증, 검증 세션과 세션별 역할 프로필·실제 모델·추론 수준·속도를 한 표로 제시하고 `프로필 검토 세션 생성` 예비 승인을 묻는다. 이 단계는 Source 변경 없이 멈춘다.
5. 예비 승인 뒤 신규 PLAN 전용 세션은 추천 `model`과 `thinking`을 명시한 `create_thread`로만 생성한다. 재사용 task의 PLAN 검토를 깨우는 `send_message_to_thread`에도 같은 추천 override를 전달한다.
6. 담당 세션의 `PROFILE PLAN PASS` 또는 `PROFILE PLAN ALTERNATIVE`를 받은 뒤, 팀장은 확정 후보와 작업·검증 세션 배정을 포함한 최종 작업계획을 한 표로 제시하고 `이 작업계획과 세션 배정으로 진행할까요?`라고 묻는다.
7. 이 최종 작업계획의 사용자 승인은 역할 전환 승인, Work ID 승인, 예비 승인 또는 표 제시 전의 일반적인 `승인`·`진행`으로 대체하지 않는다. 최종 승인 전 Source 수정은 금지한다.
8. 사용자가 최종 작업계획을 승인한 뒤 `TEAM PLAN APPROVED: works=<Work ID 목록>; sessions=<작업·검증 세션 수>`를 보고한다. 동일 세션 또는 작업 세션을 실제로 깨우는 모든 `send_message_to_thread`에는 승인 `model`과 `thinking` override를 전달한다.
9. 작업 세션 제목은 `[작업] <Work ID> <범위>`, 검증 세션 제목은 `[검증] <Work ID 목록> <범위>`로 둔다. 계획 검토만 수행한 보조 에이전트는 실제 Work ID를 인계받은 작업자 세션으로 계산하지 않는다.
10. 최종 승인 후 신규 task가 필요하면 `create_thread` 호출에는 해당 세션의 승인 `model`과 `thinking`을 반드시 전달한다. provider·speed는 호스트가 별도 호출 인자를 제공하지 않으면 `PROFILE REQUEST`와 receipt에 한계를 남긴다.
11. 재사용 task의 `WORK`, `VERIFY`, 보완 등 실행을 깨우는 모든 실질적 `send_message_to_thread` 호출에도 같은 승인 `model`과 `thinking`을 반드시 override로 전달한다.
12. 호출 직전 승인값·전달값·지원 여부를 비교한다. 하나라도 누락되거나 달라지면 호출하지 않고 `MODEL PROFILE BLOCKED` 및 `TEAM DISPATCH BLOCKED: profile=<원인>`을 보고한다. 자동 fallback은 금지한다.
13. 세션 생성이나 업무 인계가 실패하면 `TEAM DISPATCH BLOCKED: <원인>`을 보고하고 멈춘다. 사용자 재승인 없이 팀장이 직접 구현하거나 숨은 보조 에이전트로 자동 대체하지 않는다.
14. 생성된 작업·검증 세션에 계획만 전달하고 Source 변경 전에 `PLAN PASS` 또는 `PLAN BLOCKED`와 최소 범위를 확인하는 `SIMPLE PASS`, 승인·Worktree·금지 작업을 확인하는 `GUARDRAIL PASS`를 받는다. 모든 팀원이 아니라 직접 영향받는 담당자만 확인하며, 가벼운 표현·구조 차이는 계획을 막지 않는다.
15. 필요한 세션이 모두 `PLAN PASS`이면 `TEAM DISPATCH PASS: works=<Work ID와 세션>; verify=<검증 세션>; order=<실행 순서>`를 보고한 뒤 구현을 시작한다.

## 개인 기능 MD와 Work ID

- 2~6번 인간 담당자의 개인 기능 MD가 해당 기능 Work ID 기록 위치다. 별도 팀장 Ledger를 만들지 않는다.
- 시작 시 Work ID, work slug, 작업 목록, 저장소·Branch를 한 번 기록한다.
- 작업 중 상태는 팀장 세션에서 관리하고 MD를 실시간 갱신하지 않는다.
- 종료 시 검증 결과, Commit·PR·병합 정보와 최종 상태를 한 번 갱신한다.
- Work ID 분리, 담당자 변경, 범위 취소처럼 기록 자체가 바뀌는 경우만 중간 갱신 예외로 둔다.
- 팀장은 다른 담당자의 개인 MD를 직접 수정하지 않고 담당자 LLM에 근거와 최소 제안만 전달한다.

## 구조 확인

- 2~6번 개인 MD 작업에서는 [AI Core 개인 기능 문서 구조 계약](../product/ai-core/AI_CORE_DOCUMENT_STRUCTURE_CONTRACT_v0.1.md)을 먼저 읽는다.
- 구조 계약과 현재 작업에 영향받는 개인 MD의 제목·메타데이터만 우선 비교한다. 2~6번 전체와 6번 전문을 매번 읽지 않는다.
- 공통 Runtime·Registry·보안 경계가 실제로 걸릴 때만 6번 문서의 관련 섹션을 상세 확인한다.
- 기본 판정은 `STRUCTURE PASS`다. 제목 순서·표현·표 위치 차이는 `PASS`와 짧은 참고사항으로 끝낸다.
- `STRUCTURE BLOCKED`는 작업 대상을 특정할 수 없거나, 동시 수정으로 변경 유실 위험이 크거나, API·DB·공통 Runtime 변경에 직접 영향받는 담당자의 최소 확인이 없는 경우에만 사용한다.
- 차단 시 영향받는 Work만 보류하고 독립 Work는 계속할 수 있다. 최소 결정권자 한 명에게만 확인한 뒤 변경된 부분만 재검사한다.

## 실행·모니터링·종료

- 실제 Source 구현은 승인된 Work ID별 독립 Worktree에서 진행한다.
- `MULTI TRACK` Source 구현은 `TEAM DISPATCH PASS` 전에는 시작하지 않는다.
- 팀장은 작업자 중간 로그를 복제하지 않고 범위, 충돌, 검증 결과와 차단 여부만 모니터링한다.
- 호스트의 대기·상태 조회 기능으로 배정 직후 상태를 한 번 확인하고, 이후 각 세션이 완료·차단·사용자 확인 필요 상태가 될 때까지 상태 변화 기준으로 기다린다. 상태 변화마다 팀장이 작업 범위와 Git Diff를 확인하고, 변하지 않은 상태는 반복 보고하지 않는다.
- 작업자가 차단되면 팀장은 원인과 최소 결정만 전달한다. 사용자 재배정 없이 해당 Worktree를 직접 수정해 작업자를 대체하지 않는다.
- 저장소·Worktree·충돌 파일이 특정된 차단은 해당 Work에만 적용한다. 선후 관계나 같은 충돌 파일이 없는 독립 Work는 계속하며 전체 팀 작업을 일괄 차단하지 않는다.
- 전체 동기화에서 Dirty canonical은 `PRESERVED`로 분류하고 해당 Working Tree와 공용 Hook·컨텍스트 갱신만 보류한다. 관계없는 깨끗한 Source 저장소의 동기화 결과는 계속 확인한다.
- `SIMPLE PASS` 또는 `GUARDRAIL PASS` 위반, 범위 확장, 불필요한 추상화·중복 문서·과도한 검증이 보이면 영향 세션을 즉시 중단하고 최소 수정 방향만 전달한다.
- `MULTI TRACK`은 작업자와 다른 검증 세션이 최소 완료 기준을 확인한다. `SINGLE TRACK`은 팀장이 직접 검증할 수 있다.
- 모든 작업·검증 상태를 확인한 뒤 `TEAM MONITOR PASS: completed=<Work ID 목록>; blocked=<없음|Work ID>`를 보고하고 개인 기능 MD의 종료 기록을 갱신한다.
- Push·PR은 별도 승인 전 금지한다. 승인 후 Push·PR 직전에는 깨끗한 Feature Worktree에서 `scripts/prepare-dev-pr.ps1 -ApproveNetwork`를 실행하고, Merge·배포를 포함한 나머지 작업은 사용자의 기존 승인 규칙을 그대로 따른다.
