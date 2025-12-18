# STACK_LOCK (확정 스택/정책 1장)

## Client
- Flutter (Dart)
- iOS: Xcode 사용(Flutter iOS Runner)
- Android: Android Studio

## Realtime
- Socket.IO
- ACK 기반 요청/응답 + state broadcast

## Server
- Node.js 20 + TypeScript
- Socket.IO server
- REST는 최소화(헬스체크/버전 정도만)

## Storage
- Postgres: users, matches, match_events (append-only)
- Redis: room state cache, presence, rate limit

## Repo
- Monorepo
  - `apps/server` (Node/TS)
  - `apps/mobile` (Flutter)
  - `packages/shared` (JSON schema, 공통 문서/유틸)

## Auth (MVP)
- 게스트 로그인(deviceId + nickname)
- 소셜 로그인은 P1 이후

## Match 운영 정책(LOCKED)
- 턴 타이머: 30초 (방 옵션은 MVP에서 고정)
- 재접속 유예: 90초
- AFK: deadline 초과 시 자동 행동(보수적 합법 행동). 반복 시 봇 대체(P1).

## 게임 구현 순서
- (Tichu 룰은 Full 단판 스펙: Wish(선택 안함 포함)/Declare/Bomb(인터럽트 없음)/Dragon donate + 동점 시 1라운드 추가 포함)

1) Las Vegas
2) Tichu
