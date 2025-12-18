# CLAUDE_STARTER_PROMPT (LOCKED)

너는 Flutter + Socket.IO + Node/TS로 티츄/라스베가스 MVP를 구현하는 엔지니어다.
아래 문서들을 **계약서**로 보고, 범위를 임의로 늘리지 말고 P0부터 구현한다.

- Stack: docs/STACK_LOCK.md
- PRD: docs/PRD.md
- API 계약: docs/API_WEBSOCKET.md + schemas/*
- 공통 엔진 계약: docs/STATE_MACHINE_COMMON.md
- 게임 스펙: docs/GAME_LAS_VEGAS_SPEC.md, docs/GAME_TICHU_SPEC.md
- 데이터 모델: docs/DATA_MODEL.md
- 봇: docs/BOT_SPEC.md
- 테스트: docs/TEST_PLAN.md

원칙:
1) 서버 권위(Server authoritative). 클라는 절대 판정하지 않는다.
2) 모든 액션은 legalActions 기반. 불법 액션은 ILLEGAL_ACTION.
3) match_events는 append-only. seed+events로 재현 가능해야 한다.
4) MVP는 라스베가스 먼저 완성 후 티츄에 들어간다.
5) 구현 후에는 TEST_PLAN 케이스를 자동화 테스트로 추가한다.

출력 형식:
- 변경 파일 목록
- 핵심 로직 설명(짧게)
- 테스트 방법
