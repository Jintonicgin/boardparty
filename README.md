# 티츄/라스베가스 MVP 구현 준비 문서 (Tight Version v3)

이 폴더는 **구현 직전(설계 고정)** 상태의 문서 패키지입니다.  
사용 스택은 이미 확정되어 있으며, 문서에는 **대안/옵션을 최소화**했습니다.

- 작성일: 2025-12-18
- 팀: 2인(맥북 1, 갤럭시북/Windows 1)
- 게임: Las Vegas(2~5인), Tichu(4인 팀전)

## 확정 스택(LOCKED)
- Client: **Flutter**
- Realtime: **Socket.IO**
- Server: **Node.js + TypeScript**
- Storage: **Postgres + Redis**
- Repo: **Monorepo**
- Auth(MVP): **게스트 로그인**
- Match 정책: **재접속 90초 / 턴 타이머 30초**

## 사용 순서(권장)
1) `docs/PRD.md` 범위 확인(P0만 구현)
2) `docs/API_WEBSOCKET.md` 를 “계약서”로 고정 → 클라/서버 병렬 개발
3) `docs/GAME_LAS_VEGAS_SPEC.md` 구현/출시 → `docs/GAME_TICHU_SPEC.md` 순으로 진행
4) `docs/TEST_PLAN.md` 케이스를 자동화 테스트로 추가

## 문서 목록
- `docs/STACK_LOCK.md` : 확정 스택/정책(한 장 요약)
- `docs/PRD.md` : 요구사항(P0/P1)
- `docs/ARCHITECTURE.md` : 모노레포/서비스 구조
- `docs/API_WEBSOCKET.md` : Socket.IO 이벤트 계약(핵심)
- `docs/DATA_MODEL.md` : Postgres/Redis 설계 + 이벤트 로그
- `docs/STATE_MACHINE_COMMON.md` : 공통 게임 엔진 계약
- `docs/GAME_LAS_VEGAS_SPEC.md` : 라스베가스 스펙
- `docs/GAME_TICHU_SPEC.md` : 티츄 Full 룰 + 동점 타이브레이커(최대 2라운드)
- `docs/BOT_SPEC.md` : 봇 MVP
- `docs/DEV_SETUP.md` : Windows/Mac 개발환경 (Flutter+iOS 포함)
- `docs/TEST_PLAN.md` : 테스트/QA
- `docs/SECURITY_FAIRPLAY.md` : 공정성/치팅 방지
- `docs/RELEASE_CHECKLIST.md` : Android/iOS 빌드/배포
- `docs/LICENSE_RISK.md` : 라이선스 리스크(상용 출시 전 필독)
- `docs/TASKS_BACKLOG.md` : 에픽/마일스톤 작업 분해(Claude CLI 입력용)
- `CLAUDE_STARTER_PROMPT.md` : Claude CLI 시작 프롬프트

## 포함 파일
- `.env.example` / `docker-compose.yml` : 로컬 서버 기본 골격
- `schemas/*.json` : WS 이벤트/액션/카드 Schema

## Tichu 룰(Full) 확정 사항
- 기본 1라운드로 승패 결정(동점이면 1라운드 추가, 최대 2라운드)
- 동점이면 추가 1라운드 진행 후 **(라운드1 + 라운드2) 합산**으로 승패 결정
- 진행 방향: 반시계
- 라운드 종료: 1명만 남으면 종료/꼴찌 처리
- 드래곤 트릭 기부: 상대 중 누구에게 줄지 선택(선택 창 필요)
- 피닉스: 콤보 와일드까지 포함
- 폭탄: 4장 동일 + 스트레이트플러시 폭탄 포함 (인터럽트 없음)
- 마작 소원(Wish) 진행 (선택 안함 가능)
- 티츄/그랜드티츄 선언 시스템 포함