# TASKS_BACKLOG (LOCKED v3, Flutter/Socket.IO/Node/TS)

## Milestone 0: Repo/Tooling
- [ ] Monorepo 구조 생성(apps/server, apps/mobile, packages/shared)
- [ ] server: tsconfig, lint, schema validation
- [ ] docker-compose(Postgres/Redis)
- [ ] shared: JSON schema 폴더 + (선택) 타입/코드생성 스크립트

## Milestone 1: Realtime Core (Room)
- [ ] Socket.IO 서버 초기화 + CORS
- [ ] auth:hello (게스트)
- [ ] room:create/join/leave
- [ ] room:setReady, room:start
- [ ] room:addBot(EASY/NORMAL)
- [ ] room:state broadcast
- [ ] reconnect flow(90초)

## Milestone 2: Match Core
- [ ] match lifecycle(started/state/event/ended)
- [ ] seed RNG + determinism 테스트
- [ ] match_events 저장(Postgres)
- [ ] AFK autoAction(30초)

## Milestone 3: Las Vegas (Game 1)
- [ ] 상태머신 + 합법 액션 생성
- [ ] 주사위 롤/선택/배치/정산/종료
- [ ] Flutter UI
- [ ] 봇 EASY/NORMAL
- [ ] self-play 500판

## Milestone 4: Tichu Full 단판 (Game 2)
- [ ] DEAL_PART1(8) + Grand 선언 window + DEAL_PART2(6)
- [ ] EXCHANGE(3장) select/commit
- [ ] TRICK 엔진(반시계)
- [ ] 시작 플레이어: Mahjong holder
- [ ] 콤보 판정 + Phoenix 와일드(declaredCombo)
- [ ] Mahjong Wish: wishRank 선택(2..A + NONE) + 강제 시 legalActions 제한/해제
- [ ] Bomb(4장 + 스트레이트플러시) 구현(인터럽트 없음)
- [ ] Dragon donate phase + 선택 UI/서버 액션
- [ ] 라운드 종료(1명 남음) + 꼴찌 처리
- [ ] 더블 승리 +200 + 선언 점수
- [ ] 단판 승패 UI
- [ ] 동점 타이브레이커(추가 라운드 1회) + 누적 점수 UI
- [ ] 봇 EASY/NORMAL
- [ ] self-play 200판

## Milestone 5: Packaging
- [ ] Android internal test
- [ ] iOS TestFlight (Xcode/Flutter)
- [ ] 서버 배포 + env
