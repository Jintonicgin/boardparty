# ARCHITECTURE (Flutter + Socket.IO + Node/TS)

## 1) 핵심 원칙
- **Server-authoritative**: 룰/랜덤/판정은 서버만 수행
- 클라는 UI/입력만 담당
- 모든 선택은 `legalActions`로 제한
- match_events(event sourcing)로 저장 → 리플레이/디버깅/학습 기반 확보

## 2) 모노레포 구조(LOCKED)
```
repo/
  apps/
    server/          # Node/TS + Socket.IO
    mobile/          # Flutter 앱
  packages/
    shared/          # JSON Schema, 공통 타입/문서, (선택) 코드생성 스크립트
  docs/              # (이 문서들)
```

## 3) 서버 구성
- Socket.IO Gateway
  - room management (create/join/leave/ready/start)
  - match routing (action -> engine -> state/event broadcast)
- Game Engine
  - las_vegas/
  - tichu/
- Bot Runner(초기: 서버 내부 모듈)
- Storage
  - Postgres: users, matches, match_events
  - Redis: room:{id}:state, presence, rate-limit

## 4) 클라이언트(Flutter) 구성
- Screens
  - Login(게스트)
  - Home(게임 선택)
  - Room/Party(슬롯/봇/Ready)
  - Match(LasVegas UI / Tichu UI)
  - Result
- Socket Layer
  - connect/auth:hello
  - subscribe room:state, match:state, match:event

## 5) 결정적 재현(determinism)
- match.seed로 RNG 초기화
- 랜덤 사용 지점을 고정(셔플, 돈 카드 공개, 주사위 롤 등)
- event log 재생으로 결과 동일해야 함


## 6) Tichu 라운드/타이브레이커
- 기본 1라운드 종료 후 동점이면 라운드2를 1회 더 진행
- 누적 점수는 match-level state로 관리하고, rounds[] 결과를 result_json에 저장
