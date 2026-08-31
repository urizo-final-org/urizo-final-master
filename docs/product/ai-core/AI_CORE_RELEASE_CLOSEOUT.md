# AX Module Studio AI Core Release Closeout

> 상태: `OPEN`
> 기준일: 2026-09-01 (Asia/Seoul)
> 원칙: `Simple is best`

## 1. 범위와 완료 기준

- 제품 기준은 [로컬 CMS MVP Spec](../AX_Module_Studio_CMS_LOCAL_DEMO_MVP_SPEC_v1.0.md), [AI 공통 계약](../AI_CORE_FUTURE_CONSIDERATIONS_v0.1.md), 4·5·6번 상세 문서다. 이 원장은 제품 범위를 새로 만들지 않는다.
- 활성 추적 대상은 **29개**다: 미완료 `M01~M07` 7개 + 부분완료 `P01~P08` 8개 + 구 Work `L01~L14` 14개.
- 기존 21개 분류의 완료 4개와 의도적 제외 2개는 작업 대상이 아니다.
- `Simple is best` 위반 7개는 29개에 포함된 원인 분류이며 추가 작업이 아니다.
- 실제 구현은 아래 7개 Work로 묶는다. 29개의 항목마다 별도 Work·문서·승인 절차를 만들지 않는다.
- 순서는 `실패 재현 → 최소 수정 → 제품 시나리오 확인 → 저장소 기존 전체 테스트`뿐이다.
- 별도 감사·감리·검증 조직·Gate 체계·새 상태·새 검증 Script·불필요한 추상화를 만들지 않는다.
- 상태는 `OPEN`과 `DONE`만 사용한다. 최종 5개 SHA에서 29개와 기존 전체 테스트, 기존 full 로컬 실행이 모두 통과해야 최종 `DONE`이다.

## 2. 시작 SHA

| 저장소 | 2026-09-01 `origin/dev` |
|---|---|
| Master | `c3cb1fd016da7fbdb0b4bd21f7fff5fa6ea6997b` |
| Frontend | `62ed93f3743d70e29c43a61ae2850ce08e093f7e` |
| Backend | `9189d27510e16c3c11c350205e6b53c14ebe2f2a` |
| Orchestrator | `85b36392481065e4b933e688ec66ebc3e2bee351` |
| MCP Server | `0885dbe64ae601d9790c05c600dbb585eff70800` |

## 3. 실제 Work 7개

| Work | 저장소 | 포함 항목 | 제품 완료 결과 | 상태 |
|---|---|---|---|---|
| `AXMS-RC-001` 인증 세션 | Frontend, Backend | `P02` | 로그인·refresh·logout 응답 순서가 바뀌어도 최신 세션만 유지 | `OPEN` |
| `AXMS-RC-002` Natural CMS | Backend, Orchestrator, MCP Server | `M02`, `L09` | 요청→Preview→승인→CMS 반영이 한 Job으로 끝나며 실패 시 원상복구 | `OPEN` |
| `AXMS-RC-003` Snapshot Runtime | Backend, Orchestrator | `M01`, `P01`, `L01~L06`, `L10` | 저장한 Profile의 순서·분기·승인·재시도 설정 그대로 실행 | `OPEN` |
| `AXMS-RC-004` CMS Site | Frontend, Backend | `M03~M05`, `P03~P04`, `L11` | Site 생성·전환·오류 복구·Template 즉시 반영이 실제 화면에서 동작 | `OPEN` |
| `AXMS-RC-005` Provider 계약 | Frontend, Backend, Orchestrator | `P06~P08`, `L08`, `L12~L14` | 설정한 Provider·Model·role·Structured Output이 실제 실행까지 보존 | `OPEN` |
| `AXMS-RC-006` MCP·정리 | Frontend, Backend, MCP Server, Master | `M06~M07`, `P05`와 Simple 위반 정리 | 13개 Tool 왕복·Windows 테스트·권한/문서 정합성, 죽은 코드와 중복 권위 제거 | `OPEN` |
| `AXMS-RC-007` 최종 실행 | Master와 네 Source | 앞의 29개 | 같은 최종 SHA에서 전체 테스트와 기존 full 로컬 제품 흐름 통과 | `OPEN` |

## 4. 미해결 15개

### 미완료 7개

| ID | 항목 | 제품 기준 완료 결과 | Work | 상태 |
|---|---|---|---|---|
| `M01` | Snapshot 승인 순서 권위 | Backend 고정 체인 없이 Snapshot Edge·interrupt·checkpoint가 승인 순서를 결정 | `AXMS-RC-003` | `OPEN` |
| `M02` | CMS 변경 원자성 | CMS 콘텐츠·Handler Result·Job 전이가 모두 성공하거나 모두 rollback | `AXMS-RC-002` | `OPEN` |
| `M03` | 공개 Site 최초 실패 처리 | 오류 화면과 재시도가 보이고 재시도 성공 후 Site 표시 | `AXMS-RC-004` | `OPEN` |
| `M04` | 공개 Site 요청 경합 | 이전 요청이 최신 Site 화면을 덮지 못함 | `AXMS-RC-004` | `OPEN` |
| `M05` | 복수 Site 관리 | SUPER_ADMIN이 Site를 생성·조회·수정하고 key/path 충돌을 안내받음 | `AXMS-RC-004` | `OPEN` |
| `M06` | MCP live 13-tool | 인증된 Spring↔MCP 왕복에서 Coding 7 + CMS 6 Catalog가 정확히 일치 | `AXMS-RC-006` | `OPEN` |
| `M07` | MCP Windows 경계 | 같은 경계 Fixture가 LF와 CRLF에서 모두 통과 | `AXMS-RC-006` | `OPEN` |

### 부분완료 8개

| ID | 항목 | 남은 제품 기준 완료 결과 | Work | 상태 |
|---|---|---|---|---|
| `P01` | Profile 설정 실제 실행 | edge·loop·toolPolicy·modelBindings에 더해 Snapshot `maxAttempts`까지 적용 | `AXMS-RC-003` | `OPEN` |
| `P02` | 인증 세션 경합 | 오래된 refresh·expired 응답 차단과 logout session-family 폐기 | `AXMS-RC-001` | `OPEN` |
| `P03` | 공개 경로 검증 | `/admin`·`/api`·`/internal`·`/actuator`와 하위 경로 저장 거부 | `AXMS-RC-004` | `OPEN` |
| `P04` | 기본 Template 관리 | `site.templateKey`만 선택 권위로 사용하고 저장 즉시 공개 화면 반영 | `AXMS-RC-004` | `OPEN` |
| `P05` | 관리자 권한·문서 | 실제 SUPER_ADMIN 권한·Route·현재 상태 문서가 코드와 일치 | `AXMS-RC-006` | `OPEN` |
| `P06` | Message role·Structured Output | role 순서와 `JSON_SCHEMA`가 실제 Provider 요청·응답까지 보존 | `AXMS-RC-005` | `OPEN` |
| `P07` | Provider 상태 | 조회 실패를 성공처럼 표시하지 않고 Key 교체 전 테스트 결과를 폐기 | `AXMS-RC-005` | `OPEN` |
| `P08` | JSON repair·검증 | 1회 repair 뒤 strict parse하고 실제 JSON golden/negative corpus 통과 | `AXMS-RC-005` | `OPEN` |

## 5. 구원장 14개 제품 재확인

과거 PR 병합은 완료 증거가 아니다. 현재 제품 흐름에서 아래 결과가 깨지면 같은 Work에서 최소 수정한다.

| ID | 구 Work | 제품 기준 완료 결과 | 새 Work | 상태 |
|---|---|---|---|---|
| `L01` | `AI06-004` Snapshot Contract | 활성화할 Snapshot JSON의 필드·Port·제한을 불변 계약으로 검증 | `AXMS-RC-003` | `OPEN` |
| `L02` | `AI06-005` Registry·Graph Builder | 등록된 Handler만으로 선형·분기·제한 반복 Graph를 조립 | `AXMS-RC-003` | `OPEN` |
| `L03` | `AI06-006` Snapshot Runner | 실제 Worker가 Snapshot 경로로 실행하며 재시도·중단·재개를 보존 | `AXMS-RC-003` | `OPEN` |
| `L04` | `AI06-007` Profile Version 읽기 | Job에 고정한 불변 Profile Version을 Spring에서 읽어 끝까지 사용 | `AXMS-RC-003` | `OPEN` |
| `L05` | `AI06-008` Job–Snapshot 바인딩 | 생성 시 Version을 고정하고 Queue에는 `jobId`만 전달 | `AXMS-RC-003` | `OPEN` |
| `L06` | `AI06-009` Approval·Check·Guardrail | 승인·Check·잠금 Guardrail과 재개가 Snapshot 결과 Port로 동작 | `AXMS-RC-003` | `OPEN` |
| `L07` | `AI06-010` MCP 공통 플랫폼 | 인증·Allowlist·단일 Catalog·Core DB 비접근 경계를 유지 | `AXMS-RC-006` | `OPEN` |
| `L08` | `AI04-002` Coding Handler | Coding Job의 분석·승인·코딩·리뷰·PR 결과가 Snapshot 흐름으로 연결 | `AXMS-RC-005` | `OPEN` |
| `L09` | `AI05-001-01` Natural CMS Handler | 전용 Queue가 `jobId`를 소비하고 Preview 승인 후 Spring CMS Service로 반영 | `AXMS-RC-002` | `OPEN` |
| `L10` | `AI06-011` 관리자 Profile 설정 | 관리자 저장·활성화가 불변 Version을 만들고 다음 Job 실행에 적용 | `AXMS-RC-003` | `OPEN` |
| `L11` | `AI05-002` CMS Site 설정 | Site별 설정 격리와 공개 Context 단일 API를 유지하고 미사용 호환 코드를 제거 | `AXMS-RC-004`, `AXMS-RC-006` | `OPEN` |
| `L12` | `AI06-017` Provider Credential | Key 등록·교체·상태·연결 테스트가 실제 화면 하나에서 동작하고 가짜 Models UI를 제거 | `AXMS-RC-005`, `AXMS-RC-006` | `OPEN` |
| `L13` | `AI06-018` Provider-native Tool Calling | 허용 Tool·Schema·결과가 실제 Provider Adapter에서 보존 | `AXMS-RC-005` | `OPEN` |
| `L14` | `AI06-019` Profile Model Binding | `profileVersionId + nodeId`가 실제 Provider·Model 선택에 사용 | `AXMS-RC-005` | `OPEN` |

### Simple is best 위반 7개 연결

- 승인 권위 중복 → `M01`
- 재시도 상한 중복 → `P01`
- Template 권위 중복 → `P04`
- CMS Transaction 경계 분리 → `M02`
- 가짜 Models UI·테스트 → `L12`
- `SiteApi.template()`·`normalizeCollection()` → `L11`
- 상태 문서 중복 → `P05`

## 6. 기존 검증 명령과 최종 기록

새 검증 Script를 만들지 않고 기존 명령만 사용한다.

| 대상 | 명령 |
|---|---|
| Frontend | `pnpm run verify` |
| Backend Product | `.\mvnw.cmd -o clean verify` |
| Backend Control | `.\mvnw.cmd -o -Pspring-ai-control clean verify` |
| Orchestrator | `uv run --frozen python -B -m unittest discover -s tests -v` 후 `uv run --frozen python -m compileall -q src tests` |
| MCP Server | `uv run python -m unittest discover -s tests -v` 후 `uv run python -m compileall -q src tests` |
| 최종 full 로컬 | Master에서 `.\scripts\start-local-cms.ps1 -Profile full -Rebuild -ApproveNetwork -ApproveLocalMutation` |

| 최종 기록 | 결과 |
|---|---|
| 상태 | `OPEN` |
| 최종 5개 SHA | — |
| 미완료 7개 | `0 / 7 DONE` |
| 부분완료 8개 | `0 / 8 DONE` |
| 구원장 14개 | `0 / 14 DONE` |
| 저장소 전체 테스트 | 미실행 |
| full 로컬 제품 흐름 | 미실행 |
