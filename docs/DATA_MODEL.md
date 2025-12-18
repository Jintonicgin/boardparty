# DATA MODEL (Postgres + Redis, LOCKED)

## Postgres (권장 스키마)
### users
- user_id (PK)
- device_id (unique)
- nickname
- created_at, updated_at

### matches
- match_id (PK)
- game
- seed
- started_at, ended_at
- result_json (scores, winner, meta)
- players_json (slots/teams)

### match_events (append-only event store)
- match_id (FK)
- seq (int, increasing)
- ts_ms (bigint)
- type (text)
- payload_json (jsonb)
- PRIMARY KEY (match_id, seq)

> `match_events`가 리플레이/디버깅의 핵심이다.

## Redis (키)
- `room:{roomId}:state`  (JSON)
- `presence:{userId}`    (socketId, lastSeenMs)
- `rate:{userId}`        (rate limit)

## 결정적 재현(determinism)
- `matches.seed` + `match_events`로 결과 재현 가능해야 함
- RNG 사용 지점 고정(셔플/주사위/돈 카드 배치)


## Tichu 단판+타이브레이커 저장(LOCKED v3)
- Tichu 매치는 기본 1라운드, 동점이면 1라운드 추가(최대 2라운드)
- `matches.result_json` 권장 구조:
  - `rounds`: [{ roundIndex, teamScores, declarations, doubleWin, firstOutPlayerId, lastPlayerId, notes }]
  - `final`: { totalScores, winnerTeam, tieBreakerApplied:boolean }
