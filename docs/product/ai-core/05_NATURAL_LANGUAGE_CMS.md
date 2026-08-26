# 5. 자연어 CMS 관리

> 담당자: 이재욱 (`LEEJAEWOOK1`)
> 현재 단계: 심층 조사·방향 수립 중
> 내용 권한: 담당자가 이 기능의 기획·방향·작업 ID와 진행 상태를 현행화한다.

## 현재 방향

- 일반관리자가 메뉴, 콘텐츠, 게시판과 사용자 페이지 Template을 자연어로 관리한다.
- 각 관리 화면 우측 Assistant는 현재 화면의 관리 대상만 변경할 수 있다.
- 자연어 CMS 관리는 기존 데이터·Template 관리이며 새로운 애플리케이션 기능 추가와 구분한다.
- LLM은 임의 HTML·CSS·JavaScript 대신 구조화 Draft를 만들고 기존 Renderer와 허용된
  Component·Template Variant·Design Token 범위 안에서만 변경한다.
- Schema·권한·접근성 검증과 Desktop·Mobile Preview 후 게시한다.
- 첨부 이미지 기반 Template 확장은 담당자가 범위와 Guardrail을 검토한다.

## 담당자 검토 항목

- 메뉴·콘텐츠·게시판·Template별 허용 명령과 데이터 경계
- 화면별 Assistant UI, Draft·Preview·승인 흐름
- 이미지 기반 Template 확장의 입력·출력과 안전 범위
- Version·복구와 게시 최소 범위

## 진행 상태

- 현재: 화면별 자연어 관리 범위와 Guardrail 심층 조사
- 다음: 팀 중간점검 후 사용자 흐름과 최소 완료 기준 확정

## 하위 작업 기록

현재는 상세 작업 분류 전이므로 비워 둔다. 새 Work ID가 승인되면 같은 PR에 포함할 구현·테스트·문서·수정을
아래처럼 한 체크리스트로 묶고, 추적표에는 저장소별 진행 상태와 Git 정보를 기록한다.

```markdown
#### `<Work ID>` · `<작업명>`
- [ ] `<같은 PR에 포함할 작업>`
```

| Work ID | Work slug | 작업 요약 | 저장소 | 진행 상태 | Branch | 최근 Push SHA·일자 | PR·상태·생성일 | dev 병합 SHA·일자 |
|---|---|---|---|---|---|---|---|---|
