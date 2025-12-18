# API / WebSocket Spec (Socket.IO 계약서, LOCKED)

> 클라/서버 병렬 개발의 기준 계약서입니다.  
> 이벤트/페이로드는 `schemas/` JSON Schema와 일치해야 합니다.

## 공통 규칙
- 모든 client->server 요청은 `requestId` 포함(UUID)
- 서버는 ACK로 `{ ok, errorCode?, data? }` 반환
- 상태 변경 시 서버는 `room:state` 또는 `match:state`/`match:event` 를 push
- 타이머는 `serverTimeMs` 기반으로 보정

---

## 1) Auth
### client->server: `auth:hello`
```json
{ "requestId":"uuid", "deviceId":"string", "nickname":"string" }
```
### ack
```json
{ "ok": true, "data": { "userId":"u_...", "nickname":"..." } }
```

---

## 2) Room
### `room:create`
```json
{
  "requestId":"uuid",
  "game":"LAS_VEGAS|TICHU",
  "visibility":"PUBLIC|PRIVATE"
}
```

### `room:join`
```json
{ "requestId":"uuid", "roomCode":"ABCD" }
```

### `room:leave`
```json
{ "requestId":"uuid" }
```

### `room:setReady`
```json
{ "requestId":"uuid", "ready": true }
```

### `room:addBot`
```json
{ "requestId":"uuid", "slotIndex": 2, "difficulty":"EASY|NORMAL" }
```

### `room:start`
```json
{ "requestId":"uuid" }
```

### server->clients: `room:state`
```json
{
  "roomId":"r_...",
  "roomCode":"ABCD",
  "game":"LAS_VEGAS",
  "members":[
    {"slotIndex":0,"type":"HUMAN","userId":"u1","nickname":"A","ready":true},
    {"slotIndex":1,"type":"BOT","botId":"b1","nickname":"Bot(EASY)","ready":true}
  ],
  "status":"LOBBY|IN_MATCH",
  "serverTimeMs": 1730000000000
}
```

---

## 3) Match
### server->clients: `match:started`
```json
{ "matchId":"m_...", "game":"LAS_VEGAS", "seed":"int-or-string" }
```

### server->client (개인별): `match:state`
```json
{
  "matchId":"m_...",
  "yourPlayerId":"p0",
  "phase":"LAS_VEGAS.PLAYER_TURN",
  "public": { "turnPlayerId":"p0", "round":1, "scores":{...}, "table":{...} },
  "private": { "hand": [], "dice": [1,1,3,6] },
  "legalActions": [ {"type":"CHOOSE_VALUE","value":6} ],
  "deadlineMs": 1730000005000,
  "serverTimeMs": 1730000001000
}
```

### client->server: `match:action`
```json
{
  "requestId":"uuid",
  "matchId":"m_...",
  "action": { "type":"CHOOSE_VALUE", "value": 6 }
}
```

### server->clients: `match:event`
```json
{
  "matchId":"m_...",
  "seq": 12,
  "tsMs": 1730000001200,
  "type":"LAS_VEGAS.CHOOSE_VALUE",
  "payload": { "playerId":"p0", "value":6, "assignedCount":2 }
}
```

---

## 4) 에러 코드
- AUTH_REQUIRED
- ROOM_NOT_FOUND
- ROOM_FULL
- NOT_HOST
- NOT_YOUR_TURN
- ILLEGAL_ACTION
- MATCH_NOT_FOUND
- RATE_LIMITED

---

## 5) 재접속(LOCKED)
- 네트워크 끊김 → Socket.IO 재연결
- 클라는 즉시 `auth:hello` 재호출
- 서버는 해당 유저가 room/match에 있으면 `room:state` + `match:state` push
- 유예 시간: 90초 (서버가 매치 유지)


## 6) Tichu Action 타입(요약)
- `TICHU.DECLARE_GRAND_TICHU`
- `TICHU.DECLARE_TICHU`
- `TICHU.SELECT_EXCHANGE` { to:"LEFT|PARTNER|RIGHT", card }
- `TICHU.CONFIRM_EXCHANGE`
- `TICHU.PLAY_CARDS` { cards:[...], declaredCombo?: {...} }
- `TICHU.PASS`
- `TICHU.DRAGON_DONATE` { toOpponentPlayerId:"p1|p3" }
- `TICHU.PLAY_BOMB` { cards:[...], declaredCombo:{type:"BOMB4|BOMB_STRAIGHT_FLUSH", ...} }

> `declaredCombo`는 Phoenix(와일드)나 Straight/Pair-straight에서 모호성을 없애기 위해 사용합니다.


## 7) Tichu 룰 변경(LOCKED v3) 요약
- 폭탄은 **내 턴에만** 제출 가능(인터럽트 없음)
- Mahjong wishRank는 2..A 또는 `"NONE"`(선택 안함) 가능
- 동점이면 1라운드 추가 진행 후 합산으로 승패 결정(서버가 roundIndex/누적점수 포함하여 state/event로 안내)
